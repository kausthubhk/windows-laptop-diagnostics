# Evidence privacy notes

The workspace evidence is mixed with local machine identity, private activity records, and third-party tools. Only the explicit export allowlist in `scripts/prepare-public-results.py` is a candidate for public use. The source folders remain local evidence and should not be uploaded as a whole.

## Redactions and retained detail

The exporter preserves the Dell G3 3500 and Intel Core i5-10300H model names, RAM capacities and module part models, configured/reported memory rates, benchmark flags and measurements, units, counter names and sample structure, dates, and status/limitations. Counter paths replace the local host label with `HOST`. Local absolute paths, profile names, device identifiers, report identifiers, and identity values are omitted or replaced. Process inventory exports are reduced to aggregate Chrome, ChatGPT, and Codex group totals without PIDs, window titles, or process-level records. Battery evidence includes a short factual summary and the bounded 10-minute check's timestamp/numeric/status telemetry; detailed reports and dense usage history are excluded. SSD evidence is restricted to selected SMART fields; no serial or raw report is included. CrystalDiskInfo's 66% health display and raw SMART Percentage Used `0x22` (34 decimal) are preserved as separate reported fields.

Third-party CPU-Z and Intel MLC binaries, archives, drivers, installer payloads, and vendor configuration files are not included. The CPU-Z SPD data is summarized only where needed; the local full report is not a public artifact. Raw battery reports and dense battery-usage records stay private.

## Readiness scan

The exporter scans its generated evidence files for absolute Windows paths, unsanitized memory counter host names, MAC and IPv4 literals, UUID-shaped values, and common private-identity labels. At the time of preparation, all 101 generated text files passed these configured checks with zero matches. The machine-readable scan result and per-output hashes are in `results/manifest.json`; the scan does not display matched values. Generic-export smoke fixtures were moved to ignored `local-results/` after schema checks and are not part of the public candidate set.

This scan catches specified patterns only. It is not a guarantee that every possible identifier or sensitive detail has been removed. Review narrative text and new source files before expanding the allowlist. Do not publish raw source directories, local handoff archives, or unreviewed future captures.

## Evidence limits

The benchmark measurements describe synthetic performance under sessions held on different dates and do not establish a causal hardware diagnosis. The 256 MiB user-mode memory screen passed its recorded patterns but did not cover all physical RAM. No Windows Memory Diagnostic result was available. Zero matching event-log records are limited to the queried channels/providers and time ranges, and do not prove the hardware error-free. Battery capacity, cycle count, and health are software-reported; the captured evidence does not authenticate physical provenance or measure complete-cycle capacity. SSD SMART counters are a snapshot and do not certify future reliability.
