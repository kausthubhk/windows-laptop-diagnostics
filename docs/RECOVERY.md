# RAM and battery test recovery guide

This guide records how to reproduce the Windows memory benchmarks, capture a normal workload, and sample battery telemetry without changing system configuration. The checked-in `results/` tree contains sanitized historical evidence. New captures belong under `local-results/` and should be reviewed for private data before sharing.

For a future run, copy [the run template](RUN-TEMPLATE.md) and record the configuration, tool versions, conditions, measurements, and user observations separately.

## Repository evidence

The public, sanitized evidence is organized as follows:

| Evidence | Path |
| --- | --- |
| Earlier 8 GB configuration | `results/ram/sep-2026-09-10/` |
| Single 8 GB module | `results/ram/single-8gb-2026-10-14/` |
| 8 GB + 4 GB modules | `results/ram/8gb-plus-4gb-2026-10-15/` |
| Netflix and assistant normal-workload capture | `results/workload/netflix-codex-12gb-2026-10-15/` |
| Battery findings summary | `results/battery/2026-10-15-summary.md` |
| Machine manifest | `results/manifest.json` |

The 8 GB + 4 GB machine had a Samsung 8 GB module (M471A1K43EB1-CWE) and a Samsung 4 GB module (M471A5244CB0-CWE). Both are rated for 3200 MT/s; the system configured memory at 2933 MT/s. Consult the manifest and raw run metadata for the exact machine state captured with each test. Comparisons across dates can include differences in background applications, power source, thermal state, firmware, and OS activity.

The manifest records SHA-256 hashes for each sanitized evidence file. `.gitattributes` marks `results/**` as byte-preserved so checkout line-ending conversion does not change those published evidence hashes; this verifies file integrity against the manifest, not the accuracy of the original sensors or measurements.

The October 15 synthetic benchmark used Intel Memory Latency Checker (MLC) v3.13 and Windows System Assessment Tool (WinSAT). It completed 20 MLC runs (four tests, five repetitions each) and five WinSAT memory runs. A later five-minute normal-workload capture recorded Netflix playing in Chrome with the assistant open. The user reported both felt smooth and no unusual heat; this is a subjective observation, not frame-time or temperature instrumentation. System telemetry can show memory, paging, CPU, and disk activity, but cannot establish whether video frames stuttered.

## Requirements and tool provenance

For a clean recovery, clone the repository from its official remote, then use the checked-in scripts and sanitized `results/` files; no raw session folder is required. Windows 10/11 includes Windows PowerShell 5.1, which is the target for the `.ps1` scripts. Python 3.10 or newer is required for `scripts/compare-ram.py` (it uses union type annotations) and only the standard library. WinSAT and `powercfg` are Windows components. No Python packages or other software need installing for the core workflow.

```powershell
$repositoryUrl = Read-Host 'Repository URL'
$destination = Read-Host 'Destination folder'
git clone $repositoryUrl $destination
Set-Location $destination
$PSVersionTable.PSVersion
python --version
```

Use the repository's official remote URL when available. Do not install PowerShell 7 or Python from an unverified mirror just for these scripts.

Windows execution policy may block locally checked-out or downloaded PowerShell scripts, depending on the machine's policy and file marking. If PowerShell blocks a script, stop and follow the device owner's or organization's policy; do not run with `-ExecutionPolicy Bypass`, set a process-wide bypass, or relax policy automatically. Any policy exception must be an explicit administrator/user decision outside this recovery procedure.

MLC is optional and must be obtained manually from Intel's [Memory Latency Checker page](https://www.intel.com/content/www/us/en/developer/articles/tool/intelr-memory-latency-checker.html), subject to Intel's download/license terms. The historical run used v3.13; the captured `mlc.exe` had SHA-256 `8d5622be464c956e161ed9546bf060fe9ff118feba082675c160a49358ac280f` and a valid Intel Corporation Authenticode signature. The runner requires the selected `mlc.exe` to have a valid Authenticode signature from Intel Corporation and records its path, signature, and SHA-256 hash. Do not commit the MLC binary or redistribute it. A different MLC version or a managed-code substitute is not an equivalent run.

