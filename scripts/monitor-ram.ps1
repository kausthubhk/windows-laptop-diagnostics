[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]*$')]
    [string]$OutputLabel,

    [ValidateRange(1, 86400)]
    [int]$DurationSeconds = 300
)

$ErrorActionPreference = 'Stop'
$resultRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\local-results'))
$outputDirectory = Join-Path $resultRoot $OutputLabel
if (Test-Path -LiteralPath $outputDirectory) {
    throw "Output directory already exists; choose a new OutputLabel: $outputDirectory"
}
New-Item -ItemType Directory -Path $outputDirectory | Out-Null

$counterPaths = @(
    '\Memory\Available MBytes', '\Memory\Committed Bytes', '\Memory\Commit Limit',
    '\Memory\Pages Input/sec', '\Memory\Pages Output/sec', '\Memory\Page Reads/sec', '\Memory\Page Faults/sec',
    '\Processor(_Total)\% Processor Time', '\Processor(*)\% Processor Time',
    '\PhysicalDisk(_Total)\Avg. Disk sec/Read', '\PhysicalDisk(_Total)\Avg. Disk sec/Write',
    '\PhysicalDisk(_Total)\Current Disk Queue Length'
)

function Get-ProcessGroups {
    param([string]$FilePath)
    $groups = Get-Process | ForEach-Object {
        $category = if ($_.ProcessName -match '^(chrome|msedge)$') { 'browser' }
            elseif ($_.ProcessName -match '^(ChatGPT|codex)$') { 'assistant' }
            elseif ($_.ProcessName -match '^Netflix$') { 'Netflix app' }
            else { $null }
        if ($category) {
            [pscustomobject]@{ Category = $category; WorkingSet64 = $_.WorkingSet64; PrivateMemorySize64 = $_.PrivateMemorySize64 }
        }
    } | Where-Object { $null -ne $_ }
    $groups | Group-Object Category | ForEach-Object {
        [pscustomobject]@{
            Category = $_.Name
            ProcessCount = $_.Count
            WorkingSetMiB = [math]::Round((($_.Group | Measure-Object WorkingSet64 -Sum).Sum) / 1MB, 1)
            PrivateMemoryMiB = [math]::Round((($_.Group | Measure-Object PrivateMemorySize64 -Sum).Sum) / 1MB, 1)
        }
    } | Export-Csv -NoTypeInformation -Encoding utf8 -Path $FilePath
}

function Save-Context {
    param([string]$Suffix)
    $os = Get-CimInstance Win32_OperatingSystem
    $computer = Get-CimInstance Win32_ComputerSystem
    $powerLineStatus = 'Unknown'
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $powerLineStatus = [System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus.ToString()
    } catch { $powerLineStatus = "Unavailable: $($_.Exception.Message)" }
    [ordered]@{
        Captured = (Get-Date).ToString('o')
        ComputerName = $env:COMPUTERNAME
        BootTime = $os.LastBootUpTime.ToString('o')
        InstalledPhysicalMemoryBytes = $computer.TotalPhysicalMemory
        MemoryModules = @(Get-CimInstance Win32_PhysicalMemory | Select-Object DeviceLocator, Manufacturer, PartNumber, Capacity, Speed, ConfiguredClockSpeed)
        ActivePowerPlan = (powercfg /getactivescheme | Out-String).Trim()
        ACLineStatus = $powerLineStatus
        Battery = @(Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object Name, BatteryStatus, EstimatedChargeRemaining, Status)
    } | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $outputDirectory "context-$Suffix.json")
}

$start = Get-Date
Save-Context -Suffix 'start'
Get-ProcessGroups -FilePath (Join-Path $outputDirectory 'process-groups-start.csv')
$csvPath = Join-Path $outputDirectory 'telemetry.csv'
Write-Host "Capturing $DurationSeconds one-second samples. Output: $outputDirectory"

