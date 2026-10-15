[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]*$')]
    [string]$OutputLabel,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$MlcPath
)

$ErrorActionPreference = 'Stop'
$resultRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\local-results'))
$outputDirectory = Join-Path $resultRoot $OutputLabel
$winsatPath = Join-Path $env:SystemRoot 'System32\WinSAT.exe'

if (Test-Path -LiteralPath $outputDirectory) {
    throw "Output directory already exists; choose a new OutputLabel: $outputDirectory"
}
$principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Open PowerShell as Administrator, then run this script. It will not self-elevate.'
}
if (-not (Test-Path -LiteralPath $MlcPath -PathType Leaf)) { throw "MLC executable not found: $MlcPath" }
if (-not (Test-Path -LiteralPath $winsatPath -PathType Leaf)) { throw "WinSAT not found: $winsatPath" }

$mlcPathResolved = (Resolve-Path -LiteralPath $MlcPath).Path
$signature = Get-AuthenticodeSignature -FilePath $mlcPathResolved
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notlike '*Intel Corporation*') {
    throw "MLC must have a valid Intel Authenticode signature. Status: $($signature.Status); signer: $($signature.SignerCertificate.Subject)"
}
$mlcHash = (Get-FileHash -LiteralPath $mlcPathResolved -Algorithm SHA256).Hash

New-Item -ItemType Directory -Path $outputDirectory | Out-Null
$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$cpu = @(Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed)
$memory = @(Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, Manufacturer, PartNumber, Capacity, Speed, ConfiguredClockSpeed, SMBIOSMemoryType)
$battery = @(Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object Name, BatteryStatus, EstimatedChargeRemaining, Status)
$powerPlan = (powercfg /getactivescheme | Out-String).Trim()
$powerLineStatus = 'Unknown'
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    $powerLineStatus = [System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus.ToString()
} catch { $powerLineStatus = "Unavailable: $($_.Exception.Message)" }
$machine = [ordered]@{
    Captured = (Get-Date).ToString('o')
    ComputerName = $env:COMPUTERNAME
    ComputerModel = $computer.Model
    OS = [ordered]@{ Caption = $os.Caption; Version = $os.Version; BuildNumber = $os.BuildNumber; Architecture = $os.OSArchitecture; LastBootUpTime = $os.LastBootUpTime.ToString('o') }
    InstalledPhysicalMemoryBytes = $computer.TotalPhysicalMemory
    CPUs = $cpu
    MemoryModules = $memory
    Battery = $battery
    ACLineStatus = $powerLineStatus
    ActivePowerPlan = $powerPlan
}
$machine | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $outputDirectory 'machine.json')

$runInfo = [ordered]@{
    Started = (Get-Date).ToString('o')
    IsAdministrator = $true
    MlcPath = $mlcPathResolved
    MlcVersion = 'Intel Memory Latency Checker 3.13 expected; confirm from each raw output.'
    MlcSignatureStatus = $signature.Status.ToString()
    MlcSigner = $signature.SignerCertificate.Subject
    MlcSha256 = $mlcHash
    WinSATPath = $winsatPath
    MlcTests = @('idle_latency', 'max_bandwidth', 'peak_injection_bandwidth', 'loaded_latency')
    RepetitionsPerMlcTest = 5
    WinSATArguments = 'mem -mint 10 -maxt 20 -buffersize 256MB'
    WinSATRepetitions = 5
    DriverAction = 'None. This runner does not install, load, or remove a driver.'
    SystemChanges = 'None. This runner does not change policy, BIOS settings, or boot configuration.'
}
$runInfo | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $outputDirectory 'run-info.json')

$mlcTests = @(
    @{ Name = 'idle_latency'; Argument = '--idle_latency' },
    @{ Name = 'max_bandwidth'; Argument = '--max_bandwidth' },
    @{ Name = 'peak_injection_bandwidth'; Argument = '--peak_injection_bandwidth' },
    @{ Name = 'loaded_latency'; Argument = '--loaded_latency' }
)
foreach ($test in $mlcTests) {
    foreach ($run in 1..5) {
        $name = "mlc-$($test.Name)-$run"
        $started = (Get-Date).ToString('o')
        $watch = [Diagnostics.Stopwatch]::StartNew()
        & $mlcPathResolved $test.Argument 2>&1 | Out-File -LiteralPath (Join-Path $outputDirectory "$name.txt") -Encoding utf8
        $exitCode = $LASTEXITCODE
        $watch.Stop()
        [pscustomobject]@{
            Name = $name
            Arguments = $test.Argument
            Started = $started
            Completed = (Get-Date).ToString('o')
            ElapsedSeconds = [math]::Round($watch.Elapsed.TotalSeconds, 2)
            ExitCode = $exitCode
        } | ConvertTo-Json -Compress | Add-Content -LiteralPath (Join-Path $outputDirectory 'run-status.jsonl') -Encoding utf8
        if ($exitCode -ne 0) { throw "MLC failed for $name with exit code $exitCode. See output directory: $outputDirectory" }
        Write-Host "$name completed in $([math]::Round($watch.Elapsed.TotalSeconds, 1)) s"
    }
}

for ($run = 1; $run -le 5; $run++) {
    $name = "winsat-mem-$run"
    $started = (Get-Date).ToString('o')
    $watch = [Diagnostics.Stopwatch]::StartNew()
    & $winsatPath mem -mint 10 -maxt 20 -buffersize 256MB 2>&1 |
        Out-File -LiteralPath (Join-Path $outputDirectory "$name.txt") -Encoding utf8
    $exitCode = $LASTEXITCODE
    $watch.Stop()
    [pscustomobject]@{
        Name = $name
        Arguments = 'mem -mint 10 -maxt 20 -buffersize 256MB'
        Started = $started
        Completed = (Get-Date).ToString('o')
        ElapsedSeconds = [math]::Round($watch.Elapsed.TotalSeconds, 2)
        ExitCode = $exitCode
    } | ConvertTo-Json -Compress | Add-Content -LiteralPath (Join-Path $outputDirectory 'run-status.jsonl') -Encoding utf8
    if ($exitCode -ne 0) { throw "WinSAT failed for $name with exit code $exitCode. See output directory: $outputDirectory" }
    Write-Host "$name completed in $([math]::Round($watch.Elapsed.TotalSeconds, 1)) s"
}

$runInfo.Finished = (Get-Date).ToString('o')
$runInfo | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $outputDirectory 'run-info.json')
Write-Host "Completed the 25-run matrix. Results: $outputDirectory"
