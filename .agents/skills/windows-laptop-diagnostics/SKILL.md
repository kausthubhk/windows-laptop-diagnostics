---
name: windows-laptop-diagnostics
description: Plan and interpret evidence-first Windows laptop memory, workload, battery, and optional storage checks using this repository's scripts. Use when diagnosing or comparing laptop behavior; do not infer a hardware fault from a single metric.
---

# Windows laptop diagnostics

Use this skill when working from this repository to collect or interpret Windows laptop diagnostic evidence. Read the relevant script and [repository workflow](../../../README.md) before choosing a command. The skill is stored in the repository; invoke it by its repository path unless it has separately been installed in a location the current Codex setup discovers.

## Choose the least intrusive useful evidence

- For a slowdown or stutter, begin with the user's normal workload and `scripts/monitor-ram.ps1`. This records Windows memory, paging, CPU, disk counters and grouped process memory; it does not record process IDs or command lines. The English performance counter names may fail on localized Windows.
- Use `scripts/ram-suite.ps1` only when a synthetic RAM comparison answers the question. It runs four Intel MLC modes five times each and five WinSAT runs. It requires an already elevated PowerShell window, a separately obtained MLC executable with a valid Intel Authenticode signature, and subjects the machine to sustained benchmark load. It does not self-elevate or change drivers, power settings, boot configuration, or restart the machine.
- Use `scripts/collect-battery.ps1` for available battery and power-provider data. It creates a Windows battery report by default; treat that report and capture context as private. `-EnergyReport` requires an already elevated shell. Collection does not change charging settings or perform a full battery capacity test. Missing provider data is unavailable, not zero.
- `scripts/test-memory-patterns.ps1` is optional and bounded: it writes and verifies patterns in one 64–512 MiB managed buffer, after checking available memory (768 MiB minimum by default). It is not a physical RAM test or certification. Do not run it on a constrained or unstable machine.
- There is no automated SSD diagnostic script here. The documented SSD workflow is a manual, read-only SMART observation if a viewer is already available. Do not characterize it as a surface test or remaining-life forecast.

When the machine is unstable, under memory pressure, or the measurement would interrupt important work, stop and discuss safer evidence or professional diagnostics. Do not run all workflows automatically; choose only what helps answer the user's question.

## Run and protect captures

PowerShell scripts expect Windows PowerShell-compatible environments and repository-relative paths. Start from the repository root and choose a new label each time. Scripts write under ignored `local-results/` and refuse to overwrite existing labels. Do not relax execution policy if a script is blocked; follow the device owner's or organization's policy.

Before sharing, inspect every output for user or machine names, absolute paths, hardware identifiers, installed software, battery history, and other private activity. Comparison JSON includes resolved input paths and machine metadata. The public exporter is an explicit allowlist, not a guarantee that an export is safe; its default mode rebuilds generated files under `results/` and updates the manifest, so inspect the diff afterward. Keep raw captures private by default.

Do not install tools, alter firmware or power settings, start battery charge/discharge cycles, run write benchmarks, restart the machine, or make external changes unless the user explicitly requests that exact action. An elevated prompt is a requirement of a particular script, not permission to make unrelated system changes. Never launch a script that uses machine-specific paths without reviewing it and adapting the paths explicitly.

## Interpret evidence carefully

Record the exact workload, time, Windows and tool versions, power source, power plan, available memory, and relevant errors. Keep user-reported symptoms separate from measured counters. Compare runs only after documenting differences in hardware, background activity, thermal state, power source, firmware, and OS activity.

Explain what each measure can support and where it stops. Synthetic bandwidth is not application speed; paging activity alone does not prove memory shortage; grouped process working sets can include shared pages; a bounded pattern pass does not cover all physical memory; software-reported battery and SMART values do not establish physical provenance or future reliability. Treat unavailable readings as unknown. Use [docs/RECOVERY.md](../../../docs/RECOVERY.md), [docs/RUN-TEMPLATE.md](../../../docs/RUN-TEMPLATE.md), and [docs/PRIVACY.md](../../../docs/PRIVACY.md) for details when relevant.
