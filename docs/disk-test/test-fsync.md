
# Run test

References:
- https://www.ibm.com/cloud/blog/using-fio-to-tell-whether-your-storage-is-fast-enough-for-etcd
- https://prog.world/is-storage-speed-suitable-for-etcd-ask-fio/

```bash
# test on a filesystem
fio --rw=write --ioengine=sync --fdatasync=1 --size=50m --bs=4k --runtime=10 --time_based=1 --name=mytest --filename=test-data
# test raw device
sudo fio --rw=write --ioengine=sync --fdatasync=1 --size=50m --bs=4k --runtime=10 --time_based=1 --name=mytest --filename=/dev/nvme0n1
```

# Main RAID array

ZFS, 6x HDD RAID Z2 vdev, 3x SATA SSD mirror special, 1x NVMe Optane SLOG

```log
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
Jobs: 1 (f=1)
mytest: (groupid=0, jobs=1): err= 0: pid=379504: Mon Jul  3 22:30:33 2023
  write: IOPS=4801, BW=18.8MiB/s (19.7MB/s)(22.0MiB/1173msec); 0 zone resets
    clat (nsec): min=10519, max=57976, avg=13462.14, stdev=2609.65
     lat (nsec): min=10769, max=58476, avg=13731.86, stdev=2657.41
    clat percentiles (nsec):
     |  1.00th=[11584],  5.00th=[11712], 10.00th=[11840], 20.00th=[12096],
     | 30.00th=[12352], 40.00th=[12480], 50.00th=[12608], 60.00th=[12992],
     | 70.00th=[13632], 80.00th=[13888], 90.00th=[15424], 95.00th=[18560],
     | 99.00th=[23168], 99.50th=[27264], 99.90th=[38656], 99.95th=[43264],
     | 99.99th=[58112]
   bw (  KiB/s): min=18952, max=19424, per=99.91%, avg=19188.00, stdev=333.75, samples=2
   iops        : min= 4738, max= 4856, avg=4797.00, stdev=83.44, samples=2
  lat (usec)   : 20=96.89%, 50=3.09%, 100=0.02%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=161, max=345, avg=192.48, stdev=20.09
    sync percentiles (usec):
     |  1.00th=[  167],  5.00th=[  172], 10.00th=[  174], 20.00th=[  178],
     | 30.00th=[  182], 40.00th=[  184], 50.00th=[  186], 60.00th=[  192],
     | 70.00th=[  196], 80.00th=[  206], 90.00th=[  221], 95.00th=[  235],
     | 99.00th=[  260], 99.50th=[  273], 99.90th=[  302], 99.95th=[  310],
     | 99.99th=[  347]
  cpu          : usr=2.99%, sys=21.84%, ctx=11253, majf=0, minf=11
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=18.8MiB/s (19.7MB/s), 18.8MiB/s-18.8MiB/s (19.7MB/s-19.7MB/s), io=22.0MiB (23.1MB), run=1173-1173msec
```

Truenas Core:

```log
root@truenas[/mnt/main/data/torrent-data/test]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=test-data
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.28
Starting 1 process
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1)
mytest: (groupid=0, jobs=1): err= 0: pid=6263: Tue Jul  4 14:45:36 2023
  write: IOPS=6055, BW=23.7MiB/s (24.8MB/s)(22.0MiB/930msec); 0 zone resets
    clat (usec): min=4, max=180, avg=10.07, stdev=12.20
     lat (usec): min=4, max=180, avg=10.29, stdev=12.21
    clat percentiles (usec):
     |  1.00th=[    6],  5.00th=[    6], 10.00th=[    6], 20.00th=[    7],
     | 30.00th=[    8], 40.00th=[    8], 50.00th=[    8], 60.00th=[    8],
     | 70.00th=[    9], 80.00th=[    9], 90.00th=[   11], 95.00th=[   18],
     | 99.00th=[   78], 99.50th=[   90], 99.90th=[  121], 99.95th=[  133],
     | 99.99th=[  182]
   bw (  KiB/s): min=23603, max=23603, per=97.44%, avg=23603.00, stdev= 0.00, samples=1
   iops        : min= 5900, max= 5900, avg=5900.00, stdev= 0.00, samples=1
  lat (usec)   : 10=88.58%, 20=7.05%, 50=1.78%, 100=2.15%, 250=0.44%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=107, max=462, avg=153.11, stdev=22.20
    sync percentiles (usec):
     |  1.00th=[  110],  5.00th=[  111], 10.00th=[  126], 20.00th=[  130],
     | 30.00th=[  147], 40.00th=[  149], 50.00th=[  151], 60.00th=[  157],
     | 70.00th=[  167], 80.00th=[  174], 90.00th=[  180], 95.00th=[  186],
     | 99.00th=[  202], 99.50th=[  210], 99.90th=[  227], 99.95th=[  231],
     | 99.99th=[  461]
  cpu          : usr=3.33%, sys=16.02%, ctx=10857, majf=0, minf=0
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=23.7MiB/s (24.8MB/s), 23.7MiB/s-23.7MiB/s (24.8MB/s-24.8MB/s), io=22.0MiB (23.1MB), run=930-930msec
```

# Main RAID array without SLOG

```log
root@truenas[/mnt/main/data/torrent-data]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=test-data
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1): [W(1)][100.0%][w=436KiB/s][w=109 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=2083842: Tue Jul  4 17:04:59 2023
  write: IOPS=95, BW=382KiB/s (391kB/s)(22.0MiB/59030msec); 0 zone resets
    clat (usec): min=14, max=480, avg=28.03, stdev=14.64
     lat (usec): min=15, max=481, avg=28.55, stdev=14.74
    clat percentiles (usec):
     |  1.00th=[   17],  5.00th=[   18], 10.00th=[   19], 20.00th=[   21],
     | 30.00th=[   22], 40.00th=[   23], 50.00th=[   24], 60.00th=[   28],
     | 70.00th=[   32], 80.00th=[   36], 90.00th=[   40], 95.00th=[   43],
     | 99.00th=[   56], 99.50th=[  145], 99.90th=[  184], 99.95th=[  217],
     | 99.99th=[  482]
   bw (  KiB/s): min=    8, max=  480, per=99.83%, avg=381.76, stdev=113.66, samples=118
   iops        : min=    2, max=  120, avg=95.44, stdev=28.41, samples=118
  lat (usec)   : 20=14.28%, 50=84.13%, 100=0.99%, 250=0.59%, 500=0.02%
  fsync/fdatasync/sync_file_range:
    sync (msec): min=6, max=821, avg=10.45, stdev=18.42
    sync percentiles (msec):
     |  1.00th=[    9],  5.00th=[    9], 10.00th=[    9], 20.00th=[    9],
     | 30.00th=[    9], 40.00th=[    9], 50.00th=[    9], 60.00th=[    9],
     | 70.00th=[    9], 80.00th=[    9], 90.00th=[    9], 95.00th=[   13],
     | 99.00th=[   62], 99.50th=[   70], 99.90th=[  209], 99.95th=[  472],
     | 99.99th=[  818]
  cpu          : usr=0.10%, sys=0.82%, ctx=11272, majf=0, minf=11
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=382KiB/s (391kB/s), 382KiB/s-382KiB/s (391kB/s-391kB/s), io=22.0MiB (23.1MB), run=59030-59030msec
```

