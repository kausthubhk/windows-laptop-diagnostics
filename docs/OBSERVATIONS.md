# Dated observations and limits

These notes consolidate RAM, SSD, and battery evidence gathered in the same Windows workspace across September and October 2026. They distinguish instrumented results from user reports. They do not establish RAM or SSD remaining life, battery authenticity, or a guaranteed two-year service life.

## 10 September 2026 — 8 GiB, two 4 GiB modules

The user had two 4 GiB Samsung DDR4-3200 SO-DIMMs running at 2933 MT/s. This is the RAM performance baseline. Five elevated WinSAT runs averaged 25,308.08 MB/s (25,146.40–25,455.71). Five-run Intel MLC means were 26,644.78 MB/s maximum-bandwidth all-read, 22,627.70 MB/s peak-injection all-read, and 85.74 ns idle latency. The historical real-use capture recorded an average 1,216.96 MiB available and 331.95 pages output/s, but the session included different programs and system conditions; it is not an A/B against the later 8 GiB single-module capture.

The user reported that Chrome and the coding assistant had frozen with the 4+4 GiB setup. No freeze count, duration, stack trace, or instrumented reproduction is present in the available diagnostics. Treat this as historical user observation.

Evidence: [sanitized baseline files](../results/ram/sep-2026-09-10/).

## 19 September 2026 — SSD health snapshot

During a separate storage-health session, the SSD was identified as a KIOXIA BG4 256 GB NVMe drive. CrystalDiskInfo v9.9.2 displayed “Good (66%)” and 54 °C. The same report's NVMe SMART fields showed critical warning 0, available spare 100, `Percentage Used` raw value `0x22` (34 decimal), media/data integrity errors 0, and error-log entries 0. CrystalDiskInfo also reported 9,654 power-on hours, 8,160 power-on count, 143,391 GB host reads, and 61,827 GB host writes.

The raw text encodes `0x22` in hexadecimal, equal to 34 in decimal, which is consistent with CrystalDiskInfo's 66% health display. NVM Express defines `Percentage Used` as a vendor-specific estimate of endurance consumed; it may reach or exceed 100 without necessarily meaning the drive failed. This does not translate into a reliable remaining-years forecast. One read-only SMART snapshot does not prove future SSD reliability or that SSD paging caused any application freeze. CrystalDiskMark v9.0.3 was installed but intentionally not run because its benchmark writes test data.

