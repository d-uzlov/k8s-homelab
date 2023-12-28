
# Tests

This folder contains raw data from various tests and instructions how to run them.

# Disk `fsync` test: Intro

- Program writes data to file
- Program issues `fsync` command to flush the data
- OS sends file data to disk
- OS issues `flush` command to disk
- disk writes data from cache to flash
- - this is very slow

# Disk `fsync` test: Results

```log
Main RAID array
iops: min= 4738, max= 4856, avg=4797.00

Main RAID array, without SLOG
Truenas Scale
iops: min=    2, max=  120, avg=95.44
Truenas Core
iops: min=   15, max=  120, avg=94.13

NVMe Intel Optane M10 16GB MEMPEK1J016GAL
Device
IOPS=18.6k
Optane is too fast to measure statistics with min/max/average with my test.
ZFS, Truenas Scale
iops: min= 5944, max= 5944, avg=5944.00
ZFS, Truenas Core
iops: min= 9317, max= 9317, avg=9317.00

NVME T-FORCE TM8FPL500G 500GB TPBF2210060060400308
iops: min=  112, max=  154, avg=144.15

NVME Samsung 970 EVO 1TB
iops: min=  950, max= 1019, avg=981.45

NVME ADATA LEGEND 960 2TB
iops: min=  339, max=  703, avg=412.96

XPG GAMMIX S70 BLADE 2TB
iops: min= 3660, max= 3674, avg=3668.67

SATA Plextor PX-0128M5S
iops: min=  414, max=  420, avg=417.15

Slow vdev + Optane Special
iops: min=   74, max=  154, avg=140.96

Slow vdev + Optane SLOG
IOPS=5812


SATA TESLA 2TB 2022092T0075
Truenas Scale
iops: min= 2588, max= 2916, avg=2792.67
Truenas Core
iops: min= 2304, max= 2410, avg=2368.50


SATA TEAM T253X2512G 500GB TPBF2206080010103840
iops: min= 1114, max= 1172, avg=1150.89

SATA Apacer AS340 480GB E09507281ACE00417122
iops: min= 1080, max= 1112, avg=1100.80

SATA TEAM T253480GB 480GB TPBF2209020010803378
iops: min= 1116, max= 1236, avg=1209.78
```

# Disk random write test: Results

```log
Main RAID array, without SLOG
Truenas Scale
iops: min= 1544, max= 4958, avg=2331.24
Truenas Core
iops: min=  148, max= 3830, avg=799.47

NVMe Intel Optane M10 16GB MEMPEK1J016GAL
Truenas Scale
iops: min=  292, max=25142, avg=18454.12
Truenas Core
iops: min=  229, max=71613, avg=28432.77
```

# Disk sequential write test: Results

```log
Main RAID array
Truenas Scale, SZTD-3, 6 cores
WRITE: bw=100MiB/s
Truenas Scale, SZTD-1, 6 cores
WRITE: bw=161MiB/s
Truenas Scale, SZTD-3, 10 cores
WRITE: bw=141MiB/s
Truenas Scale, ZSTD-1, 10 cores
WRITE: bw=234MiB/s
Truenas Core
WRITE: bw=508MiB/s

Main RAID array, without SLOG
Truenas Scale
WRITE: bw=111MiB/s
Truenas Core
WRITE: bw=557MiB/s

NVMe Intel Optane M10 16GB MEMPEK1J016GAL
Truenas Scale
WRITE: bw=151MiB/s
```

# How to read raw results

- `write: IOPS=value` is average iops
- `iops        :` is iops distribution
- `WRITE: bw=value` is average bandwidth
- `sync percentiles (usec):` is latency distribution
- - look at the `99.00th` percentile
- `slat` is submission latency that indicates how much time it took to submit I/O to the kernel.
- `clat` is completion latency that indicates how much time passed between submission to the kernel and completing the I/O (excluding submission latency).
- `lat` is the sum of `slat` and `clat`.

# Flush performance

Supposedly, these drives have very good flush performance:
- Crucial P5 Plus
- WD Red SN700

Reference:
- https://news.ycombinator.com/item?id=30436301

> Crucial P5 Plus 1TB CT1000P5PSSD8, FW P7CR402: Pass
> 
> Crucial P2 250GB CT250P2SSD8, FW P2CR046: Pass
> 
> Kingston SNVS/250G, 012.A005: Pass
> 
> Seagate Firecuda 530 PCIe Gen 4 1TB ZP1000GM30013, FW SU6SM001: Pass
> 
> Intel 670p 1TB, SSDPEKNU010TZ, FW 002C: Pass
> 
> Samsung 970 Evo Plus: MZ-V7S2T0, 2021.10: Pass
> 
> Samsung 980 250GB MZ-V8V250, 2021/11/07: Pass
> 
> WD Red: WDS100T1R0C-68BDK0, 04Sept2021: Pass
> 
> WD Black SN750 1TB WDS100T1B0E, 09Jan2022: Pass
> 
> WD Green SN350 240GB WDS240G20C, 02Aug2021: Pass
> 
> Flush performance varies by 6x and is not necessarily correlated with overall perf or price. If you are doing lots of database writes or other workloads where durability matters don't just look at the random/sustained read/write > performance!
> 
> High flush perf: Crucial P5 Plus (fastest) and WD Red
> 
> Despite being a relatively high end consumer drive the Seagate had really low flush performance. And despite being a budget drive the WD Green was really fast, almost as good as the WD Red in my test.
> 
> The SK Hynix drive had fast flush perf at times, then at other times it would slow down. But it sometimes lost flushed data so it doesn't matter much.