ZFS, Truenas Core:

```log
root@truenas[/mnt/main/data/torrent-data/test]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=test-data
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.28
Starting 1 process
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1): [W(1)][100.0%][w=339KiB/s][w=84 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=1965: Tue Jul  4 09:22:17 2023
  write: IOPS=94, BW=377KiB/s (386kB/s)(22.0MiB/59724msec); 0 zone resets
    clat (usec): min=11, max=185, avg=21.66, stdev=16.15
     lat (usec): min=12, max=186, avg=22.06, stdev=16.20
    clat percentiles (usec):
     |  1.00th=[   13],  5.00th=[   13], 10.00th=[   14], 20.00th=[   16],
     | 30.00th=[   16], 40.00th=[   16], 50.00th=[   17], 60.00th=[   17],
     | 70.00th=[   19], 80.00th=[   25], 90.00th=[   34], 95.00th=[   40],
     | 99.00th=[  110], 99.50th=[  124], 99.90th=[  153], 99.95th=[  176],
     | 99.99th=[  186]
   bw (  KiB/s): min=   63, max=  483, per=100.00%, avg=378.12, stdev=72.44, samples=116
   iops        : min=   15, max=  120, avg=94.13, stdev=18.12, samples=116
  lat (usec)   : 20=73.21%, 50=22.96%, 100=2.52%, 250=1.31%
  fsync/fdatasync/sync_file_range:
    sync (msec): min=5, max=136, avg=10.58, stdev= 9.01
    sync percentiles (msec):
     |  1.00th=[    8],  5.00th=[    9], 10.00th=[    9], 20.00th=[    9],
     | 30.00th=[    9], 40.00th=[    9], 50.00th=[    9], 60.00th=[    9],
     | 70.00th=[    9], 80.00th=[    9], 90.00th=[   11], 95.00th=[   31],
     | 99.00th=[   59], 99.50th=[   65], 99.90th=[   91], 99.95th=[  111],
     | 99.99th=[  138]
  cpu          : usr=0.13%, sys=0.45%, ctx=11262, majf=0, minf=0
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=377KiB/s (386kB/s), 377KiB/s-377KiB/s (386kB/s-386kB/s), io=22.0MiB (23.1MB), run=59724-59724msec
```

# NVMe Intel Optane M10 16GB MEMPEK1J016GAL

ZFS, block 4k:

```log
root@truenas[/mnt/test-optane]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=test-data
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
 Jobs: 1 (f=1)
mytest: (groupid=0, jobs=1): err= 0: pid=1829456: Tue Jul  4 03:51:41 2023
  write: IOPS=5860, BW=22.9MiB/s (24.0MB/s)(22.0MiB/961msec); 0 zone resets
    clat (nsec): min=10800, max=64846, avg=13360.01, stdev=2629.41
     lat (nsec): min=10980, max=65416, avg=13593.85, stdev=2678.85
    clat percentiles (nsec):
     |  1.00th=[11200],  5.00th=[11456], 10.00th=[11584], 20.00th=[11840],
     | 30.00th=[12096], 40.00th=[12224], 50.00th=[12480], 60.00th=[12992],
     | 70.00th=[13376], 80.00th=[13760], 90.00th=[16768], 95.00th=[18816],
     | 99.00th=[23168], 99.50th=[26240], 99.90th=[34048], 99.95th=[42752],
     | 99.99th=[64768]
   bw (  KiB/s): min=23776, max=23776, per=100.00%, avg=23776.00, stdev= 0.00, samples=1
   iops        : min= 5944, max= 5944, avg=5944.00, stdev= 0.00, samples=1
  lat (usec)   : 20=97.19%, 50=2.79%, 100=0.02%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=127, max=343, avg=154.88, stdev=14.67
    sync percentiles (usec):
     |  1.00th=[  135],  5.00th=[  139], 10.00th=[  141], 20.00th=[  145],
     | 30.00th=[  147], 40.00th=[  149], 50.00th=[  153], 60.00th=[  155],
     | 70.00th=[  159], 80.00th=[  165], 90.00th=[  174], 95.00th=[  184],
     | 99.00th=[  206], 99.50th=[  215], 99.90th=[  239], 99.95th=[  255],
     | 99.99th=[  343]
  cpu          : usr=2.19%, sys=29.38%, ctx=9374, majf=0, minf=10
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=22.9MiB/s (24.0MB/s), 22.9MiB/s-22.9MiB/s (24.0MB/s-24.0MB/s), io=22.0MiB (23.1MB), run=961-961msec
```

ZFS, Truenas Core:

```log
root@truenas[/mnt/test-optane/1]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=test-data
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.28
Starting 1 process

mytest: (groupid=0, jobs=1): err= 0: pid=1966: Tue Jul  4 08:33:29 2023
  write: IOPS=9324, BW=36.4MiB/s (38.2MB/s)(22.0MiB/604msec); 0 zone resets
    clat (nsec): min=5361, max=41321, avg=8061.94, stdev=1802.17
     lat (nsec): min=5611, max=41921, avg=8366.42, stdev=1858.53
    clat percentiles (nsec):
     |  1.00th=[ 5856],  5.00th=[ 6304], 10.00th=[ 6496], 20.00th=[ 6752],
     | 30.00th=[ 7136], 40.00th=[ 7328], 50.00th=[ 7584], 60.00th=[ 7968],
     | 70.00th=[ 8640], 80.00th=[ 9024], 90.00th=[ 9536], 95.00th=[11328],
     | 99.00th=[14912], 99.50th=[16192], 99.90th=[22400], 99.95th=[27264],
     | 99.99th=[41216]
   bw (  KiB/s): min=37269, max=37269, per=99.92%, avg=37269.00, stdev= 0.00, samples=1
   iops        : min= 9317, max= 9317, avg=9317.00, stdev= 0.00, samples=1
  lat (usec)   : 10=91.99%, 20=7.88%, 50=0.12%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=73, max=249, avg=96.53, stdev= 8.90
    sync percentiles (usec):
     |  1.00th=[   88],  5.00th=[   90], 10.00th=[   92], 20.00th=[   92],
     | 30.00th=[   93], 40.00th=[   93], 50.00th=[   94], 60.00th=[   95],
     | 70.00th=[   97], 80.00th=[  101], 90.00th=[  105], 95.00th=[  110],
     | 99.00th=[  139], 99.50th=[  149], 99.90th=[  174], 99.95th=[  184],
     | 99.99th=[  249]
  cpu          : usr=2.32%, sys=20.73%, ctx=5640, majf=0, minf=0
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=36.4MiB/s (38.2MB/s), 36.4MiB/s-36.4MiB/s (38.2MB/s-38.2MB/s), io=22.0MiB (23.1MB), run=604-604msec
```

Raw device, block 4k:

```log
root@truenas[/home/admin]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=/dev/nvme1n1
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process

mytest: (groupid=0, jobs=1): err= 0: pid=1683564: Tue Jul  4 02:56:33 2023
  write: IOPS=18.6k, BW=72.8MiB/s (76.4MB/s)(22.0MiB/302msec); 0 zone resets
    clat (usec): min=2, max=139, avg= 4.34, stdev= 3.43
     lat (usec): min=3, max=139, avg= 4.53, stdev= 3.44
    clat percentiles (usec):
     |  1.00th=[    4],  5.00th=[    4], 10.00th=[    4], 20.00th=[    4],
     | 30.00th=[    4], 40.00th=[    4], 50.00th=[    4], 60.00th=[    4],
     | 70.00th=[    4], 80.00th=[    5], 90.00th=[    6], 95.00th=[    7],
     | 99.00th=[   12], 99.50th=[   18], 99.90th=[   49], 99.95th=[   69],
     | 99.99th=[  139]
  lat (usec)   : 4=70.95%, 10=27.36%, 20=1.23%, 50=0.39%, 100=0.04%
  lat (usec)   : 250=0.04%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=41, max=109, avg=47.60, stdev= 4.93
    sync percentiles (usec):
     |  1.00th=[   43],  5.00th=[   43], 10.00th=[   44], 20.00th=[   45],
     | 30.00th=[   46], 40.00th=[   47], 50.00th=[   47], 60.00th=[   48],
     | 70.00th=[   48], 80.00th=[   49], 90.00th=[   52], 95.00th=[   57],
     | 99.00th=[   68], 99.50th=[   75], 99.90th=[   94], 99.95th=[  101],
     | 99.99th=[  110]
  cpu          : usr=15.95%, sys=12.62%, ctx=5631, majf=0, minf=14
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=72.8MiB/s (76.4MB/s), 72.8MiB/s-72.8MiB/s (76.4MB/s-76.4MB/s), io=22.0MiB (23.1MB), run=302-302msec

Disk stats (read/write):
  nvme1n1: ios=0/2568, merge=0/0, ticks=0/103, in_queue=103, util=57.63%
```

# NVME T-FORCE TM8FPL500G 500GB TPBF2210060060400308

Raw device, block 4k:

```log
root@truenas[/home/admin]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=/dev/nvme0n1
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
Jobs: 1 (f=1): [W(1)][100.0%][w=588KiB/s][w=147 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=669986: Wed Jun 28 00:10:39 2023
  write: IOPS=144, BW=576KiB/s (590kB/s)(22.0MiB/39092msec); 0 zone resets
    clat (usec): min=5, max=300, avg=11.74, stdev= 9.12
     lat (usec): min=6, max=301, avg=12.27, stdev= 9.22
    clat percentiles (usec):
     |  1.00th=[    7],  5.00th=[    8], 10.00th=[    8], 20.00th=[    9],
     | 30.00th=[    9], 40.00th=[    9], 50.00th=[   10], 60.00th=[   11],
     | 70.00th=[   13], 80.00th=[   16], 90.00th=[   19], 95.00th=[   21],
     | 99.00th=[   25], 99.50th=[   32], 99.90th=[  169], 99.95th=[  180],
     | 99.99th=[  302]
   bw (  KiB/s): min=  448, max=  616, per=99.95%, avg=576.62, stdev=28.91, samples=78
   iops        : min=  112, max=  154, avg=144.15, stdev= 7.23, samples=78
  lat (usec)   : 10=58.31%, 20=36.67%, 50=4.69%, 100=0.11%, 250=0.21%
  lat (usec)   : 500=0.02%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=5415, max=23256, avg=6926.11, stdev=970.04
    sync percentiles (usec):
     |  1.00th=[ 5800],  5.00th=[ 6063], 10.00th=[ 6194], 20.00th=[ 6390],
     | 30.00th=[ 6521], 40.00th=[ 6652], 50.00th=[ 6783], 60.00th=[ 6915],
     | 70.00th=[ 7046], 80.00th=[ 7242], 90.00th=[ 7504], 95.00th=[ 7832],
     | 99.00th=[11731], 99.50th=[12387], 99.90th=[16188], 99.95th=[16909],
     | 99.99th=[23200]
  cpu          : usr=0.16%, sys=0.58%, ctx=16812, majf=0, minf=15
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%        
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%       
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%       
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=576KiB/s (590kB/s), 576KiB/s-576KiB/s (590kB/s-590kB/s), io=22.0MiB (23.1MB), run=39092-39092msec

Disk stats (read/write):
  nvme0n1: ios=51/11205, merge=0/0, ticks=69/38658, in_queue=77209, util=99.97%
```

# SATA TESLA 2TB 2022092T0075

ZFS, block 2300:

```log
root@truenas[/mnt/test-2]# fio --rw=write --ioengine=sync --fdatasync=1 --directory=test-data --size=22m --bs=2300 --name=mytest
mytest: (g=0): rw=write, bs=(R) 2300B-2300B, (W) 2300B-2300B, (T) 2300B-2300B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
Jobs: 1 (f=1): [W(1)][100.0%][w=5144KiB/s][w=2290 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=2160117: Sun Jun 25 15:33:23 2023
  write: IOPS=2317, BW=5205KiB/s (5330kB/s)(21.0MiB/4328msec); 0 zone resets
    clat (nsec): min=9759, max=58538, avg=12841.07, stdev=2262.21
     lat (nsec): min=9929, max=59068, avg=13088.08, stdev=2285.02
    clat percentiles (nsec):
     |  1.00th=[11456],  5.00th=[11712], 10.00th=[11840], 20.00th=[11968],
     | 30.00th=[12096], 40.00th=[12096], 50.00th=[12224], 60.00th=[12352],
     | 70.00th=[12608], 80.00th=[13120], 90.00th=[13760], 95.00th=[14912],
     | 99.00th=[23936], 99.50th=[25728], 99.90th=[35072], 99.95th=[37120],
     | 99.99th=[44800]
   bw (  KiB/s): min= 5013, max= 5282, per=99.95%, avg=5202.50, stdev=90.88, samples=8
   iops        : min= 2232, max= 2352, avg=2316.50, stdev=40.51, samples=8
  lat (usec)   : 10=0.02%, 20=97.31%, 50=2.66%, 100=0.01%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=379, max=6060, avg=416.30, stdev=73.93
    sync percentiles (usec):
     |  1.00th=[  392],  5.00th=[  396], 10.00th=[  400], 20.00th=[  404],
     | 30.00th=[  408], 40.00th=[  412], 50.00th=[  412], 60.00th=[  416],
     | 70.00th=[  416], 80.00th=[  420], 90.00th=[  429], 95.00th=[  433],
     | 99.00th=[  465], 99.50th=[  506], 99.90th=[ 1237], 99.95th=[ 1549],
     | 99.99th=[ 2245]
  cpu          : usr=0.92%, sys=10.98%, ctx=20061, majf=0, minf=11
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,10029,0,0 short=10029,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=5205KiB/s (5330kB/s), 5205KiB/s-5205KiB/s (5330kB/s-5330kB/s), io=21.0MiB (23.1MB), run=4328-4328msec
```

Raw device, block 4k:

```log
root@truenas[/home/admin]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=/dev/sdl
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
Jobs: 1 (f=1)
mytest: (groupid=0, jobs=1): err= 0: pid=672300: Wed Jun 28 00:11:19 2023
  write: IOPS=2820, BW=11.0MiB/s (11.6MB/s)(22.0MiB/1997msec); 0 zone resets
    clat (usec): min=4, max=112, avg= 5.92, stdev= 4.56
     lat (usec): min=4, max=113, avg= 6.13, stdev= 4.57
    clat percentiles (usec):
     |  1.00th=[    5],  5.00th=[    5], 10.00th=[    5], 20.00th=[    5],
     | 30.00th=[    6], 40.00th=[    6], 50.00th=[    6], 60.00th=[    6],
     | 70.00th=[    6], 80.00th=[    7], 90.00th=[    8], 95.00th=[    9],
     | 99.00th=[   13], 99.50th=[   17], 99.90th=[   95], 99.95th=[  103],
     | 99.99th=[  114]
   bw (  KiB/s): min=10352, max=11664, per=99.02%, avg=11170.67, stdev=713.94, samples=3
   iops        : min= 2588, max= 2916, avg=2792.67, stdev=178.49, samples=3
  lat (usec)   : 10=97.55%, 20=2.08%, 50=0.12%, 100=0.18%, 250=0.07%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=310, max=51488, avg=346.60, stdev=682.52
    sync percentiles (usec):
     |  1.00th=[  318],  5.00th=[  322], 10.00th=[  326], 20.00th=[  326],
     | 30.00th=[  330], 40.00th=[  334], 50.00th=[  334], 60.00th=[  338],
     | 70.00th=[  338], 80.00th=[  343], 90.00th=[  351], 95.00th=[  359],
     | 99.00th=[  371], 99.50th=[  383], 99.90th=[ 1106], 99.95th=[ 1254],
     | 99.99th=[51643]
  cpu          : usr=2.81%, sys=5.46%, ctx=16887, majf=0, minf=15
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=11.0MiB/s (11.6MB/s), 11.0MiB/s-11.0MiB/s (11.6MB/s-11.6MB/s), io=22.0MiB (23.1MB), run=1997-1997msec

Disk stats (read/write):
  sdl: ios=51/10649, merge=0/0, ticks=15/1722, in_queue=3262, util=95.98%
```

Truenas Core:

```log
root@truenas[/mnt/test tesla]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=test-data
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.28
Starting 1 process
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1): [W(1)][-.-%][w=9519KiB/s][w=2379 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=5433: Tue Jul  4 13:57:32 2023
  write: IOPS=2352, BW=9410KiB/s (9636kB/s)(22.0MiB/2394msec); 0 zone resets
    clat (nsec): min=6190, max=48977, avg=9088.43, stdev=3426.75
     lat (nsec): min=6370, max=49447, avg=9315.23, stdev=3438.67
    clat percentiles (nsec):
     |  1.00th=[ 6688],  5.00th=[ 7392], 10.00th=[ 7712], 20.00th=[ 7968],
     | 30.00th=[ 8160], 40.00th=[ 8256], 50.00th=[ 8384], 60.00th=[ 8512],
     | 70.00th=[ 8640], 80.00th=[ 8768], 90.00th=[ 9152], 95.00th=[13504],
     | 99.00th=[26496], 99.50th=[28800], 99.90th=[34560], 99.95th=[36608],
     | 99.99th=[48896]
   bw (  KiB/s): min= 9219, max= 9640, per=100.00%, avg=9475.25, stdev=201.36, samples=4
   iops        : min= 2304, max= 2410, avg=2368.50, stdev=50.71, samples=4
  lat (usec)   : 10=93.06%, 20=3.53%, 50=3.41%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=366, max=4709, avg=413.80, stdev=93.10
    sync percentiles (usec):
     |  1.00th=[  375],  5.00th=[  396], 10.00th=[  396], 20.00th=[  400],
     | 30.00th=[  404], 40.00th=[  404], 50.00th=[  404], 60.00th=[  408],
     | 70.00th=[  412], 80.00th=[  420], 90.00th=[  433], 95.00th=[  441],
     | 99.00th=[  465], 99.50th=[  506], 99.90th=[ 1876], 99.95th=[ 2180],
     | 99.99th=[ 4686]
  cpu          : usr=0.71%, sys=6.94%, ctx=11260, majf=0, minf=0
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=9410KiB/s (9636kB/s), 9410KiB/s-9410KiB/s (9636kB/s-9636kB/s), io=22.0MiB (23.1MB), run=2394-2394msec
```

# NVME Samsung 970 EVO 1TB

NTFS, block 4k:

```log
C:\Users\danil\Documents\k8s-public-copy>fio --rw=write --ioengine=sync --fdatasync=1 --directory=test-data --size=22m --bs=4k --name=mytest
fio: this platform does not support process shared mutexes, forcing use of threads. Use the 'thread' option to get rid of this warning.
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.35
Starting 1 thread
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1): [W(1)][100.0%][w=3927KiB/s][w=981 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=41484: Wed Jun 28 02:40:07 2023   
  write: IOPS=981, BW=3927KiB/s (4021kB/s)(22.0MiB/5737msec); 0 zone resets
    clat (usec): min=5, max=112, avg=11.15, stdev=10.34
     lat (usec): min=5, max=112, avg=11.32, stdev=10.34
    clat percentiles (usec):
     |  1.00th=[    6],  5.00th=[    6], 10.00th=[    6], 20.00th=[    7], 
     | 30.00th=[    7], 40.00th=[    8], 50.00th=[    8], 60.00th=[    8], 
     | 70.00th=[    9], 80.00th=[   10], 90.00th=[   30], 95.00th=[   38], 
     | 99.00th=[   49], 99.50th=[   56], 99.90th=[   75], 99.95th=[   77], 
     | 99.99th=[  113]
   bw (  KiB/s): min= 3800, max= 4079, per=99.98%, avg=3926.91, stdev=115.44, samples=11
   iops        : min=  950, max= 1019, avg=981.45, stdev=28.55, samples=11
  lat (usec)   : 10=82.07%, 20=5.95%, 50=11.10%, 100=0.87%, 250=0.02%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=813, max=7611, avg=1005.76, stdev=321.16
    sync percentiles (usec):
     |  1.00th=[  873],  5.00th=[  898], 10.00th=[  906], 20.00th=[  922],
     | 30.00th=[  930], 40.00th=[  947], 50.00th=[  963], 60.00th=[  979],
     | 70.00th=[  996], 80.00th=[ 1004], 90.00th=[ 1037], 95.00th=[ 1074],
     | 99.00th=[ 1975], 99.50th=[ 3851], 99.90th=[ 4113], 99.95th=[ 4146],
     | 99.99th=[ 7635]
  cpu          : usr=0.00%, sys=0.00%, ctx=0, majf=0, minf=0
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=3927KiB/s (4021kB/s), 3927KiB/s-3927KiB/s (4021kB/s-4021kB/s), io=22.0MiB (23.1MB), run=5737-5737msec
```

# SATA Plextor PX-0128M5S

NTFS, block 4k:

```log
D:\>fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --directory=test-data
fio: this platform does not support process shared mutexes, forcing use of threads. Use the 'thread' option to get rid of this warning.
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.35
Starting 1 thread
Jobs: 1 (f=1): [W(1)][100.0%][w=1673KiB/s][w=418 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=1976: Thu Jun 29 03:01:27 2023
  write: IOPS=416, BW=1668KiB/s (1708kB/s)(22.0MiB/13510msec); 0 zone resets
    clat (usec): min=4, max=170, avg= 7.66, stdev= 5.50
     lat (usec): min=5, max=170, avg= 7.84, stdev= 5.51
    clat percentiles (usec):
     |  1.00th=[    6],  5.00th=[    6], 10.00th=[    7], 20.00th=[    7],
     | 30.00th=[    7], 40.00th=[    7], 50.00th=[    8], 60.00th=[    8],
     | 70.00th=[    8], 80.00th=[    9], 90.00th=[    9], 95.00th=[   10],
     | 99.00th=[   14], 99.50th=[   44], 99.90th=[  116], 99.95th=[  133],
     | 99.99th=[  172]
   bw (  KiB/s): min= 1656, max= 1680, per=100.00%, avg=1669.04, stdev= 7.22, samples=26
   iops        : min=  414, max=  420, avg=417.15, stdev= 1.78, samples=26
  lat (usec)   : 10=96.38%, 20=2.89%, 50=0.37%, 100=0.25%, 250=0.11%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=2278, max=4918, avg=2389.36, stdev=98.98
    sync percentiles (usec):
     |  1.00th=[ 2278],  5.00th=[ 2311], 10.00th=[ 2311], 20.00th=[ 2311],
     | 30.00th=[ 2343], 40.00th=[ 2343], 50.00th=[ 2376], 60.00th=[ 2409],
     | 70.00th=[ 2442], 80.00th=[ 2442], 90.00th=[ 2474], 95.00th=[ 2507],
     | 99.00th=[ 2606], 99.50th=[ 2737], 99.90th=[ 3752], 99.95th=[ 4686],
     | 99.99th=[ 4948]
  cpu          : usr=0.00%, sys=0.00%, ctx=0, majf=0, minf=0
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=1668KiB/s (1708kB/s), 1668KiB/s-1668KiB/s (1708kB/s-1708kB/s), io=22.0MiB (23.1MB), run=13510-13510msec
```

# SATA TEAM T253X2512G 500GB TPBF2206080010103840

Raw device, block 4k:

```log
root@truenas[/home/admin]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=/dev/sdm
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
Jobs: 1 (f=1): [W(1)][80.0%][w=4664KiB/s][w=1166 IOPS][eta 00m:01s]
mytest: (groupid=0, jobs=1): err= 0: pid=677741: Wed Jun 28 00:14:26 2023
  write: IOPS=1151, BW=4606KiB/s (4717kB/s)(22.0MiB/4891msec); 0 zone resets
    clat (usec): min=4, max=191, avg= 7.99, stdev= 6.33
     lat (usec): min=4, max=191, avg= 8.32, stdev= 6.36
    clat percentiles (usec):
     |  1.00th=[    5],  5.00th=[    6], 10.00th=[    6], 20.00th=[    6],
     | 30.00th=[    7], 40.00th=[    7], 50.00th=[    8], 60.00th=[    9],
     | 70.00th=[    9], 80.00th=[    9], 90.00th=[   10], 95.00th=[   12],
     | 99.00th=[   18], 99.50th=[   23], 99.90th=[  123], 99.95th=[  141],
     | 99.99th=[  192]
   bw (  KiB/s): min= 4456, max= 4688, per=99.93%, avg=4603.56, stdev=86.91, samples=9
   iops        : min= 1114, max= 1172, avg=1150.89, stdev=21.73, samples=9
  lat (usec)   : 10=91.41%, 20=7.90%, 50=0.41%, 100=0.09%, 250=0.20%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=293, max=1898, avg=857.65, stdev=527.71
    sync percentiles (usec):
     |  1.00th=[  306],  5.00th=[  314], 10.00th=[  318], 20.00th=[  322],
     | 30.00th=[  330], 40.00th=[  338], 50.00th=[ 1319], 60.00th=[ 1336],
     | 70.00th=[ 1352], 80.00th=[ 1369], 90.00th=[ 1385], 95.00th=[ 1483],
     | 99.00th=[ 1598], 99.50th=[ 1631], 99.90th=[ 1663], 99.95th=[ 1680],
     | 99.99th=[ 1893]
  cpu          : usr=0.94%, sys=3.78%, ctx=16878, majf=0, minf=14
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=4606KiB/s (4717kB/s), 4606KiB/s-4606KiB/s (4717kB/s-4717kB/s), io=22.0MiB (23.1MB), run=4891-4891msec

Disk stats (read/write):
  sdm: ios=51/10693, merge=0/0, ticks=18/4401, in_queue=8415, util=98.31%
```

Truenas Core:

```log
root@truenas[/mnt/test-500]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=test-data
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.28
Starting 1 process
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1): [W(1)][100.0%][w=3335KiB/s][w=833 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=5676: Tue Jul  4 14:02:53 2023
  write: IOPS=914, BW=3658KiB/s (3746kB/s)(22.0MiB/6159msec); 0 zone resets
    clat (nsec): min=7390, max=46387, avg=12337.13, stdev=4307.19
     lat (nsec): min=7660, max=46887, avg=12656.81, stdev=4349.90
    clat percentiles (nsec):
     |  1.00th=[ 7904],  5.00th=[ 8160], 10.00th=[ 8256], 20.00th=[ 8512],
     | 30.00th=[ 8768], 40.00th=[ 9152], 50.00th=[12736], 60.00th=[14272],
     | 70.00th=[15040], 80.00th=[15296], 90.00th=[15424], 95.00th=[15936],
     | 99.00th=[26240], 99.50th=[31104], 99.90th=[44288], 99.95th=[45312],
     | 99.99th=[46336]
   bw (  KiB/s): min= 2944, max= 3937, per=100.00%, avg=3663.17, stdev=256.76, samples=12
   iops        : min=  736, max=  984, avg=915.50, stdev=64.15, samples=12
  lat (usec)   : 10=45.21%, 20=50.98%, 50=3.82%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=414, max=9854, avg=1078.45, stdev=583.56
    sync percentiles (usec):
     |  1.00th=[  461],  5.00th=[  469], 10.00th=[  474], 20.00th=[  490],
     | 30.00th=[  519], 40.00th=[  611], 50.00th=[ 1467], 60.00th=[ 1500],
     | 70.00th=[ 1516], 80.00th=[ 1532], 90.00th=[ 1647], 95.00th=[ 1729],
     | 99.00th=[ 3163], 99.50th=[ 3228], 99.90th=[ 3392], 99.95th=[ 3458],
     | 99.99th=[ 9896]
  cpu          : usr=0.63%, sys=3.22%, ctx=11262, majf=0, minf=0
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=3658KiB/s (3746kB/s), 3658KiB/s-3658KiB/s (3746kB/s-3746kB/s), io=22.0MiB (23.1MB), run=6159-6159msec
```

# SATA Apacer AS340 480GB E09507281ACE00417122

Raw device, block 4k:

```log
root@truenas[/home/admin]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=/dev/sdd
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
Jobs: 1 (f=1): [W(1)][100.0%][w=4404KiB/s][w=1101 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=971230: Tue Jul  4 00:55:33 2023
  write: IOPS=1100, BW=4400KiB/s (4506kB/s)(22.0MiB/5120msec); 0 zone resets
    clat (usec): min=3, max=209, avg= 7.57, stdev= 8.94
     lat (usec): min=4, max=210, avg= 7.90, stdev= 8.98
    clat percentiles (usec):
     |  1.00th=[    5],  5.00th=[    5], 10.00th=[    5], 20.00th=[    6],
     | 30.00th=[    6], 40.00th=[    7], 50.00th=[    7], 60.00th=[    8],
     | 70.00th=[    8], 80.00th=[    9], 90.00th=[   10], 95.00th=[   11],
     | 99.00th=[   18], 99.50th=[   31], 99.90th=[  153], 99.95th=[  167],
     | 99.99th=[  210]
   bw (  KiB/s): min= 4320, max= 4448, per=100.00%, avg=4403.20, stdev=44.97, samples=10
   iops        : min= 1080, max= 1112, avg=1100.80, stdev=11.24, samples=10
  lat (usec)   : 4=0.11%, 10=93.20%, 20=5.89%, 50=0.36%, 100=0.04%
  lat (usec)   : 250=0.41%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=290, max=2141, avg=898.84, stdev=545.18
    sync percentiles (usec):
     |  1.00th=[  326],  5.00th=[  334], 10.00th=[  338], 20.00th=[  347],
     | 30.00th=[  355], 40.00th=[  359], 50.00th=[ 1369], 60.00th=[ 1401],
     | 70.00th=[ 1418], 80.00th=[ 1434], 90.00th=[ 1450], 95.00th=[ 1467],
     | 99.00th=[ 1614], 99.50th=[ 1647], 99.90th=[ 1729], 99.95th=[ 1778],
     | 99.99th=[ 2147]
  cpu          : usr=0.76%, sys=3.09%, ctx=16196, majf=0, minf=14
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=4400KiB/s (4506kB/s), 4400KiB/s-4400KiB/s (4506kB/s-4506kB/s), io=22.0MiB (23.1MB), run=5120-5120msec

Disk stats (read/write):
  sdd: ios=0/10771, merge=0/0, ticks=0/4677, in_queue=9116, util=98.04%
```

# SATA TEAM T253480GB 480GB TPBF2209020010803378

Raw device, block 4k:

```log
root@truenas[/home/admin]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=/dev/sde
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
Jobs: 1 (f=1): [W(1)][100.0%][w=4720KiB/s][w=1180 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=502725: Tue Jul  4 01:47:53 2023
  write: IOPS=1209, BW=4840KiB/s (4956kB/s)(22.0MiB/4655msec); 0 zone resets
    clat (usec): min=4, max=292, avg= 8.16, stdev= 9.37
     lat (usec): min=4, max=293, avg= 8.54, stdev= 9.83
    clat percentiles (usec):
     |  1.00th=[    5],  5.00th=[    6], 10.00th=[    6], 20.00th=[    6],
     | 30.00th=[    7], 40.00th=[    7], 50.00th=[    8], 60.00th=[    9],
     | 70.00th=[    9], 80.00th=[    9], 90.00th=[   10], 95.00th=[   12],
     | 99.00th=[   19], 99.50th=[   34], 99.90th=[  151], 99.95th=[  190],
     | 99.99th=[  293]
   bw (  KiB/s): min= 4464, max= 4944, per=99.99%, avg=4839.11, stdev=151.39, samples=9
   iops        : min= 1116, max= 1236, avg=1209.78, stdev=37.85, samples=9
  lat (usec)   : 10=92.26%, 20=6.92%, 50=0.39%, 100=0.04%, 250=0.37%
  lat (usec)   : 500=0.02%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=246, max=21890, avg=813.21, stdev=627.76
    sync percentiles (usec):
     |  1.00th=[  255],  5.00th=[  265], 10.00th=[  269], 20.00th=[  277],
     | 30.00th=[  281], 40.00th=[  285], 50.00th=[ 1270], 60.00th=[ 1287],
     | 70.00th=[ 1303], 80.00th=[ 1319], 90.00th=[ 1336], 95.00th=[ 1418],
     | 99.00th=[ 1516], 99.50th=[ 1549], 99.90th=[ 1614], 99.95th=[ 2114],
     | 99.99th=[21890]
  cpu          : usr=0.73%, sys=4.02%, ctx=16684, majf=0, minf=16
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=4840KiB/s (4956kB/s), 4840KiB/s-4840KiB/s (4956kB/s-4956kB/s), io=22.0MiB (23.1MB), run=4655-4655msec

Disk stats (read/write):
  sde: ios=72/11223, merge=0/0, ticks=12/4360, in_queue=8463, util=98.31%
```

# Slow vdev + Optane Special

Default:

```log
root@truenas[/mnt/test-optane]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=test-data
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1): [W(1)][100.0%][w=516KiB/s][w=129 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=1764993: Tue Jul  4 03:41:37 2023
  write: IOPS=140, BW=563KiB/s (577kB/s)(22.0MiB/39980msec); 0 zone resets
    clat (usec): min=14, max=137, avg=25.86, stdev= 9.61
     lat (usec): min=14, max=138, avg=26.39, stdev= 9.75
    clat percentiles (usec):
     |  1.00th=[   17],  5.00th=[   18], 10.00th=[   18], 20.00th=[   21],
     | 30.00th=[   21], 40.00th=[   21], 50.00th=[   22], 60.00th=[   23],
     | 70.00th=[   27], 80.00th=[   33], 90.00th=[   40], 95.00th=[   45],
     | 99.00th=[   61], 99.50th=[   70], 99.90th=[   80], 99.95th=[   87],
     | 99.99th=[  139]
   bw (  KiB/s): min=  296, max=  616, per=99.91%, avg=563.85, stdev=65.07, samples=79
   iops        : min=   74, max=  154, avg=140.96, stdev=16.27, samples=79
  lat (usec)   : 20=17.47%, 50=79.21%, 100=3.30%, 250=0.02%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=5323, max=82512, avg=7069.57, stdev=1944.89
    sync percentiles (usec):
     |  1.00th=[ 5735],  5.00th=[ 5932], 10.00th=[ 6063], 20.00th=[ 6259],
     | 30.00th=[ 6390], 40.00th=[ 6587], 50.00th=[ 6718], 60.00th=[ 6849],
     | 70.00th=[ 7046], 80.00th=[ 7242], 90.00th=[ 7767], 95.00th=[10159],
     | 99.00th=[15008], 99.50th=[16909], 99.90th=[23462], 99.95th=[26084],
     | 99.99th=[82314]
  cpu          : usr=0.10%, sys=1.18%, ctx=11271, majf=0, minf=11
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=563KiB/s (577kB/s), 563KiB/s-563KiB/s (577kB/s-577kB/s), io=22.0MiB (23.1MB), run=39980-39980msec
```

Special block size 1M:

```log
root@truenas[/mnt/test-optane]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=test-data
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1): [W(1)][100.0%][w=648KiB/s][w=162 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=1768851: Tue Jul  4 03:43:25 2023
  write: IOPS=178, BW=712KiB/s (729kB/s)(22.0MiB/31628msec); 0 zone resets
    clat (usec): min=13, max=117, avg=25.17, stdev= 9.40
     lat (usec): min=14, max=118, avg=25.69, stdev= 9.53
    clat percentiles (usec):
     |  1.00th=[   17],  5.00th=[   17], 10.00th=[   18], 20.00th=[   21],
     | 30.00th=[   21], 40.00th=[   21], 50.00th=[   22], 60.00th=[   23],
     | 70.00th=[   26], 80.00th=[   31], 90.00th=[   39], 95.00th=[   45],
     | 99.00th=[   61], 99.50th=[   68], 99.90th=[   80], 99.95th=[   96],
     | 99.99th=[  118]
   bw (  KiB/s): min=  480, max=  760, per=99.96%, avg=712.76, stdev=56.11, samples=63
   iops        : min=  120, max=  190, avg=178.19, stdev=14.03, samples=63
  lat (usec)   : 20=19.02%, 50=77.50%, 100=3.46%, 250=0.02%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=4336, max=53849, avg=5587.31, stdev=1183.52
    sync percentiles (usec):
     |  1.00th=[ 4817],  5.00th=[ 4883], 10.00th=[ 5014], 20.00th=[ 5145],
     | 30.00th=[ 5276], 40.00th=[ 5342], 50.00th=[ 5407], 60.00th=[ 5407],
     | 70.00th=[ 5538], 80.00th=[ 5735], 90.00th=[ 6259], 95.00th=[ 6915],
     | 99.00th=[ 9503], 99.50th=[11207], 99.90th=[14877], 99.95th=[16319],
     | 99.99th=[53740]
  cpu          : usr=0.15%, sys=1.45%, ctx=11264, majf=0, minf=11
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=712KiB/s (729kB/s), 712KiB/s-712KiB/s (729kB/s-729kB/s), io=22.0MiB (23.1MB), run=31628-31628msec
```

# Slow vdev + Optane SLOG

```log
root@truenas[/mnt/test-optane]# fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=test-data
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
Jobs: 1 (f=1)
mytest: (groupid=0, jobs=1): err= 0: pid=1823302: Tue Jul  4 03:49:20 2023
  write: IOPS=5812, BW=22.7MiB/s (23.8MB/s)(22.0MiB/969msec); 0 zone resets
    clat (nsec): min=11139, max=42696, avg=13062.14, stdev=2243.41
     lat (nsec): min=11379, max=43527, avg=13317.93, stdev=2287.99
    clat percentiles (nsec):
     |  1.00th=[11456],  5.00th=[11712], 10.00th=[11840], 20.00th=[12096],
     | 30.00th=[12224], 40.00th=[12224], 50.00th=[12352], 60.00th=[12480],
     | 70.00th=[12736], 80.00th=[13120], 90.00th=[15296], 95.00th=[17280],
     | 99.00th=[22400], 99.50th=[26240], 99.90th=[33536], 99.95th=[36096],
     | 99.99th=[42752]
   bw (  KiB/s): min=23632, max=23632, per=100.00%, avg=23632.00, stdev= 0.00, samples=1
   iops        : min= 5908, max= 5908, avg=5908.00, stdev= 0.00, samples=1
  lat (usec)   : 20=97.87%, 50=2.13%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=127, max=675, avg=156.47, stdev=15.73
    sync percentiles (usec):
     |  1.00th=[  133],  5.00th=[  139], 10.00th=[  143], 20.00th=[  147],
     | 30.00th=[  149], 40.00th=[  153], 50.00th=[  155], 60.00th=[  157],
     | 70.00th=[  161], 80.00th=[  165], 90.00th=[  174], 95.00th=[  182],
     | 99.00th=[  206], 99.50th=[  212], 99.90th=[  237], 99.95th=[  255],
     | 99.99th=[  676]
  cpu          : usr=3.51%, sys=27.17%, ctx=9381, majf=0, minf=12
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=22.7MiB/s (23.8MB/s), 22.7MiB/s-22.7MiB/s (23.8MB/s-23.8MB/s), io=22.0MiB (23.1MB), run=969-969msec
```

# NVME ADATA LEGEND 960 2TB

NTFS:

```log
D:\>fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest
fio: this platform does not support process shared mutexes, forcing use of threads. Use the 'thread' option to get rid of this warning.
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.35
Starting 1 thread
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1): [W(1)][100.0%][w=1809KiB/s][w=452 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=4960: Wed Jul 19 05:35:43 2023
  write: IOPS=421, BW=1688KiB/s (1728kB/s)(22.0MiB/13349msec); 0 zone resets
    clat (nsec): min=4400, max=78400, avg=8460.60, stdev=5091.38
     lat (nsec): min=4500, max=78800, avg=8647.51, stdev=5098.82
    clat percentiles (nsec):
     |  1.00th=[ 5280],  5.00th=[ 5984], 10.00th=[ 6176], 20.00th=[ 6432],
     | 30.00th=[ 6688], 40.00th=[ 6880], 50.00th=[ 7200], 60.00th=[ 7520],
     | 70.00th=[ 7776], 80.00th=[ 8256], 90.00th=[ 9024], 95.00th=[22912],
     | 99.00th=[29824], 99.50th=[34048], 99.90th=[45312], 99.95th=[50944],
     | 99.99th=[78336]
   bw (  KiB/s): min= 1357, max= 2812, per=97.89%, avg=1652.38, stdev=260.46, samples=26
   iops        : min=  339, max=  703, avg=412.96, stdev=65.17, samples=26
  lat (usec)   : 10=92.21%, 20=1.60%, 50=6.13%, 100=0.07%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=748, max=16687, avg=2360.04, stdev=483.35
    sync percentiles (usec):
     |  1.00th=[ 1074],  5.00th=[ 1188], 10.00th=[ 2245], 20.00th=[ 2311],
     | 30.00th=[ 2343], 40.00th=[ 2343], 50.00th=[ 2376], 60.00th=[ 2507],
     | 70.00th=[ 2540], 80.00th=[ 2573], 90.00th=[ 2769], 95.00th=[ 2900],
     | 99.00th=[ 2999], 99.50th=[ 2999], 99.90th=[ 4424], 99.95th=[ 5080],
     | 99.99th=[16712]
  cpu          : usr=0.00%, sys=0.00%, ctx=0, majf=0, minf=0
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=1688KiB/s (1728kB/s), 1688KiB/s-1688KiB/s (1728kB/s-1728kB/s), io=22.0MiB (23.1MB), run=13349-13349msec
```

# XPG GAMMIX S70 BLADE 2TB

NTFS:

```log
E:\>fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest
fio: this platform does not support process shared mutexes, forcing use of threads. Use the 'thread' option to get rid of this warning.
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.35
Starting 1 thread
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1)
mytest: (groupid=0, jobs=1): err= 0: pid=8880: Wed Jul 19 05:37:40 2023
  write: IOPS=3666, BW=14.3MiB/s (15.0MB/s)(22.0MiB/1536msec); 0 zone resets
    clat (nsec): min=4200, max=83900, avg=6105.18, stdev=3870.80
     lat (nsec): min=4300, max=84400, avg=6239.44, stdev=3881.06
    clat percentiles (nsec):
     |  1.00th=[ 4384],  5.00th=[ 4512], 10.00th=[ 4512], 20.00th=[ 4576],
     | 30.00th=[ 4576], 40.00th=[ 4704], 50.00th=[ 4832], 60.00th=[ 5024],
     | 70.00th=[ 5408], 80.00th=[ 6112], 90.00th=[ 7584], 95.00th=[17024],
     | 99.00th=[21376], 99.50th=[24704], 99.90th=[33024], 99.95th=[43776],
     | 99.99th=[83456]
   bw (  KiB/s): min=14642, max=14698, per=100.00%, avg=14676.00, stdev=29.87, samples=3
   iops        : min= 3660, max= 3674, avg=3668.67, stdev= 7.57, samples=3
  lat (usec)   : 10=93.08%, 20=5.47%, 50=1.42%, 100=0.04%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=253, max=828, avg=265.24, stdev=15.61
    sync percentiles (usec):
     |  1.00th=[  255],  5.00th=[  255], 10.00th=[  258], 20.00th=[  258],
     | 30.00th=[  260], 40.00th=[  260], 50.00th=[  262], 60.00th=[  262],
     | 70.00th=[  265], 80.00th=[  269], 90.00th=[  281], 95.00th=[  293],
     | 99.00th=[  318], 99.50th=[  326], 99.90th=[  388], 99.95th=[  416],
     | 99.99th=[  832]
  cpu          : usr=0.00%, sys=0.00%, ctx=0, majf=0, minf=0
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,5632,0,0 short=5631,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=14.3MiB/s (15.0MB/s), 14.3MiB/s-14.3MiB/s (15.0MB/s-15.0MB/s), io=22.0MiB (23.1MB), run=1536-1536msec
```

```log
$ fio --rw=write --ioengine=sync --fdatasync=1 --size=50m --bs=4k --runtime=10 --time_based=1 --name=mytest --filename=test-data
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.33
Starting 1 process
Jobs: 1 (f=1): [W(1)][100.0%][w=8352KiB/s][w=2088 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=6056: Wed Jun  5 00:54:58 2024
  write: IOPS=2137, BW=8551KiB/s (8756kB/s)(83.5MiB/10001msec); 0 zone resets
    clat (usec): min=4, max=253, avg=17.99, stdev=11.01
     lat (usec): min=4, max=253, avg=18.52, stdev=11.14
    clat percentiles (usec):
     |  1.00th=[    5],  5.00th=[    6], 10.00th=[    6], 20.00th=[    7],
     | 30.00th=[   15], 40.00th=[   19], 50.00th=[   21], 60.00th=[   22],
     | 70.00th=[   22], 80.00th=[   23], 90.00th=[   25], 95.00th=[   26],
     | 99.00th=[   52], 99.50th=[   56], 99.90th=[  194], 99.95th=[  208],
     | 99.99th=[  235]
   bw (  KiB/s): min= 8280, max= 8864, per=100.00%, avg=8561.26, stdev=158.98, samples=19
   iops        : min= 2070, max= 2216, avg=2140.32, stdev=39.75, samples=19
  lat (usec)   : 10=25.31%, 20=24.52%, 50=48.90%, 100=1.13%, 250=0.14%
  lat (usec)   : 500=0.01%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=385, max=9783, avg=446.95, stdev=433.44
    sync percentiles (usec):
     |  1.00th=[  392],  5.00th=[  396], 10.00th=[  400], 20.00th=[  408],
     | 30.00th=[  424], 40.00th=[  429], 50.00th=[  429], 60.00th=[  429],
     | 70.00th=[  433], 80.00th=[  437], 90.00th=[  441], 95.00th=[  449],
     | 99.00th=[  506], 99.50th=[  570], 99.90th=[ 9634], 99.95th=[ 9765],
     | 99.99th=[ 9765]
  cpu          : usr=1.08%, sys=8.14%, ctx=42789, majf=0, minf=13
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,21379,0,0 short=21379,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=8551KiB/s (8756kB/s), 8551KiB/s-8551KiB/s (8756kB/s-8756kB/s), io=83.5MiB (87.6MB), run=10001-10001msec
```

# SK Hynix P31 Gold 500GB

RAW:

```log
$ sudo fio --rw=write --ioengine=sync --fdatasync=1 --size=50m --bs=4k --runtime=10 --time_based=1 --name=mytest --filename=/dev/nvme0n1
mytest: (g=0): rw=write, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=sync, iodepth=1
fio-3.33
Starting 1 process
Jobs: 1 (f=1): [W(1)][100.0%][w=16.6MiB/s][w=4254 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=1441: Wed Jun 26 05:29:21 2024
  write: IOPS=4257, BW=16.6MiB/s (17.4MB/s)(166MiB/10001msec); 0 zone resets
    clat (nsec): min=2307, max=34173, avg=2725.54, stdev=758.20
     lat (nsec): min=2401, max=34439, avg=2814.27, stdev=766.17
    clat percentiles (nsec):
     |  1.00th=[ 2416],  5.00th=[ 2480], 10.00th=[ 2480], 20.00th=[ 2544],
     | 30.00th=[ 2544], 40.00th=[ 2576], 50.00th=[ 2608], 60.00th=[ 2672],
     | 70.00th=[ 2704], 80.00th=[ 2768], 90.00th=[ 2896], 95.00th=[ 3088],
     | 99.00th=[ 4576], 99.50th=[ 5472], 99.90th=[13888], 99.95th=[18560],
     | 99.99th=[28288]
   bw (  KiB/s): min=16864, max=17160, per=100.00%, avg=17039.16, stdev=91.05, samples=19
   iops        : min= 4216, max= 4290, avg=4259.79, stdev=22.76, samples=19
  lat (usec)   : 4=98.47%, 10=1.36%, 20=0.13%, 50=0.05%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=224, max=6900, avg=231.08, stdev=96.45
    sync percentiles (usec):
     |  1.00th=[  227],  5.00th=[  227], 10.00th=[  227], 20.00th=[  229],
     | 30.00th=[  229], 40.00th=[  229], 50.00th=[  229], 60.00th=[  229],
     | 70.00th=[  229], 80.00th=[  229], 90.00th=[  231], 95.00th=[  237],
     | 99.00th=[  241], 99.50th=[  243], 99.90th=[  322], 99.95th=[ 2278],
     | 99.99th=[ 5604]
  cpu          : usr=0.78%, sys=4.28%, ctx=85175, majf=4, minf=15
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,42579,0,0 short=42579,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=16.6MiB/s (17.4MB/s), 16.6MiB/s-16.6MiB/s (17.4MB/s-17.4MB/s), io=166MiB (174MB), run=10001-10001msec

Disk stats (read/write):
  nvme0n1: ios=52/84273, merge=0/0, ticks=2/9490, in_queue=18265, util=98.99%
```

# To be continued...