Evidence summary is under [`results/ssd/`](../results/ssd/); the original DiskInfo file is outside this workspace and is not included. See the [NVM Express base specification](https://nvmexpress.org/wp-content/uploads/NVM-Express-Base-Specification-2.0c-2022.10.04-Ratified.pdf).

## 14 October 2026 — 8 GiB, one 8 GiB module

The 4+4 layout was replaced with one Samsung 8 GiB module, so total capacity remained 8 GiB. This was a temporary diagnostic/isolation configuration, not established as the user’s normal daily setup. CPU-Z 3.01 reported single-channel mode, one rank, DDR4-2933 active operation and an SPD manufacturing date of week 45 of 2021. The SPD date is not a usage-hours, usage-cycles, purchase-date, or newness field. The CPU-Z portable utility was checksum/signature verified and produced a report; a before/after check found no lingering CPU-Z driver/service/process/temp directory.

The five-run elevated WinSAT mean was 14,677.19 MB/s, 42.01% below the September 10 two-module baseline. MLC max-bandwidth all-read averaged 17,865.58 MB/s (32.95% below that baseline); peak-injection all-read averaged 16,359.72 MB/s (27.70% below); idle latency averaged 86.20 ns, near the old 85.74 ns mean. This was a synthetic performance difference, not evidence the module was defective or previously used.

A limited test ran eight pattern passes over a single 256 MiB managed allocation (2 GiB total written and verified) with zero mismatches. It was not a full physical-memory test. The user reported running Windows Memory Diagnostic after a reboot; logs show a scheduled test and reboot, but no diagnostic-result event was recovered. Its completion/pass/fail is unknown. The 1,200-sample normal-use captures spanned about 40 minutes per session, not a controlled A/B. The 8 GiB session had a mean 1,814.87 MiB available and 5.12 pages output/s; conditions differ across the month.

Evidence: [single-module captures](../results/ram/single-8gb-2026-10-14/).

## 15 October 2026 — 12 GiB, one 8 GiB + one 4 GiB module

The user returned a 4 GiB module, yielding 12 GiB configured at 2933 MT/s. The 8+4 flex-channel pattern (balanced/interleaved portion and unmatched capacity) is plausible from platform documentation, but this boot's channel mode was not directly verified. Against September 10, the five-run means were lower on all 11 bandwidth rows and higher for idle latency; examples include WinSAT 19,706.00 MB/s (-22.14%) and MLC all-read max bandwidth 24,021.64 MB/s (-9.84%), with idle latency 116.24 ns (+35.57%). The month-separated tests did not control background activity, temperature, power state, or timing/rank of the 4 GiB module; synthetic differences do not imply apps are slower by those percentages.

The user said Chrome and the coding assistant felt smoother and the laptop seemed less hot than with the previous 8 GiB layout. Heat was subjective; no temperature sensor or objective hang/stutter metric was captured. During a separate five-minute Netflix-in-Chrome + Codex session, the user reported both were smooth and there was no unusual heat. Telemetry sampled once per second for 300 seconds: available RAM averaged 1,582.92 MiB (range 1,345–1,715), all readings below 2 GiB but none below 1 GiB; committed memory averaged 12.585 GiB against a 23.597 GiB commit limit. Pages input averaged 222.04/s and peaked at 17,268.44/s; pages output averaged 1.00/s, with one sample above 100/s. Disk read/write latency averaged 0.50/0.70 ms and queue averaged 0.06 (peak 6). The largest page-input samples had 0.17–0.20 ms read latency and queue zero; the one page-output sample above 100/s also had queue zero. This shows paging activity and limited headroom, not sustained storage pressure or a proven cause of earlier freezes.

The laptop was on battery and Balanced power mode throughout the five-minute capture, with charge falling from 70% to 67%. The pre-session 30-second sample did not confirm Netflix playback, so the session is not a matched 8 GiB/12 GiB A/B. The subjective smoothness supports the user's experience but cannot establish RAM caused the difference or guarantee future performance.

A separate post-matrix 60-second desktop capture had mean 3,482.55 MiB available, 0 pages output/s and no disk queue; it followed synthetic tests and is separate from the Netflix session. A bounded Windows event query found no matching app hang/error or WHEA/diagnostic result records, which does not prove no hang or hardware health.

The current practical conclusion in the 15 October comparison is to keep 12 GiB. A second 8 GiB module would add 4 GiB net, bringing the laptop to Dell-listed 16 GiB 2×8 dual-channel DDR4-2933 support; that arrangement was not tested ([Dell G3 15 3500 memory specifications](https://www.dell.com/support/manuals/en-in/g-series-15-3500-laptop/dell-g3-15-3500-setup-and-specifications/memory?guid=guid-e9d2ea83-38a4-431d-803c-96d63c1dbc34&lang=en-us)). The session did not show an urgent purchase need, though more capacity could provide a buffer for heavier future workloads. See the sanitized [RAM comparison](../results/ram/benchmark-comparison-2026-10-15.md) and [workload files](../results/workload/netflix-codex-12gb-2026-10-15/).

## 15 October 2026 — replacement battery checks

The user had replaced the laptop battery and asked whether it was genuine/new and whether it would last. Windows-reported design and full-charge capacity were both 51,004 mWh, with a reported zero cycle count. My Dell displayed health “EXCELLENT” and “Dell Battery: Yes.” Dell SupportAssist battery and charger functional tests passed. These are favorable software/function checks; they do not authenticate physical provenance, prove a brand-new condition, measure true full-cycle capacity, or establish future life.

A mixed active/standby unplugged interval in the battery report lasted about 3 h 26 min and used around 29.94 Wh; that is historical use, not a controlled runtime test. A separate ordinary-activity sample measured about 15.2 W average discharge for six minutes, then a five-minute charging interval showed the gauge rise 2,109 mWh. These short observations do not establish runtime or capacity. Battery temperature was unavailable; no full discharge test or Dell preboot/ePSA test was run.

The official Dell Power Manager Service 3.18.0 installer was verified and launched, but setup stopped at its My Dell conflict check (MSI 1603). No service was installed, no application uninstalled, no BIOS/firmware/driver changed, and no power setting was changed. The My Dell update flow still reported version 2.2.6.0 afterward. `powercfg /energy` recorded disabled display/sleep timeouts and an active PowerToys Awake request; those are observed power-policy context, not changes attributed to the diagnostic session. Exact battery serial/PPID, service tag, UUID, device name, raw battery report, and detailed activity logs are excluded from the public summary.

See the sanitized [battery summary](../results/battery/2026-10-15-summary.md).

## Evidence scope

Session review was limited to uncompressed session-log files whose metadata names this exact workspace path, plus the local dated captures and reports. A narrow review covered relevant RAM/battery/SSD prompts and tool runs; raw conversation logs were not copied. The matching logs identified in the session store are one from 19 September, four from 14 October, and seven from 15 October 2026. The September 10 RAM baseline is reconstructed from retained workspace results. This does not prove that no other machine sessions, alternate workspace paths, or compressed archives exist. The public manifest maps exported results to local source-relative files; raw source captures remain private.
