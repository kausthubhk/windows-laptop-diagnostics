# Windows RAM, SSD, and battery validation notes

This project documents diagnostics and performance checks run on a Dell G3 3500 in September and October 2026. It includes sanitized evidence and scripts for future local measurements.

## Findings at a glance

- The laptop moved through 8 GiB (2×4 GiB, 10 September), 8 GiB (1×8 GiB, 14 October), and 12 GiB (8+4 GiB, 15 October). The 12 GiB setup adds capacity and the user reported Chrome and Codex felt smoother, with less heat, than during the earlier 8 GiB experience. A five-minute Netflix-in-Chrome + Codex session on 15 October was reported smooth. These are useful observations, not a controlled before/after test; the October session was on battery and temperature was not instrumented.
- Synthetic memory scores for the 12 GiB setup were lower than the 2×4 GiB 10 September baseline on all 11 bandwidth rows, with higher mean idle latency. Dates and platform conditions differed, and those figures do not predict that apps run a matching percentage slower. The 8+4 channel arrangement was not directly confirmed.
- The 16 GiB 2×8 GiB configuration is listed by Dell as supported ([memory specifications](https://www.dell.com/support/manuals/en-in/g-series-15-3500-laptop/dell-g3-15-3500-setup-and-specifications/memory?guid=guid-e9d2ea83-38a4-431d-803c-96d63c1dbc34&lang=en-us)), but it was not tested. The live workload showed some memory headroom constraints without sustained page-outs or disk queue. The 15 October report recommended keeping 12 GiB and did not show an urgent need to spend ₹4,500 for another 8 GiB module.
- A 19 September read-only SSD snapshot reported CrystalDiskInfo “Good (66%)” for a KIOXIA BG4 256 GB drive. The raw CrystalDiskInfo SMART line was `05 000000000022 Percentage Used`; its value `0x22` is hexadecimal for 34 decimal. That is consistent with the 66% health display. NVM Express defines this as a vendor-specific estimate of endurance consumed, not a remaining-years forecast. Critical warning, media/data-integrity errors, and error-log entries were zero in that snapshot. CrystalDiskMark was installed but not run.
- On 15 October, Windows and Dell software reported favorable battery function indicators, including 51,004 mWh reported design/full-charge capacity and passing SupportAssist battery and charger checks. Those checks did not authenticate the pack, establish newness, or measure a complete capacity cycle.

Read [observations](docs/OBSERVATIONS.md) for the full dated record and limits, [software inventory](docs/SOFTWARE.md) for tools and installation status, and the [publication proposal](docs/PUBLICATION-PROPOSAL.md) for the intended public scope and privacy choices.

## Reproduction scripts

The scripts in [`scripts/`](scripts/) are for new local captures. They write to ignored `local-results/` folders and never overwrite an existing output label.

- [`ram-suite.ps1`](scripts/ram-suite.ps1) runs the elevated WinSAT and Intel MLC matrix. Windows PowerShell must already be elevated; supply a locally downloaded, signed Intel MLC executable. The script does not install or load a driver, change power settings, or restart the computer.
- [`monitor-ram.ps1`](scripts/monitor-ram.ps1) samples Windows memory, processor, and disk counters during an ordinary workload. It groups process working sets for common browser and assistant process names, so those totals can include shared pages.
- [`compare-ram.py`](scripts/compare-ram.py) summarizes supported RAM output folders using Python's standard library. The Python installation version used by historical sessions was not captured.
- [`collect-battery.ps1`](scripts/collect-battery.ps1) collects Windows battery/power telemetry and can optionally create a native `powercfg /energy` report. That report option requires an already elevated shell; collection does not launch an elevation prompt.
- [`test-memory-patterns.ps1`](scripts/test-memory-patterns.ps1) runs an optional bounded 256 MiB user-mode pattern screen. It is not an exhaustive physical-memory test; recovery documentation describes its limits.
- [`prepare-public-results.py`](scripts/prepare-public-results.py) regenerates the explicit sanitized evidence allowlist. Its `--run-dir` and `--label` options can export a reviewed new run with a per-run manifest; the historical root manifest is preserved.
- [`RECOVERY.md`](docs/RECOVERY.md) documents official tool sources, prerequisites, manual checks, and recovery steps.

A benchmark compares performance; it is not a memory integrity test. WinSAT requires elevation. Intel MLC must be obtained separately under Intel's license. CrystalDiskMark performs storage writes and was not run in the historical session; use it only when a storage-write benchmark is deliberately wanted. Windows Memory Diagnostic and Dell preboot diagnostics require a restart and were not verified as completed successfully here.

## Results and provenance

- RAM baseline: [`results/ram/sep-2026-09-10/`](results/ram/sep-2026-09-10/)
- One 8 GiB module: [`results/ram/single-8gb-2026-10-14/`](results/ram/single-8gb-2026-10-14/)
- 8+4 GiB: [`results/ram/8gb-plus-4gb-2026-10-15/`](results/ram/8gb-plus-4gb-2026-10-15/)
- Netflix + Codex workload: [`results/workload/netflix-codex-12gb-2026-10-15/`](results/workload/netflix-codex-12gb-2026-10-15/)
- Battery summary: [`results/battery/2026-10-15-summary.md`](results/battery/2026-10-15-summary.md)
- Short battery telemetry: [`results/battery/2026-10-15-short-check-telemetry.csv`](results/battery/2026-10-15-short-check-telemetry.csv)
- SSD summary: [`results/ssd/2026-09-19-summary.md`](results/ssd/2026-09-19-summary.md) and [machine-readable data](results/ssd/2026-09-19-summary.json)
- Export provenance and output hashes: [`results/manifest.json`](results/manifest.json)

The manifest maps sanitized public files back to local source-relative names and records source/output SHA-256 hashes. Raw session logs, full application process lists, private hardware identifiers, raw battery reports, installers, drivers, archives, and local temporary caches are excluded. A manifest proves file transformation/hash correspondence, not the truth of every sensor value.

## Scope

The public proposal is for Windows memory, storage, and battery diagnostics on one laptop. It is not a general hardware repair guide, a warranty/authenticity determination, or a prediction of future component life. The local raw captures remain private and are not needed to use the scripts.
