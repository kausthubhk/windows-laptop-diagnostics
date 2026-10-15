# Public evidence manifest

This allowlist defines the candidate text-only evidence for a future public repository. It was prepared locally and does not publish or stage anything. Original workspace artifacts remain untouched; they must stay excluded from public uploads.

## Candidate files

`results/manifest.json` is the machine-readable file manifest. For each generated evidence file it records the source-relative path, SHA-256 of the source and output, byte count, and transformation. The manifest itself is not self-hashed. `scripts/prepare-public-results.py` rebuilds only the explicitly listed outputs under `results/`; it does not modify or remove source evidence. It refuses to complete if its final privacy scan detects a configured identifier pattern.

| Public path | Contents |
|---|---|
| `results/ram/sep-2026-09-10/` | 2×4 GiB baseline: allowlisted hardware fields, five WinSAT runs, five runs of each MLC mode, and filtered PerfMon memory telemetry. |
| `results/ram/single-8gb-2026-10-14/` | 1×8 GiB comparison: same benchmark matrix, filtered telemetry, limited 256 MiB pattern-screen aggregate, and bounded memory-event observations. |
| `results/ram/8gb-plus-4gb-2026-10-15/` | 8+4 GiB comparison: matched benchmark matrix, hardware fields, and paging-pressure counters. |
| `results/ram/benchmark-comparison-2026-10-15.md` | Reviewed descriptive benchmark table and interpretation, with local links removed. |
| `results/workload/netflix-codex-12gb-2026-10-15/` | 300-sample memory/CPU/disk counter capture, aggregate summary, and app-group memory totals without PIDs or window titles. The user observation is explicitly labeled subjective; the baseline did not confirm Netflix playback. |
| `results/battery/2026-10-15-summary.md` and `results/battery/2026-10-15-short-check-telemetry.csv` | Short battery findings plus the bounded 10-minute check's allowlisted timestamp/numeric/status telemetry; dense activity history and raw reports are excluded. |
| `results/ssd/2026-09-19-summary.json` and `.md` | Selected SMART fields from a same-session CrystalDiskInfo report outside the workspace; the source report itself is not copied. |

Current allowlist output: 101 text files, 393,787 bytes. The generated manifest records the actual current hashes and sizes. The source inventory in that manifest reports counts and bytes for the benchmark, validation, battery, research, and cache areas without embedding private identifier values. These totals are a preparation-time snapshot.

## Source inventory and exclusions

The workspace contains useful performance measurements mixed with raw event records, process inventories, local reports, and hardware identifiers. `ram-results/` includes 155 files (524,835 bytes); `ram-validation-2026-10-14/` has 63 files (26,551,134 bytes); `ram-validation-2026-10-15/` has 6 files (140,763 bytes); and `battery-diagnostics-20261015-104721/` has 48 files (17,081,704 bytes). These are source-area totals, not public-file totals. The exact per-area inventory is in `results/manifest.json`.

The following remain private or excluded from the candidate set:

- Raw machine inventories and event messages; raw process lists and user-activity titles; PIDs; identity-bearing event or report files.
- Battery HTML/XML reports, dense battery activity history and usage timelines, private PPID/identity captures, and installer logs. The short controlled telemetry CSV above is the only battery time series included.
- CPU-Z executables, driver-capable tools, ZIP archives, and other third-party binaries. The local CPU-Z report may contain hardware identifiers. Cite the official vendor download separately if needed; do not distribute the binary.
- Raw comparison HTML, handoff ZIP/prompt, Repomix output, research/chat log, `tmp/` package cache, and Python bytecode.
- The external CrystalDiskInfo source report and all CrystalDiskMark output (the benchmark was not run).
- Every file not named by the export allowlist, including all future local captures until individually reviewed.

Raw MLC and WinSAT text logs are included only as sanitized copies. They retain flags, benchmark output, run timestamps, and units; local executable/output paths are omitted. The September suite is the historical 2×4 GiB baseline, October 14 is 1×8 GiB, and October 15 is 8+4 GiB. The matrix has five runs per test. Successful benchmark exit codes mean the benchmark programs completed; they are not memory-integrity results. The 256 MiB screen is a limited user-mode check. The Windows Memory Diagnostic outcome remains unknown because no result event was captured.

## Rebuild

From the workspace root, run `python scripts/prepare-public-results.py` to rebuild the historical allowlist. For one new monitor or battery capture, use `python scripts/prepare-public-results.py --run-dir <local-capture-directory> --label <new-label>`; this uses fixed text/CSV field allowlists, writes a run-local manifest, preserves the historical root manifest, and refuses an existing destination. The generic exporter was smoke-checked against local syntax fixtures; the RAM-suite `machine.json` path has not been exercised with a full suite. Review generated files and manifests before any later sharing decision. This preparation does not authorize staging, committing, pushing, or publishing.
