# Windows laptop diagnostics

A collection of Windows scripts and notes for checking memory performance, observing a normal workload, collecting battery telemetry, and reviewing selected storage health indicators. The scripts are intended for local use on Windows 10 or 11. They collect evidence; they do not diagnose every hardware fault or certify a device as healthy.

## Choose a workflow

Start with the question you want to answer. For a slow or stuttering laptop, observe the usual workload before running a synthetic benchmark. For memory comparisons, use the same benchmark and conditions on each run. For battery concerns, collect the available Windows readings and note that device vendors expose different data. This repository has no automated SSD diagnostic script; its storage guidance is a manual, read-only SMART observation.

| Goal | Tool | What it records |
| --- | --- | --- |
| Compare RAM performance | [`scripts/ram-suite.ps1`](scripts/ram-suite.ps1) | Intel MLC and Windows WinSAT output, run status, system and module inventory |
| Observe a workload | [`scripts/monitor-ram.ps1`](scripts/monitor-ram.ps1) | Memory, paging, CPU, disk counters, and grouped process memory |
| Collect battery readings | [`scripts/collect-battery.ps1`](scripts/collect-battery.ps1) | Windows battery providers, power context, and a battery report; optional energy report |
| Run a limited memory check | [`scripts/test-memory-patterns.ps1`](scripts/test-memory-patterns.ps1) | Pattern checks over one bounded user-mode buffer |
| Summarize RAM benchmark output | [`scripts/compare-ram.py`](scripts/compare-ram.py) | Statistics from supported WinSAT/MLC output folders |
| Export reviewed evidence | [`scripts/prepare-public-results.py`](scripts/prepare-public-results.py) | Explicitly allowlisted, sanitized text files and a hash manifest |

## Getting started

Windows 10 or 11 and Windows PowerShell 5.1 are the supported baseline. Clone the repository and open PowerShell in its directory:

```powershell
git clone https://github.com/kausthubhk/windows-laptop-diagnostics.git
Set-Location windows-laptop-diagnostics
```

Python 3.10 or newer is optional and needed only for the Python comparison and export scripts; both use the standard library. Intel MLC is needed only for the RAM benchmark, and must be obtained separately under Intel's license terms. Other workflows use Windows components and the included PowerShell scripts.

Use a fresh, unique output label for each capture. PowerShell scripts write beneath `local-results/<label>/`, which is ignored by Git, and refuse to reuse an existing label. Start PowerShell in the repository root. If script execution is blocked by the machine's policy, follow the device owner's or organization's policy; these instructions do not relax it.

To observe an ordinary workload, start the workload yourself and run a non-elevated PowerShell session:

```powershell
& .\scripts\monitor-ram.ps1 -OutputLabel 'workload-example-01' -DurationSeconds 300
```

The monitor samples for one second per sample. It requests English performance counter names, so some counters may fail on localized Windows installations. Process groups use common browser and assistant process names. The context files contain machine and module details, so review them before sharing.

To collect battery readings over five minutes:

```powershell
& .\scripts\collect-battery.ps1 -OutputLabel 'battery-example-01' -DurationSeconds 300 -SampleIntervalSeconds 30
```

The collector does not change charging settings or perform a full capacity test. The default battery HTML report may contain identifying details and battery history; treat it as private. `-EnergyReport` additionally runs `powercfg /energy` and requires an already elevated PowerShell window; the script will not request elevation. Providers may be unavailable on a particular device, and missing values are not zero.

For a RAM performance matrix, first obtain Intel Memory Latency Checker under its license terms. The runner requires an already elevated PowerShell window and a valid Intel Authenticode signature on the selected executable. It runs four MLC modes five times each and WinSAT five times. This is a sustained synthetic workload; stop if the laptop is unstable or under memory pressure.

```powershell
& .\scripts\ram-suite.ps1 `
  -OutputLabel 'ram-example-01' `
  -MlcPath 'C:\Path\To\mlc\Windows\mlc.exe'
```

