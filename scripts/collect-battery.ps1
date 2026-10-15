[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]*$')]
    [string]$OutputLabel,

    [ValidateRange(1, 86400)]
    [int]$DurationSeconds = 300,

    [ValidateRange(1, 3600)]
    [int]$SampleIntervalSeconds = 30,

    [switch]$EnergyReport,

    [ValidateRange(1, 3600)]
    [int]$EnergyReportDurationSeconds = 60,

    [switch]$SkipBatteryReport
)

$ErrorActionPreference = 'Stop'
$resultRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\local-results'))
$outputDirectory = Join-Path $resultRoot $OutputLabel
if (Test-Path -LiteralPath $outputDirectory) {
    throw "Output directory already exists; choose a new OutputLabel: $outputDirectory"
}
$principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if ($EnergyReport -and -not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'The optional powercfg energy report requires an already elevated PowerShell. No elevation prompt will be started.'
}
New-Item -ItemType Directory -Path $outputDirectory | Out-Null

function Get-ProviderRecord {
    param(
        [string]$ClassName,
        [string[]]$Properties
    )
    try {
        $instances = @(Get-CimInstance -Namespace 'root\wmi' -ClassName $ClassName -ErrorAction Stop)
        if ($instances.Count -eq 0) {
            return [pscustomobject]@{ State = 'NoInstances'; Error = $null; Data = $null }
        }
        $instance = $instances[0]
        $data = [ordered]@{}
        foreach ($property in $Properties) {
            if ($instance.PSObject.Properties.Name -contains $property) {
                $data[$property] = $instance.$property
            }
        }
        return [pscustomobject]@{ State = 'Available'; Error = $null; Data = [pscustomobject]$data }
    } catch {
        return [pscustomobject]@{ State = 'Unavailable'; Error = $_.Exception.Message; Data = $null }
    }
}

function Get-PowerContext {
    param([string]$Suffix)
    $os = Get-CimInstance Win32_OperatingSystem
    $system = Get-CimInstance Win32_ComputerSystem
    $powerLineStatus = 'Unknown'
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $powerLineStatus = [System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus.ToString()
    } catch { $powerLineStatus = "Unavailable: $($_.Exception.Message)" }
    $battery = @(Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object Name, Caption, Description, Manufacturer, DesignCapacity, FullChargeCapacity, EstimatedChargeRemaining, BatteryStatus, Status)
    $safeStatic = Get-ProviderRecord -ClassName 'BatteryStaticData' -Properties @('ManufacturerName','DeviceName','DesignedCapacity','Chemistry','Technology','ManufactureDate')
    $context = [ordered]@{
        Captured = (Get-Date).ToString('o')
        ComputerModel = $system.Model
        BootTime = $os.LastBootUpTime.ToString('o')
        InstalledPhysicalMemoryBytes = $system.TotalPhysicalMemory
        ACLineStatus = $powerLineStatus
        ActivePowerPlan = (powercfg /getactivescheme | Out-String).Trim()
        Win32Battery = $battery
        BatteryStaticDataProvider = $safeStatic
        BatteryFullChargedCapacityProvider = Get-ProviderRecord -ClassName 'BatteryFullChargedCapacity' -Properties @('FullChargedCapacity')
        BatteryCycleCountProvider = Get-ProviderRecord -ClassName 'BatteryCycleCount' -Properties @('CycleCount')
    }
    $context | ConvertTo-Json -Depth 7 | Set-Content -Encoding utf8 (Join-Path $outputDirectory "context-$Suffix.json")
}

function Add-Row {
    param([pscustomobject]$Row, [string]$Path)
    if (Test-Path -LiteralPath $Path) {
        $Row | Export-Csv -NoTypeInformation -Append -Encoding utf8 -Path $Path
    } else {
        $Row | Export-Csv -NoTypeInformation -Encoding utf8 -Path $Path
    }
}

Get-PowerContext -Suffix 'start'
if (-not $SkipBatteryReport) {
    $batteryReportPath = Join-Path $outputDirectory 'battery-report.html'
    $batteryReportOutput = & powercfg /batteryreport /output $batteryReportPath 2>&1
    [pscustomobject]@{
        Command = 'powercfg /batteryreport /output <private local output path>'
        ExitCode = $LASTEXITCODE
        Output = ($batteryReportOutput | Out-String).Trim()
        OutputFile = 'battery-report.html'
    } | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $outputDirectory 'battery-report-command.json')
}
if ($EnergyReport) {
    $energyReportPath = Join-Path $outputDirectory 'energy-report.html'
    $energyOutput = & powercfg /energy /duration $EnergyReportDurationSeconds /output $energyReportPath 2>&1
    [pscustomobject]@{
        Command = "powercfg /energy /duration $EnergyReportDurationSeconds /output <private local output path>"
        ExitCode = $LASTEXITCODE
        Output = ($energyOutput | Out-String).Trim()
        OutputFile = 'energy-report.html'
        RequiresAdministrator = $true
    } | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 (Join-Path $outputDirectory 'energy-report-command.json')
    if ($LASTEXITCODE -ne 0) { throw "powercfg /energy failed with exit code $LASTEXITCODE." }
}

