
# Tests

This folder contains raw data from various tests and instructions how to run them.

# Disk `fsync` test: Intro

- Program writes data to file
- Program issues `fsync` command to flush the data
- OS sends file data to disk
- OS issues `flush` command to disk
- disk writes data from cache to flash
- - this is very slow

Some disks lie about writing data to buffer.

# Disk `fsync` test: Results

```log
Main RAID array
iops: min= 4738, max= 4856, avg=4797.00

NVMe Intel Optane M10 16GB MEMPEK1J016GAL
IOPS=18.6k
Optane is too fast to measure statistics with min/max/average with my test.

NVMe Intel Optane M10 16GB MEMPEK1J016GAL
ZFS
IOPS=5860
ZFS seems to severely limit the performance.

NVME T-FORCE TM8FPL500G 500GB TPBF2210060060400308
iops: min=  112, max=  154, avg=144.15

NVME Samsung 970 EVO 1TB
iops: min=  950, max= 1019, avg=981.45

SATA Plextor PX-0128M5S
iops: min=  414, max=  420, avg=417.15

Slow vdev + Optane Special
iops: min=   74, max=  154, avg=140.96

Slow vdev + Optane SLOG
IOPS=5812
```

Likely lying:
```log
SATA TESLA 2TB 2022092T0075
iops: min= 2588, max= 2916, avg=2792.67
```

Maybe lying:
```log
SATA TEAM T253X2512G 500GB TPBF2206080010103840
iops: min= 1114, max= 1172, avg=1150.89

SATA Apacer AS340 480GB E09507281ACE00417122
iops: min= 1080, max= 1112, avg=1100.80

SATA TEAM T253480GB 480GB TPBF2209020010803378
iops: min= 1116, max= 1236, avg=1209.78
```