$sampleNumber = 0
Get-Counter -Counter $counterPaths -SampleInterval 1 -MaxSamples $DurationSeconds | ForEach-Object {
    $sampleNumber++
    $samples = $_.CounterSamples
    $find = {
        param([string]$Pattern)
        $item = $samples | Where-Object { $_.Path -match $Pattern } | Select-Object -First 1
        if ($null -eq $item) { return $null }
        return [double]$item.CookedValue
    }
    $processors = @($samples | Where-Object { $_.Path -match '\\Processor\(([^)]+)\)\\% Processor Time$' })
    $totalCpu = $processors | Where-Object { $_.Path -match '\\Processor\(_Total\)\\% Processor Time$' } | Select-Object -First 1
    $coreCpu = @($processors | Where-Object { $_.Path -notmatch '\\Processor\(_Total\)\\% Processor Time$' } | ForEach-Object { [double]$_.CookedValue })
    $row = [pscustomobject][ordered]@{
        Timestamp = $_.Timestamp.ToString('o')
        AvailableMiB = [math]::Round((& $find '\\Memory\\Available MBytes$'), 2)
        CommittedGiB = [math]::Round((& $find '\\Memory\\Committed Bytes$') / 1GB, 3)
        CommitLimitGiB = [math]::Round((& $find '\\Memory\\Commit Limit$') / 1GB, 3)
        PagesInputPerSec = [math]::Round((& $find '\\Memory\\Pages Input/sec$'), 2)
        PagesOutputPerSec = [math]::Round((& $find '\\Memory\\Pages Output/sec$'), 2)
        PageReadsPerSec = [math]::Round((& $find '\\Memory\\Page Reads/sec$'), 2)
        PageFaultsPerSec = [math]::Round((& $find '\\Memory\\Page Faults/sec$'), 2)
        CpuTotalPct = if ($totalCpu) { [math]::Round($totalCpu.CookedValue, 2) } else { $null }
        CpuCoreMaxPct = if ($coreCpu.Count) { [math]::Round(($coreCpu | Measure-Object -Maximum).Maximum, 2) } else { $null }
        DiskReadSec = [math]::Round((& $find '\\PhysicalDisk\(_Total\)\\Avg. Disk sec/Read$'), 5)
        DiskWriteSec = [math]::Round((& $find '\\PhysicalDisk\(_Total\)\\Avg. Disk sec/Write$'), 5)
        DiskQueue = [math]::Round((& $find '\\PhysicalDisk\(_Total\)\\Current Disk Queue Length$'), 2)
    }
    if (Test-Path -LiteralPath $csvPath) { $row | Export-Csv -NoTypeInformation -Append -Encoding utf8 -Path $csvPath }
    else { $row | Export-Csv -NoTypeInformation -Encoding utf8 -Path $csvPath }
    if (($sampleNumber % 60) -eq 0) { Write-Host "Recorded $sampleNumber/$DurationSeconds samples at $($row.Timestamp)" }
}

$finished = Get-Date
Save-Context -Suffix 'end'
Get-ProcessGroups -FilePath (Join-Path $outputDirectory 'process-groups-end.csv')
$rows = @(Import-Csv -LiteralPath $csvPath)
$summary = [ordered]@{
    Started = $start.ToString('o')
    Finished = $finished.ToString('o')
    Samples = $rows.Count
    FirstSample = if ($rows.Count) { $rows[0].Timestamp } else { $null }
    LastSample = if ($rows.Count) { $rows[-1].Timestamp } else { $null }
    SecondsBelow1GiBAvailable = @($rows | Where-Object { [double]$_.AvailableMiB -lt 1024 }).Count
    SecondsBelow2GiBAvailable = @($rows | Where-Object { [double]$_.AvailableMiB -lt 2048 }).Count
    SamplesPagesInputOver100PerSec = @($rows | Where-Object { [double]$_.PagesInputPerSec -gt 100 }).Count
    SamplesPagesInputOver1000PerSec = @($rows | Where-Object { [double]$_.PagesInputPerSec -gt 1000 }).Count
    SamplesPagesOutputOver100PerSec = @($rows | Where-Object { [double]$_.PagesOutputPerSec -gt 100 }).Count
    Metrics = [ordered]@{}
}
foreach ($field in 'AvailableMiB','CommittedGiB','CommitLimitGiB','PagesInputPerSec','PagesOutputPerSec','PageReadsPerSec','PageFaultsPerSec','CpuTotalPct','CpuCoreMaxPct','DiskReadSec','DiskWriteSec','DiskQueue') {
    $values = @($rows | ForEach-Object { if ($_."$field" -ne '') { [double]$_.$field } })
    if ($values.Count) {
        $summary.Metrics[$field] = [ordered]@{
            Mean = [math]::Round(($values | Measure-Object -Average).Average, 4)
            Min = [math]::Round(($values | Measure-Object -Minimum).Minimum, 4)
            Max = [math]::Round(($values | Measure-Object -Maximum).Maximum, 4)
        }
    }
}
$summary | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $outputDirectory 'summary.json')
Write-Host "Finished $($rows.Count) telemetry samples. Results: $outputDirectory"
