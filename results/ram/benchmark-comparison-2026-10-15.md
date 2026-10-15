## Comparable synthetic benchmarks

Each value is mean (minimum–maximum), **n=5**. Bandwidth is MB/s and latency is ns. Change is `(later mean / earlier mean - 1) × 100`. Negative bandwidth change means lower throughput; positive latency change means slower access. These are descriptive comparisons, not controlled causal estimates.

| Test | Unit | Sep 10 · 2×4 GiB | Oct 14 · 1×8 GiB | Oct 15 · 8+4 GiB | Oct14 vs Sep10 | Oct15 vs Sep10 | Oct15 vs Oct14 |
|---|---|---:|---:|---:|---:|---:|---:|
| WinSAT memory bandwidth | MB/s | 25308.08 (25146.40–25455.71); n=5 | 14677.19 (13091.83–15305.67); n=5 | 19706.00 (17946.88–20907.82); n=5 | -42.01% | -22.14% | +34.26% |
| MLC maximum bandwidth, all reads | MB/s | 26644.78 (24649.90–27970.90); n=5 | 17865.58 (17344.50–18211.50); n=5 | 24021.64 (22923.80–25382.30); n=5 | -32.95% | -9.84% | +34.46% |
| MLC peak injection bandwidth, all reads | MB/s | 22627.70 (22159.90–23237.50); n=5 | 16359.72 (15833.60–16661.80); n=5 | 20971.36 (20704.20–21251.10); n=5 | -27.70% | -7.32% | +28.19% |
| MLC idle latency | ns | 85.74 (75.10–92.20); n=5 | 86.20 (84.80–89.80); n=5 | 116.24 (104.10–136.20); n=5 | +0.54% | +35.57% | +34.85% |
| MLC maximum bandwidth, 3:1 Reads-Writes | MB/s | 21756.36 (21457.60–22018.90); n=5 | 15861.00 (14612.00–19101.20); n=5 | 19535.52 (17566.50–20660.10); n=5 | -27.10% | -10.21% | +23.17% |
| MLC maximum bandwidth, 2:1 Reads-Writes | MB/s | 20562.28 (19856.00–21341.90); n=5 | 14344.16 (13980.60–14496.90); n=5 | 19194.20 (17604.50–20135.20); n=5 | -30.24% | -6.65% | +33.81% |
| MLC maximum bandwidth, 1:1 Reads-Writes | MB/s | 19226.54 (18503.00–19677.10); n=5 | 13294.04 (12978.50–13676.20); n=5 | 18014.90 (16290.50–18810.90); n=5 | -30.86% | -6.30% | +35.51% |
| MLC maximum bandwidth, Stream-triad like | MB/s | 21996.96 (18937.00–23455.10); n=5 | 14472.90 (14157.80–14774.90); n=5 | 21255.08 (19422.20–22391.60); n=5 | -34.20% | -3.37% | +46.86% |
| MLC peak injection bandwidth, 3:1 Reads-Writes | MB/s | 19498.52 (19252.50–19880.70); n=5 | 15817.48 (13568.50–24053.10); n=5 | 17193.22 (16671.20–17450.40); n=5 | -18.88% | -11.82% | +8.70% |
| MLC peak injection bandwidth, 2:1 Reads-Writes | MB/s | 20682.78 (19838.60–21005.70); n=5 | 13706.14 (13366.20–13995.20); n=5 | 17283.88 (16923.30–17658.30); n=5 | -33.73% | -16.43% | +26.10% |
| MLC peak injection bandwidth, 1:1 Reads-Writes | MB/s | 20236.32 (19386.50–20622.20); n=5 | 12866.94 (12721.20–12952.00); n=5 | 16061.26 (15472.40–16590.70); n=5 | -36.42% | -20.63% | +24.83% |
| MLC peak injection bandwidth, Stream-triad like | MB/s | 19846.28 (19403.90–20105.50); n=5 | 13192.58 (12081.80–13837.50); n=5 | 17646.80 (17056.80–18175.00); n=5 | -33.53% | -11.08% | +33.76% |


### What the 12 benchmark rows mean

“Bandwidth” is how fast the test moved memory data; higher is better. “Latency” is how long a memory request took; lower is better. These are synthetic scores, not application launch times.

