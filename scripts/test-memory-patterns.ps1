[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]*$')]
    [string]$OutputLabel,

    [ValidateRange(64, 512)]
    [int]$BufferMiB = 256,
    [ValidateRange(256, 4096)]
    [int]$MinimumAvailableMiB = 768
)

# Bounded, user-mode screening of one pinned .NET byte array. This is not a
# whole-physical-memory test and makes no claim about inaccessible pages.
$ErrorActionPreference = 'Stop'
$startedUtc = [DateTime]::UtcNow
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$label = if ($OutputLabel) { $OutputLabel } else { "memory-screen-$stamp" }
$resultRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\local-results'))
$outputDirectory = Join-Path $resultRoot $label
if (Test-Path -LiteralPath $outputDirectory) {
    throw "Output directory already exists; choose a new OutputLabel: $outputDirectory"
}
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$reportPath = Join-Path $outputDirectory 'memory-pattern-screen.json'
$buffer = $null
$pin = $null
$exitCode = 3
$passes = [System.Collections.Generic.List[object]]::new()
$summary = [ordered]@{
    Test = 'Pinned managed-buffer pattern screen'
    Scope = 'One user-mode virtual allocation; not exhaustive physical RAM coverage'
    StartedUtc = $startedUtc.ToString('o')
    CompletedUtc = $null
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    Is64BitProcess = [Environment]::Is64BitProcess
    BufferMiB = $BufferMiB
    BufferBytes = [long]$BufferMiB * 1MB
    MinimumAvailableMiB = $MinimumAvailableMiB
    AvailableMiBBeforeAllocation = $null
    PassCountCompleted = 0
    BytesWritten = [long]0
    BytesVerified = [long]0
    MismatchCount = [long]0
    Passes = @()
    Status = 'NotStarted'
    Error = $null
    ElapsedSeconds = $null
    ExitCode = $null
    Limitations = @(
        'Tests only the allocated managed buffer and pages Windows backs it with; it cannot prove that all installed physical memory is error-free.'
        'User-mode virtual offsets are not physical DRAM addresses. No SPD, ECC, or device-level telemetry is read.'
        'A clean result is a limited screening result, not proof that the module is new or fault-free.'
    )
}

function Save-Report {
    $timer.Stop()
    $summary.CompletedUtc = [DateTime]::UtcNow.ToString('o')
    $summary.Passes = @($passes)
    $summary.ElapsedSeconds = [math]::Round($timer.Elapsed.TotalSeconds, 3)
    $summary.ExitCode = $exitCode
    $summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Write-Output "Report: $reportPath"
}

try {
    $memoryCounter = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Memory -ErrorAction Stop
    $availableMiB = [int]$memoryCounter.AvailableMBytes
    $summary.AvailableMiBBeforeAllocation = $availableMiB
    if ($availableMiB -lt $MinimumAvailableMiB) {
        $summary.Status = 'SkippedInsufficientAvailableMemory'
        $summary.Error = "Available memory ${availableMiB} MiB is below the ${MinimumAvailableMiB} MiB safety threshold. No allocation or test was performed."
        $exitCode = 2
    }
    else {
        $source = @(
            'using System;',
            'using System.Collections.Generic;',
            'namespace RamScreen {',
            '  public sealed class MismatchSample { public int Offset { get; set; } public byte Expected { get; set; } public byte Observed { get; set; } }',
            '  public sealed class VerifyResult { public long MismatchCount { get; set; } public List<MismatchSample> Samples { get; set; } }',
            '  public static class PatternOps {',
            '    private static byte Expected(int i, int mode) {',
            '      switch (mode) {',
            '        case 0: return 0x00;',
            '        case 1: return 0xFF;',
            '        case 2: return 0xAA;',
            '        case 3: return 0x55;',
            '        case 4: return (byte)((i ^ (i >> 8) ^ (i >> 16) ^ 0xA5) & 0xFF);',
            '        case 5: return (byte)(~((i ^ (i >> 8) ^ (i >> 16) ^ 0xA5) & 0xFF) & 0xFF);',
            '        case 6:',
            '        case 7: uint x = unchecked((uint)i * 0x9E3779B9u + 0xA341316Cu); x ^= x >> 16; x = unchecked(x * 0x7FEB352Du); x ^= x >> 15; byte b = (byte)(x & 0xFF); return mode == 6 ? b : (byte)~b;',
            '        default: throw new ArgumentOutOfRangeException("mode");',
            '      }',
            '    }',
            '    public static void Write(byte[] data, int mode) { for (int i = 0; i < data.Length; i++) data[i] = Expected(i, mode); }',
            '    public static VerifyResult Verify(byte[] data, int mode, int sampleLimit) {',
            '      VerifyResult r = new VerifyResult(); r.MismatchCount = 0; r.Samples = new List<MismatchSample>();',
            '      for (int i = 0; i < data.Length; i++) { byte e = Expected(i, mode); byte a = data[i]; if (a != e) { r.MismatchCount++; if (r.Samples.Count < sampleLimit) r.Samples.Add(new MismatchSample { Offset = i, Expected = e, Observed = a }); } }',
            '      return r;',
            '    }',
            '  }',
            '}'
        ) -join [Environment]::NewLine
        Add-Type -TypeDefinition $source -Language CSharp -ErrorAction Stop
        $summary.Status = 'Running'
        $buffer = [byte[]]::new([int]($BufferMiB * 1MB))
        $pin = [System.Runtime.InteropServices.GCHandle]::Alloc($buffer, [System.Runtime.InteropServices.GCHandleType]::Pinned)
        $names = @('Zero','Ones','AlternatingAA','Alternating55','OffsetAddressPattern','InvertedOffsetAddressPattern','DeterministicPseudoRandom','InvertedDeterministicPseudoRandom')
        for ($mode = 0; $mode -lt $names.Count; $mode++) {
            $passTimer = [System.Diagnostics.Stopwatch]::StartNew()
            [RamScreen.PatternOps]::Write($buffer, $mode)
            $check = [RamScreen.PatternOps]::Verify($buffer, $mode, 20)
            $passTimer.Stop()
            $samples = @($check.Samples | ForEach-Object {
                [pscustomobject]@{ Offset = $_.Offset; Expected = ('0x{0:X2}' -f $_.Expected); Observed = ('0x{0:X2}' -f $_.Observed) }
            })
            $passes.Add([pscustomobject][ordered]@{
                Name = $names[$mode]
                BufferBytesWritten = [long]$buffer.Length
                BufferBytesVerified = [long]$buffer.Length
                MismatchCount = [long]$check.MismatchCount
                MismatchSamples = $samples
                ElapsedSeconds = [math]::Round($passTimer.Elapsed.TotalSeconds, 3)
            })
            $summary.PassCountCompleted++
            $summary.BytesWritten += [long]$buffer.Length
            $summary.BytesVerified += [long]$buffer.Length
            $summary.MismatchCount += [long]$check.MismatchCount
            if ($check.MismatchCount -gt 0) {
                $summary.Status = 'MismatchDetected'
                $exitCode = 1
                break
            }
        }
        if ($summary.MismatchCount -eq 0 -and $summary.PassCountCompleted -eq $names.Count) {
            $summary.Status = 'PassedLimitedScreen'
            $exitCode = 0
        }
    }
}
catch {
    $summary.Status = 'Exception'
    $summary.Error = $_ | Out-String
    $exitCode = 3
}
finally {
    if ($null -ne $pin -and $pin.IsAllocated) { $pin.Free() }
    $buffer = $null
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    Save-Report
}
exit $exitCode