$start = Get-Date
$deadline = $start.AddSeconds($DurationSeconds)
$csvPath = Join-Path $outputDirectory 'battery-telemetry.csv'
$sampleNumber = 0
Write-Host "Sampling battery status for $DurationSeconds seconds every $SampleIntervalSeconds seconds. Output: $outputDirectory"
while ((Get-Date) -le $deadline) {
    $sampleStart = Get-Date
    $status = Get-ProviderRecord -ClassName 'BatteryStatus' -Properties @('PowerOnline','Charging','Discharging','Critical','ChargeRate','DischargeRate','RemainingCapacity')
    $full = Get-ProviderRecord -ClassName 'BatteryFullChargedCapacity' -Properties @('FullChargedCapacity')
    $cycle = Get-ProviderRecord -ClassName 'BatteryCycleCount' -Properties @('CycleCount')
    $temperature = Get-ProviderRecord -ClassName 'BatteryTemperature' -Properties @('Temperature')
    $statusData = $status.Data
    $fullData = $full.Data
    $cycleData = $cycle.Data
    $temperatureData = $temperature.Data
    $row = [pscustomobject][ordered]@{
        Timestamp = $sampleStart.ToString('o')
        BatteryStatusProvider = $status.State
        BatteryStatusError = $status.Error
        PowerOnline = if ($statusData) { $statusData.PowerOnline } else { $null }
        Charging = if ($statusData) { $statusData.Charging } else { $null }
        Discharging = if ($statusData) { $statusData.Discharging } else { $null }
        Critical = if ($statusData) { $statusData.Critical } else { $null }
        RemainingCapacityMWh = if ($statusData) { $statusData.RemainingCapacity } else { $null }
        ChargeRateMilliwatts = if ($statusData) { $statusData.ChargeRate } else { $null }
        DischargeRateMilliwatts = if ($statusData) { $statusData.DischargeRate } else { $null }
        FullChargedCapacityProvider = $full.State
        FullChargedCapacityMWh = if ($fullData) { $fullData.FullChargedCapacity } else { $null }
        CycleCountProvider = $cycle.State
        CycleCount = if ($cycleData) { $cycleData.CycleCount } else { $null }
        TemperatureProvider = $temperature.State
        BatteryTemperatureRaw = if ($temperatureData) { $temperatureData.Temperature } else { $null }
        TemperatureUnits = if ($temperatureData) { 'Provider-native; verify platform definition before interpreting' } else { $null }
    }
    Add-Row -Row $row -Path $csvPath
    $sampleNumber++
    if (($sampleNumber % 5) -eq 0) { Write-Host "Recorded $sampleNumber battery samples at $($row.Timestamp)" }
    $nextSample = $sampleStart.AddSeconds($SampleIntervalSeconds)
    $remainingMs = [int][math]::Floor(($nextSample - (Get-Date)).TotalMilliseconds)
    if ((Get-Date) -ge $deadline -or $remainingMs -le 0) { break }
    Start-Sleep -Milliseconds $remainingMs
}

Get-PowerContext -Suffix 'end'
$rows = @(Import-Csv -LiteralPath $csvPath)
$summary = [ordered]@{
    Started = $start.ToString('o')
    Finished = (Get-Date).ToString('o')
    RequestedDurationSeconds = $DurationSeconds
    SampleIntervalSeconds = $SampleIntervalSeconds
    Samples = $rows.Count
    FirstSample = if ($rows.Count) { $rows[0].Timestamp } else { $null }
    LastSample = if ($rows.Count) { $rows[-1].Timestamp } else { $null }
    BatteryStatusProviderStates = @($rows | Group-Object BatteryStatusProvider | ForEach-Object { [pscustomobject]@{ State = $_.Name; Samples = $_.Count } })
    FullCapacityProviderStates = @($rows | Group-Object FullChargedCapacityProvider | ForEach-Object { [pscustomobject]@{ State = $_.Name; Samples = $_.Count } })
    TemperatureProviderStates = @($rows | Group-Object TemperatureProvider | ForEach-Object { [pscustomobject]@{ State = $_.Name; Samples = $_.Count } })
    NumericMetrics = [ordered]@{}
}
foreach ($field in 'RemainingCapacityMWh','ChargeRateMilliwatts','DischargeRateMilliwatts','FullChargedCapacityMWh','CycleCount','BatteryTemperatureRaw') {
    $values = @($rows | ForEach-Object { if ($_."$field" -ne '') { [double]$_.$field } })
    if ($values.Count) {
        $summary.NumericMetrics[$field] = [ordered]@{
            Mean = [math]::Round(($values | Measure-Object -Average).Average, 3)
            Min = [math]::Round(($values | Measure-Object -Minimum).Minimum, 3)
            Max = [math]::Round(($values | Measure-Object -Maximum).Maximum, 3)
            Samples = $values.Count
        }
    }
}
$summary | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $outputDirectory 'summary.json')
Write-Host "Finished $($rows.Count) battery samples. Results: $outputDirectory"
