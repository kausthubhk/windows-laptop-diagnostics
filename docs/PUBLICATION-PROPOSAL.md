# Publication scope and privacy decisions

**Suggested repository name:** `windows-laptop-diagnostics`

**Working description:** Reproducible Windows memory, SSD-health, and battery checks, with sanitized 2026 observations from one Dell G3 3500.

A public clone can restore the reviewed methods and sanitized evidence, but it will not restore private session history, raw machine identifiers, full battery activity reports, installers, or every local capture. This is not a complete backup of the laptop or its private diagnostic history. Keep a separate private backup if preserving those materials is important.

## Included scope

- Root `README.md` with current practical findings, reproduction entry points, and clear limitations.
- `docs/OBSERVATIONS.md` with the dated 10 September, 19 September, 14 October, and 15 October 2026 evidence, separating instrument readings from user reports.
- `docs/SOFTWARE.md` listing Windows components and downloaded/installed/portable tools, including outcomes and version/provenance gaps.
- `docs/RECOVERY.md` with safe manual Windows recovery and repeat-test instructions, including official source links and reboot/write warnings.
- `scripts/` with Windows data collectors, an optional bounded memory screen, a standard-library comparison utility, and a sanitized-results exporter. Captures write to ignored `local-results/` and require deliberate elevated launch only where the specific Windows command requires it. The memory-screen script has only had syntax and safety-guard checks; it was not rerun against RAM.
- `results/` with reviewed, allowlisted summaries and selected run-level RAM/workload evidence. `results/manifest.json` records each exported file’s local source-relative path and input/output SHA-256 hashes.

## Evidence included in the reviewed scope

- Sanitized 2×4 GiB, 1×8 GiB, and 8+4 GiB RAM inventory and run outputs. These make the synthetic comparison reproducible while preserving dates, command flags, sample counts, units, and caveats.
- Sanitized five-minute Netflix + browser + coding-assistant counter summary and user-reported note, with battery state and no-A/B limitations.
- Battery result summary and short sanitized telemetry aggregates. Keep detailed battery-report XML/HTML, full telemetry timeline, exact serial/PPID, and service/device IDs local.
- A brief SSD summary from the 19 September CrystalDiskInfo capture: model family, “Good (66%)” reader status, raw SMART `Percentage Used` value `0x22` (34 decimal), zero critical/error counters, and the caveat that the endurance estimate does not predict remaining years. No unrelated drive identifier is needed.
- Scripts and official references, not downloadable third-party program binaries.

## Exclusions and privacy tradeoffs

- Raw desktop/session JSONL and chat transcripts. These include messages unrelated to this hardware work, tool prompts, local file paths, and personal context.
- Full process inventories/top-process timelines. They can reveal app use and work patterns. Aggregate workload counters are enough to understand memory pressure.
- Service tag, system UUID, BIOS/baseboard serials, Windows account/computer names, battery serial and PPID, raw SPD serial bytes, raw battery report identifiers, and other unique identifiers.
- Raw Windows event XML/EVTX and broad Event Viewer exports. Publish a short statement of query range/result instead of unrelated system events.
- Battery raw reports and detailed battery-change timeline. A summary provides the outcome and limitations without disclosing a detailed usage chronology.
- CrystalDiskInfo's full raw drive report. The compact summary exposes the health findings needed to discuss the concern; full host reads/writes, power-on counts, firmware and controller metadata disclose additional device-use details.
- `CrystalDiskMark` results, because no benchmark was run. Do not fabricate an SSD performance score.
- Intel MLC, CPU-Z, CrystalDiskInfo, CrystalDiskMark, Dell installers, drivers, and archives. They are third-party software with separate license/distribution rules. Readers should obtain them from the official links in `docs/SOFTWARE.md`.
- Temporary caches, installers, executables, drivers, screenshots, handoff ZIPs, generated repomix archives, unrelated research/chat export, and local-only `local-results/` captures.

Sanitizing results improves privacy but removes detail that another analyst could use to check the raw collection context. The manifest keeps source/output hashes and transform notes for traceability; it cannot replace a raw-file review. If the owner prefers maximal independent verification over privacy, that should be a deliberate second publication decision, with each raw file individually reviewed first.

## Claims and wording

The public material should say that the 12 GiB session felt smoother to the user and that a short user-confirmed Netflix + coding-assistant session was smooth; it should not claim controlled causal proof. Report synthetic score deltas with units and explain that benchmark percentage changes are not app speed changes. State that the 8+4 channel mode is inferred, not CPU-Z verified. Present battery reports as software health/function indications, not authenticity proof. For the SSD, the SMART text `0x22` is 34 decimal and is consistent with CrystalDiskInfo's “Good (66%)” display; describe `Percentage Used` as a vendor-specific endurance estimate and do not predict a two-year life. State explicitly that Windows Memory Diagnostic completion/result could not be verified.

## Licensing

No license is assigned by this proposal. Third-party binaries remain excluded; their redistribution terms are separate from the project materials.
