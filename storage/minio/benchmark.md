
# S3 benchmark

Here we use `minio/warp` to test speed of S3 access.

References:
- https://github.com/minio/warp

# Install

```bash

mkdir -p ~/git/
cd ~/git/
git clone https://github.com/minio/warp.git
cd warp
go build

```

# Run

You need to create a separate bucket for testing.
By default warp uses bucket named `warp-benchmark-bucket`.

```bash

endpoint=nas.example.com:9000
key=i6MgDqtH36gWsPVmpNHl
secret=CAefORhKqrq5IYPXZOuohdMoWvWttBFoxxziZ4Ez
bucket=warp-benchmark-bucket

~/git/warp/warp mixed --host $endpoint --access-key $key --secret-key $secret --bucket $bucket

```

# Example results

```bash
╭─────────────────────────────────╮
│ WARP S3 Benchmark Tool by MinIO │
╰─────────────────────────────────╯
                                                                       
Benchmarking: Press 'q' to abort benchmark and print partial results...
                                                                       
 λ █████████████████████████████████████████████████████████████████████████ 100%
                                                                                                        
Reqs: 71349, Errs:0, Objs:71349, Bytes: 418.02GiB                                                       
 -    DELETE Average: 24 Obj/s; Current 30 Obj/s, 7.7 ms/req                                            
 -       GET Average: 107 Obj/s, 1071.8MiB/s; Current 116 Obj/s, 1160.1MiB/s, 105.0 ms/req, TTFB: 10.9ms
 -       PUT Average: 36 Obj/s, 356.9MiB/s; Current 30 Obj/s, 295.9MiB/s, 228.9 ms/req                  
 -      STAT Average: 71 Obj/s; Current 81 Obj/s, 5.7 ms/req                                            
                                                                                                        
UI: program was killed: context canceled
Report: DELETE. Concurrency: 20. Ran: 4m57s
 * Average: 23.80 obj/s
 * Reqs: Avg: 7.5ms, 50%: 6.2ms, 90%: 12.3ms, 99%: 27.6ms, Fastest: 1.6ms, Slowest: 63.1ms, StdDev: 4.3ms

Throughput, split into 297 x 1s:
 * Fastest: 33.00 obj/s
 * 50% Median: 23.00 obj/s
 * Slowest: 15.39 obj/s

──────────────────────────────────

Report: GET. Concurrency: 20. Ran: 4m57s
 * Average: 1071.81 MiB/s, 107.18 obj/s
 * Reqs: Avg: 108.9ms, 50%: 107.9ms, 90%: 130.2ms, 99%: 152.7ms, Fastest: 15.2ms, Slowest: 212.9ms, StdDev: 16.6ms
 * TTFB: Avg: 11ms, Best: 1ms, 25th: 8ms, Median: 9ms, 75th: 13ms, 90th: 19ms, 99th: 34ms, Worst: 72ms StdDev: 6ms

Throughput, split into 297 x 1s:
 * Fastest: 1259.9MiB/s, 125.99 obj/s
 * 50% Median: 1072.1MiB/s, 107.21 obj/s
 * Slowest: 708.2MiB/s, 70.82 obj/s

──────────────────────────────────

Report: PUT. Concurrency: 20. Ran: 4m57s
 * Average: 356.93 MiB/s, 35.69 obj/s
 * Reqs: Avg: 216.8ms, 50%: 215.1ms, 90%: 260.1ms, 99%: 309.1ms, Fastest: 103.3ms, Slowest: 833.2ms, StdDev: 34.8ms

Throughput, split into 297 x 1s:
 * Fastest: 452.6MiB/s, 45.26 obj/s
 * 50% Median: 362.6MiB/s, 36.26 obj/s
 * Slowest: 261.8MiB/s, 26.18 obj/s

──────────────────────────────────

Report: STAT. Concurrency: 20. Ran: 4m57s
 * Average: 71.48 obj/s
 * Reqs: Avg: 5.8ms, 50%: 5.0ms, 90%: 8.9ms, 99%: 19.4ms, Fastest: 0.8ms, Slowest: 59.0ms, StdDev: 3.2ms

Throughput, split into 297 x 1s:
 * Fastest: 89.00 obj/s
 * 50% Median: 72.00 obj/s
 * Slowest: 50.00 obj/s


──────────────────────────────────

Report: Total. Concurrency: 20. Ran: 4m57s
 * Average: 1428.74 MiB/s, 238.15 obj/s

Throughput, split into 297 x 1s:
 * Fastest: 1563.2MiB/s, 272.19 obj/s
 * 50% Median: 1399.1MiB/s, 236.91 obj/s
 * Slowest: 994.3MiB/s, 168.43 obj/s


Cleanup
Cleanup Done
```