The optional CPU-Z utility was used historically for SPD/module inspection, not for the routine performance matrix. It is not needed to run these scripts. If module details are unavailable from Windows, obtain CPU-Z from [CPUID](https://www.cpuid.com/softwares/cpu-z.html), verify the downloaded archive against CPUID's published checksum list, and review its signature before use. Avoid running its elevated SPD mode unless a fresh hardware inventory is specifically needed.

## Run the RAM benchmark matrix

Open an already elevated PowerShell window. The suite intentionally refuses to self-elevate. It makes no policy, BIOS, boot, or driver changes and does not reboot. It requires administrator access because the original comparable measurements were captured elevated. If elevation is unavailable, stop and record that barrier; a non-elevated substitute is not the same test.

From the repository root, run a new label and provide the explicit path to Intel's signed executable:

```powershell
& .\scripts\ram-suite.ps1 `
  -OutputLabel 'ram-2026-10-15-example' `
  -MlcPath 'C:\Path\To\mlc_v3.13\Windows\mlc.exe'
```

This executes five repetitions each of `mlc.exe --idle_latency`, `--max_bandwidth`, `--peak_injection_bandwidth`, and `--loaded_latency`, followed by five runs of `WinSAT.exe mem -mint 10 -maxt 20 -buffersize 256MB`. It writes raw output, run status, machine inventory, and tool provenance to `local-results/<OutputLabel>/`. Labels are restricted to filename-safe characters, and an existing output directory causes the run to stop rather than overwrite data. The full suite is a sustained synthetic workload; close no applications as part of this procedure, and do not run it if the machine is unstable or under memory pressure.

## Optional bounded user-mode memory screen

`scripts/test-memory-patterns.ps1` carries forward the historical limited test: one pinned 256 MiB managed buffer is written and verified with eight byte patterns, for 2 GiB written and 2 GiB verified total. It checks available memory before allocating and skips below 768 MiB by default. It is not an exhaustive physical-memory test and cannot prove every DIMM page is fault-free. This test is opt-in and is not run as part of recovery or routine comparison.

```powershell
& .\scripts\test-memory-patterns.ps1
```

It writes one JSON report to a unique `local-results/memory-screen-<timestamp>/` folder. A caller may provide `-OutputLabel` to choose a different unique label, `-BufferMiB` from 64 to 512, or `-MinimumAvailableMiB` from 256 to 4096. Existing output folders are refused. Do not lower the safety threshold to force a run when memory is scarce.

## Capture a normal workload

Run this in an ordinary, non-elevated PowerShell session while the user has already started the workload they want observed:

```powershell
& .\scripts\monitor-ram.ps1 -OutputLabel 'workload-2026-10-15-example' -DurationSeconds 300
```

The monitor streams one-second counter samples to CSV and records start/end system and process-group snapshots. It captures available and committed memory, paging counters, CPU, disk latency/queue, and grouped process memory. Process names are summarized into broad categories; command lines and process identifiers are not collected. The `context-*.json` inventory can still reveal machine-specific details, so inspect it before sharing. Record the workload and the user's observation separately, with timestamps; do not infer visible stutter, heat, or a fault from counters alone.

The monitor requests English Windows performance-counter names. On a localized Windows installation, `Get-Counter` may reject one or more names and the capture may stop; record that error rather than changing the system language or counter configuration.

## Capture battery telemetry

The collector samples Windows battery WMI providers and records power source/plan context. It does not change charging settings, discharge the battery, or run a deep battery test. Provider errors and missing instances are represented as `Unavailable` or `NoInstances`, never as zero.

For a short discharge observation, start on AC, unplug manually, then run:

```powershell
& .\scripts\collect-battery.ps1 -OutputLabel 'battery-discharge-2026-10-15-example' -DurationSeconds 300 -SampleIntervalSeconds 30
```

For a separate charge observation, reconnect AC manually and use a different label. Each run captures its own battery-report HTML by default. That report can contain battery history and identifying details; treat it as private and redact it before sharing. Outputs are kept under `local-results/<OutputLabel>/` and existing labels are refused.

An optional Windows energy report can be requested from an already elevated PowerShell session:

```powershell
& .\scripts\collect-battery.ps1 -OutputLabel 'battery-energy-2026-10-15-example' -DurationSeconds 60 -SampleIntervalSeconds 10 -EnergyReport
```

The script errors if `-EnergyReport` is requested without existing elevation; it does not show a UAC prompt. Battery temperature or cycle-count providers may be absent on a given laptop. Missing readings mean unavailable, not zero. Historical observations reported an excellent Dell battery health status and successful vendor quick tests, but did not include an ePSA or deep-capacity test. These historical results do not replace current diagnostics.

For manual UI checks, note the timestamp and observed text from **Settings > System > Power & battery**, **My Dell > Power/Battery**, and **SupportAssist > Diagnostics > Battery and Charger** when those screens are available. On this laptop, historical My Dell showed “Excellent” and “Dell Battery: Yes”; SupportAssist battery and charger functional tests passed. A health label or quick check is not a controlled capacity or authenticity test. Do not change charging mode, BIOS options, or battery settings during evidence collection.

## Optional SSD health observation

If CrystalDiskInfo is already installed, open it and record the displayed drive model, health status, temperature, and SMART attributes with a timestamp. This is a manual read-only observation; do not run a disk benchmark, surface scan, firmware update, or write test as part of this recovery. If it is not installed, skip it rather than installing software for this workflow. CrystalDiskInfo's official project is [Crystal Dew World](https://crystalmark.info/en/software/crystaldiskinfo/). SMART status and vendor UI labels are indicators, not a full media test; record missing or unsupported attributes as unavailable.

## Future 8 GB + 8 GB configuration

If an 8 GB replacement module is acquired and installed later, capture the part number, rank/timing data if available, configured memory speed, date, firmware/OS, AC state and power plan, and tool version/hash. First verify Windows sees the expected capacity and both modules. Then repeat the same elevated 25-command matrix and a separately labeled normal-workload capture. Compare primarily with the September 2×4 GiB baseline and the current 8+4 GiB setup; the single-8 GiB run is a temporary isolation reference, not the user's normal configuration. Module, date, background load, power, and thermal differences remain confounders. This is a future procedure only; no 8+8 GB test is included here.

## Compare results

The comparison tool reads folders recursively, summarizes recognized MLC/WinSAT outputs, and can associate separate monitor folders with matching labels. It writes JSON to standard output unless an output path is provided; it refuses to overwrite an existing report.

```powershell
python .\scripts\compare-ram.py `
  --config 'single-8gb=results/ram/single-8gb-2026-10-14' `
  --config '8gb-plus-4gb=results/ram/8gb-plus-4gb-2026-10-15' `
  --telemetry '8gb-plus-4gb=results/workload/netflix-codex-12gb-2026-10-15'
```

Use the sanitized `results/` paths for public comparisons. Do not point a public report at `local-results/` until its files have been reviewed for personal paths, machine identifiers, battery history, and any unintended application data.