| Metric | In everyday terms | 8+4 GiB vs 4+4 GiB |
|---|---|---:|
| WinSAT memory bandwidth | Windows’ built-in memory-copy speed test. | -22.14% |
| MLC maximum bandwidth, all reads | Fastest read-only memory throughput found while MLC automatically varies its generated load. | -9.84% |
| MLC peak-injection bandwidth, all reads | Read-only throughput when the processor issues requests as fast as it can. | -7.32% |
| MLC idle latency | Time for a memory access with no added MLC traffic; the result uses random accesses. | +35.57% slower |
| MLC maximum bandwidth, 3:1 reads/writes | Maximum test throughput with about three reads for each write. | -10.21% |
| MLC maximum bandwidth, 2:1 reads/writes | Maximum test throughput with about two reads for each write. | -6.65% |
| MLC maximum bandwidth, 1:1 reads/writes | Maximum test throughput with reads and writes balanced. | -6.30% |
| MLC maximum bandwidth, Stream-triad-like | Maximum throughput in a read/write pattern modeled on a small numerical calculation that reads two arrays and writes one result array. | -3.37% |
| MLC peak-injection bandwidth, 3:1 reads/writes | Throughput for the three-read, one-write mix when the processor issues requests at its fastest rate. | -11.82% |
| MLC peak-injection bandwidth, 2:1 reads/writes | Throughput for the two-read, one-write mix at fastest request rate. | -16.43% |
| MLC peak-injection bandwidth, 1:1 reads/writes | Throughput for balanced reads and writes at fastest request rate. | -20.63% |
| MLC peak-injection bandwidth, Stream-triad-like | Throughput for the two-array-read/one-result-write pattern at fastest request rate. | -11.08% |

The 8+4 GiB mean is lower on all 11 bandwidth rows and its idle latency is higher. Eight of the 12 pairs of five-run ranges do not overlap; four do overlap. That is evidence that the benchmark outputs differ beyond the run-to-run spread seen in many rows. It is not a significance test and does not isolate the RAM arrangement as the cause. WinSAT’s **22.14% lower memory-copy score does not mean Windows, Chrome, or Codex is 22.14% slower**. Intel documents the distinction between the MLC maximum-bandwidth scan, peak-injection workload, idle latency, and read/write traffic mixes in its ; the Stream Triad label refers to a synthetic numerical array operation, not an app workload ().

### Why the benchmark scores could be lower

The raw runs verify that the same WinSAT flags, Intel MLC v3.13 modes, five repetitions, and administrator elevation were used for Sep 10 and Oct 15. That makes the synthetic tests comparable in method. It does not make the system state identical across dates. Likely explanations, from most directly tied to the configuration change to less directly supported possibilities, are:

1. **Different channel layout:** Sep 10 had two 4 GiB modules; Oct 15 had 8 GiB + 4 GiB. Flex Memory behavior makes an interleaved 8 GiB balanced region plus a single-channel 4 GiB region plausible. But there is no Oct 15 channel-mode or address-range measurement, so this does not prove which region each benchmark accessed or explain a 22% score change.
2. **Different conditions during each session:** the runs were a month apart, with no matched temperature, processor frequency, background load, or test-order controls. Those factors can change memory-latency and bandwidth results.
3. **Different module timings or organization:** configured speed is 2933 MT/s in both inventories, but Oct 15 has no CPU-Z/SPD capture of channel mode, rank, or active timings. Those properties could contribute; the files do not establish that they did.

There is no direct evidence here that the 4 GiB module is defective or used. The 8 GiB part number matches a stick whose earlier SPD report showed one rank; Oct 15 did not capture the 4 GiB module’s SPD, rank, or active timings, so no rank-mismatch or timing explanation is proven. A prior user-mode pattern screen tested one 256 MiB allocation through eight patterns (2 GiB written/verified) with no mismatches; it did not cover all installed physical RAM. All 25 benchmark commands exiting successfully means the benchmark programs completed, not that memory passed an integrity test. The Windows Memory Diagnostic result remains unverified.

### Loaded latency curve

Each of MLC’s 19 shared read-only injection settings is summarized across five runs per configuration. MLC does not state a unit for the injection setting. Achieved bandwidth differs by configuration at the same setting, so read the curve as a synthetic stress-response comparison, not identical application traffic. Higher latency is slower.