The suite does not install or load drivers, change power or boot settings, or restart the computer. MLC is not included in this repository. Use the [Intel MLC download and documentation](https://www.intel.com/content/www/us/en/developer/articles/tool/intelr-memory-latency-checker.html) to review its source and terms.

The optional memory pattern screen checks a single 64–512 MiB user-mode buffer with eight patterns. It skips the test when available memory is below its threshold (768 MiB by default). A pass covers only that buffer and those patterns; it does not test all physical RAM or certify DIMMs.

```powershell
& .\scripts\test-memory-patterns.ps1 -OutputLabel 'memory-screen-example-01'
```

Python's standard library is enough to compare existing RAM result folders. The comparison script does not run benchmarks:

```powershell
python .\scripts\compare-ram.py `
  --config 'run-a=local-results/ram-run-a' `
  --config 'run-b=local-results/ram-run-b'
```

Use the script's `--help` for all options. Its JSON includes resolved input directory paths and machine metadata, so review it before sharing. It summarizes recognized text; it cannot establish that two runs had equivalent conditions.

Use the parameterized scripts under `scripts/` for new captures. Older root-level scripts and `.cmd` wrappers belong to the historical workflow: some contain machine-specific paths, and the wrappers invoke PowerShell with an execution-policy bypass. They are not part of this generic quickstart.

## Review and interpret results

Record the laptop model, Windows build, installed memory configuration, tool versions, date, AC/battery state, active power plan, workload, and any errors. Keep direct observations such as “the video stuttered at 10:32” separate from counter readings. For comparisons, document differences in background work, temperature, power source, firmware, and operating system activity. See the [run template](docs/RUN-TEMPLATE.md).

Counters and benchmarks are clues, not a diagnosis. A memory bandwidth score is not a measure of application speed. Paging counters can rise for normal reasons; interpret them with available memory, workload timing, and disk activity. The memory pattern screen is bounded. Battery health and capacity values depend on Windows and vendor providers and are not a complete charge/discharge test or proof of battery provenance. A SMART health label is a snapshot rather than a guarantee of future storage reliability.

Before sharing results, inspect them for usernames, absolute paths, machine and module identifiers, battery history, installed software, and other private details. The public-results exporter uses an explicit allowlist, but its output still needs review. Its default mode rebuilds generated files under `results/` and updates `results/manifest.json`; inspect the resulting diff before keeping or sharing it. Its `--run-dir` mode writes a new labeled export under `results/` and refuses an existing label. Do not share raw capture directories by default. See [privacy notes](docs/PRIVACY.md) and the [exporter](scripts/prepare-public-results.py).

## SSD observations

There is no automated SSD test in this repository. If a SMART viewer is already available, record its drive model, health indicator, temperature, and selected attributes with a timestamp. The notes recommend a read-only observation and do not call for a surface scan, firmware update, or write benchmark. SMART fields and vendor labels vary and do not predict remaining service life. See [software and tool notes](docs/SOFTWARE.md).

## More detail

- [Recovery and workflow guide](docs/RECOVERY.md) describes requirements, commands, expected output, and limitations.
- [Software inventory](docs/SOFTWARE.md) records tool provenance and historical use.
- [Observations](docs/OBSERVATIONS.md), [sanitized results](results/), and [manifest](results/manifest.json) are dated examples from prior runs, not expected results for another laptop.
- [Publication proposal](docs/PUBLICATION-PROPOSAL.md) explains the scope of the historical evidence.
- [RAM benchmark notes](README-RAM-BENCHMARKS.md) cover the earlier benchmark work.

## Reusable Codex skill

This repository includes a reusable skill at [`.agents/skills/windows-laptop-diagnostics/SKILL.md`](.agents/skills/windows-laptop-diagnostics/SKILL.md). To use it from this checkout, ask Codex: “Use `.agents/skills/windows-laptop-diagnostics/SKILL.md` to help me investigate high memory use during my usual workload.”