| MLC injection setting (unit not reported) | Sep10 latency, ns | Oct14 latency, ns | Oct15 latency, ns | Oct15 vs Sep10 | Oct15 vs Oct14 |
|---:|---:|---:|---:|---:|---:|
| 0 | 173.28 (150.51–196.37); n=5 | 311.97 (274.55–343.44); n=5 | 220.20 (200.89–256.77); n=5 | +27.08% | -29.42% |
| 2 | 163.87 (157.28–176.26); n=5 | 301.28 (252.93–360.48); n=5 | 220.66 (198.48–270.87); n=5 | +34.66% | -26.76% |
| 8 | 139.32 (136.39–146.22); n=5 | 306.03 (248.76–403.07); n=5 | 174.15 (161.46–193.36); n=5 | +25.00% | -43.09% |
| 15 | 130.14 (128.42–131.85); n=5 | 246.87 (235.89–262.57); n=5 | 181.21 (154.78–224.55); n=5 | +39.24% | -26.60% |
| 50 | 113.61 (111.01–120.90); n=5 | 245.83 (205.79–318.08); n=5 | 152.29 (140.39–179.67); n=5 | +34.05% | -38.05% |
| 100 | 91.09 (89.82–94.09); n=5 | 169.05 (154.23–194.51); n=5 | 111.67 (101.65–134.98); n=5 | +22.59% | -33.94% |
| 200 | 80.88 (79.83–82.88); n=5 | 107.31 (103.71–110.14); n=5 | 100.41 (90.83–117.54); n=5 | +24.15% | -6.43% |
| 300 | 77.65 (77.11–78.57); n=5 | 97.54 (89.93–105.60); n=5 | 89.70 (84.62–101.29); n=5 | +15.52% | -8.04% |
| 400 | 75.85 (75.17–76.40); n=5 | 89.34 (85.67–91.66); n=5 | 89.80 (81.41–107.69); n=5 | +18.39% | +0.51% |
| 500 | 74.87 (74.17–75.62); n=5 | 90.13 (82.99–99.32); n=5 | 86.87 (80.39–106.31); n=5 | +16.03% | -3.62% |
| 700 | 73.89 (73.25–75.38); n=5 | 88.54 (80.67–101.89); n=5 | 87.13 (79.86–106.51); n=5 | +17.92% | -1.59% |
| 1000 | 73.46 (72.89–74.26); n=5 | 95.29 (82.93–110.87); n=5 | 93.72 (77.56–122.00); n=5 | +27.58% | -1.65% |
| 1300 | 73.61 (72.23–77.36); n=5 | 89.83 (79.27–103.30); n=5 | 96.83 (77.76–116.58); n=5 | +31.54% | +7.79% |
| 1700 | 75.35 (72.01–87.91); n=5 | 81.87 (76.49–84.08); n=5 | 90.16 (78.28–116.64); n=5 | +19.65% | +10.13% |
| 2500 | 72.07 (71.65–72.62); n=5 | 86.63 (77.25–115.93); n=5 | 85.26 (76.96–107.01); n=5 | +18.30% | -1.58% |
| 3500 | 73.78 (72.78–74.59); n=5 | 88.61 (79.30–105.47); n=5 | 88.84 (77.25–123.81); n=5 | +20.41% | +0.26% |
| 5000 | 73.12 (71.37–76.75); n=5 | 82.34 (76.63–93.72); n=5 | 84.28 (78.28–95.75); n=5 | +15.26% | +2.36% |
| 9000 | 71.83 (70.75–72.91); n=5 | 79.25 (76.39–81.60); n=5 | 80.45 (76.48–82.99); n=5 | +12.00% | +1.51% |
| 20000 | 74.31 (71.71–83.66); n=5 | 84.76 (76.01–91.00); n=5 | 81.89 (76.97–85.54); n=5 | +10.20% | -3.39% |

Against the Sep 10 2×4 GiB baseline, **Oct 15 mean latency is higher at all 19 injection settings**; only two pairs of five-run min–max ranges overlap. That supports a repeatable difference in this synthetic test, though the one-month gap and uncontrolled system state prevent attributing the difference specifically to the DIMM layout. Compared with Oct 14, Oct 15 is lower at many settings but remains higher at several. Examples: setting 100: 111.67 ns, 19591.58 MB/s; setting 5000: 84.28 ns, 1308.86 MB/s; setting 20000: 81.89 ns, 921.32 MB/s. Use the separate achieved-bandwidth arrays in `comparison.json` when interpreting the curve, because equal injection settings did not produce equal bandwidth.

