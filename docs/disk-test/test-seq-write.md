
# Run test

https://arstechnica.com/gadgets/2020/02/how-fast-are-your-disks-find-out-the-open-source-way-with-fio/

```bash
# test on a filesystem
fio --ioengine=posixaio --rw=write --bs=32m --numjobs=4 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --size=1g --group_reporting --name=seq-write

# alt command
dd if=/dev/zero of=test-dd bs=32000k count=100 oflag=dsync
```

# Main RAID array

Truenas Scale, SZTD-3, 6 cores:

```log
root@truenas[/mnt/main/data/torrent-data]# fio --ioengine=posixaio --rw=write --bs=32m --numjobs=4 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --size=1g --group_reporting --name=seq-write
seq-write: (g=0): rw=write, bs=(R) 32.0MiB-32.0MiB, (W) 32.0MiB-32.0MiB, (T) 32.0MiB-32.0MiB, ioengine=posixaio, iodepth=1
...
fio-3.25
Starting 4 processes
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
Jobs: 2 (f=2): [F(1),_(2),F(1)][100.0%][eta 00m:00s]
seq-write: (groupid=0, jobs=4): err= 0: pid=220578: Mon Jul 17 03:30:08 2023
  write: IOPS=3, BW=100MiB/s (105MB/s)(7648MiB/76350msec); 0 zone resets
    slat (usec): min=547, max=55561, avg=1218.39, stdev=3616.11
    clat (msec): min=17, max=1980, avg=1011.58, stdev=473.85
     lat (msec): min=18, max=1981, avg=1012.80, stdev=473.34
    clat percentiles (msec):
     |  1.00th=[   19],  5.00th=[   25], 10.00th=[   35], 20.00th=[  810],
     | 30.00th=[ 1099], 40.00th=[ 1116], 50.00th=[ 1133], 60.00th=[ 1150],
     | 70.00th=[ 1167], 80.00th=[ 1183], 90.00th=[ 1385], 95.00th=[ 1804],
     | 99.00th=[ 1955], 99.50th=[ 1989], 99.90th=[ 1989], 99.95th=[ 1989],
     | 99.99th=[ 1989]
   bw (  KiB/s): min=248560, max=2229537, per=100.00%, avg=302423.33, stdev=69559.51, samples=203
   iops        : min=    4, max=   68, avg= 8.55, stdev= 2.18, samples=203
  lat (msec)   : 20=1.26%, 50=10.46%, 100=1.67%, 250=1.67%, 500=1.67%
  lat (msec)   : 750=0.84%, 1000=5.86%, 2000=76.57%
  cpu          : usr=0.07%, sys=0.00%, ctx=604, majf=22, minf=227
  IO depths    : 1=101.7%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,239,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=100MiB/s (105MB/s), 100MiB/s-100MiB/s (105MB/s-105MB/s), io=7648MiB (8020MB), run=76350-76350msec
```

Truenas Scale, SZTD-1, 6 cores:

```log
root@truenas[/mnt/main/data/torrent-data]# fio --ioengine=posixaio --rw=write --bs=32m --numjobs=4 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --size=1g --group_reporting --name=seq-write
seq-write: (g=0): rw=write, bs=(R) 32.0MiB-32.0MiB, (W) 32.0MiB-32.0MiB, (T) 32.0MiB-32.0MiB, ioengine=posixaio, iodepth=1
...
fio-3.25
Starting 4 processes
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
Jobs: 2 (f=2): [_(1),F(2),_(1)][100.0%][eta 00m:00s]
seq-write: (groupid=0, jobs=4): err= 0: pid=227648: Mon Jul 17 03:33:15 2023
  write: IOPS=5, BW=161MiB/s (169MB/s)(11.5GiB/72790msec); 0 zone resets
    slat (usec): min=500, max=7093, avg=926.85, stdev=431.53
    clat (msec): min=6, max=1575, avg=655.69, stdev=264.54
     lat (msec): min=7, max=1576, avg=656.61, stdev=264.44
    clat percentiles (msec):
     |  1.00th=[    9],  5.00th=[   29], 10.00th=[  317], 20.00th=[  667],
     | 30.00th=[  676], 40.00th=[  676], 50.00th=[  676], 60.00th=[  684],
     | 70.00th=[  684], 80.00th=[  693], 90.00th=[  768], 95.00th=[ 1045],
     | 99.00th=[ 1519], 99.50th=[ 1569], 99.90th=[ 1569], 99.95th=[ 1569],
     | 99.99th=[ 1569]
   bw (  KiB/s): min=260580, max=2293760, per=100.00%, avg=286551.95, stdev=55815.13, samples=332
   iops        : min=    4, max=   70, avg= 8.39, stdev= 1.74, samples=332
  lat (msec)   : 10=1.91%, 20=0.82%, 50=5.72%, 250=1.09%, 500=1.63%
  lat (msec)   : 750=78.20%, 1000=4.63%, 2000=5.99%
  cpu          : usr=0.12%, sys=0.00%, ctx=1030, majf=23, minf=227
  IO depths    : 1=101.1%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,367,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=161MiB/s (169MB/s), 161MiB/s-161MiB/s (169MB/s-169MB/s), io=11.5GiB (12.3GB), run=72790-72790msec
```

Truenas Scale, SZTD-3, 10 cores:

```log
root@truenas[/mnt/main/data/torrent-data]# fio --ioengine=posixaio --rw=write --bs=32m --numjobs=4 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --size=1g --group_reporting --name=seq-write
seq-write: (g=0): rw=write, bs=(R) 32.0MiB-32.0MiB, (W) 32.0MiB-32.0MiB, (T) 32.0MiB-32.0MiB, ioengine=posixaio, iodepth=1
...
fio-3.25
Starting 4 processes
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
Jobs: 4 (f=4): [F(4)][100.0%][eta 00m:00s]
seq-write: (groupid=0, jobs=4): err= 0: pid=19327: Mon Jul 17 03:41:25 2023
  write: IOPS=4, BW=141MiB/s (148MB/s)(10.3GiB/74478msec); 0 zone resets
    slat (usec): min=500, max=11042, avg=1048.03, stdev=612.19
    clat (msec): min=8, max=1740, avg=732.44, stdev=296.07
     lat (msec): min=10, max=1741, avg=733.49, stdev=295.88
    clat percentiles (msec):
     |  1.00th=[   12],  5.00th=[   20], 10.00th=[  106], 20.00th=[  726],
     | 30.00th=[  743], 40.00th=[  751], 50.00th=[  760], 60.00th=[  768],
     | 70.00th=[  785], 80.00th=[  810], 90.00th=[  995], 95.00th=[ 1250],
     | 99.00th=[ 1603], 99.50th=[ 1720], 99.90th=[ 1737], 99.95th=[ 1737],
     | 99.99th=[ 1737]
   bw (  KiB/s): min=256878, max=2294942, per=100.00%, avg=289647.41, stdev=59558.79, samples=294
   iops        : min=    4, max=   70, avg= 8.63, stdev= 1.84, samples=294
  lat (msec)   : 10=0.30%, 20=4.86%, 50=3.04%, 100=1.52%, 250=1.22%
  lat (msec)   : 500=0.61%, 750=27.96%, 1000=51.06%, 2000=9.42%
  cpu          : usr=0.11%, sys=0.00%, ctx=755, majf=22, minf=251
  IO depths    : 1=101.2%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,329,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=141MiB/s (148MB/s), 141MiB/s-141MiB/s (148MB/s-148MB/s), io=10.3GiB (11.0GB), run=74478-74478msec
```

Truenas Scale, ZSTD-1, 10 cores:

```log
root@truenas[/mnt/main/data/torrent-data]# fio --ioengine=posixaio --rw=write --bs=32m --numjobs=4 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --size=1g --group_reporting --name=seq-write
seq-write: (g=0): rw=write, bs=(R) 32.0MiB-32.0MiB, (W) 32.0MiB-32.0MiB, (T) 32.0MiB-32.0MiB, ioengine=posixaio, iodepth=1
...
fio-3.25
Starting 4 processes
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
Jobs: 1 (f=1): [F(1),_(3)][100.0%][eta 00m:00s]                  
seq-write: (groupid=0, jobs=4): err= 0: pid=208382: Mon Jul 17 03:26:22 2023
  write: IOPS=7, BW=234MiB/s (245MB/s)(16.0GiB/70047msec); 0 zone resets
    slat (usec): min=487, max=4566, avg=1020.23, stdev=384.79
    clat (msec): min=9, max=1411, avg=469.49, stdev=188.08
     lat (msec): min=11, max=1412, avg=470.51, stdev=187.92
    clat percentiles (msec):
     |  1.00th=[   11],  5.00th=[   31], 10.00th=[  418], 20.00th=[  430],
     | 30.00th=[  439], 40.00th=[  443], 50.00th=[  451], 60.00th=[  464],
     | 70.00th=[  472], 80.00th=[  481], 90.00th=[  634], 95.00th=[  869],
     | 99.00th=[ 1070], 99.50th=[ 1368], 99.90th=[ 1418], 99.95th=[ 1418],
     | 99.99th=[ 1418]
   bw (  KiB/s): min=260060, max=2362841, per=100.00%, avg=304763.00, stdev=53100.93, samples=437
   iops        : min=    4, max=   72, avg= 9.15, stdev= 1.63, samples=437
  lat (msec)   : 10=0.78%, 20=3.52%, 50=1.37%, 100=0.59%, 250=0.78%
  lat (msec)   : 500=77.54%, 750=7.03%, 1000=7.03%, 2000=1.37%
  cpu          : usr=0.19%, sys=0.00%, ctx=1315, majf=14, minf=206
  IO depths    : 1=100.8%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,512,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=234MiB/s (245MB/s), 234MiB/s-234MiB/s (245MB/s-245MB/s), io=16.0GiB (17.2GB), run=70047-70047msec
```

Truenas Core:

```log
root@truenas[/mnt/main/data/torrent-data/test]# fio --ioengine=posixaio --rw=write --bs=32m --numjobs=4 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --size=1g --group_reporting --name=seq-write
seq-write: (g=0): rw=write, bs=(R) 32.0MiB-32.0MiB, (W) 32.0MiB-32.0MiB, (T) 32.0MiB-32.0MiB, ioengine=posixaio, iodepth=1
...
fio-3.28
Starting 4 processes
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
Jobs: 4 (f=4): [F(4)][100.0%][eta 00m:00s]                       
seq-write: (groupid=0, jobs=4): err= 0: pid=16433: Wed Jul  5 06:32:44 2023
  write: IOPS=15, BW=508MiB/s (533MB/s)(35.6GiB/71763msec); 0 zone resets
    slat (usec): min=444, max=3599, avg=1005.29, stdev=399.38
    clat (msec): min=8, max=633, avg=209.80, stdev=90.55
     lat (msec): min=10, max=633, avg=210.80, stdev=90.40
    clat percentiles (msec):
     |  1.00th=[   10],  5.00th=[  153], 10.00th=[  163], 20.00th=[  171],
     | 30.00th=[  176], 40.00th=[  182], 50.00th=[  186], 60.00th=[  192],
     | 70.00th=[  203], 80.00th=[  226], 90.00th=[  321], 95.00th=[  414],
     | 99.00th=[  575], 99.50th=[  600], 99.90th=[  625], 99.95th=[  634],
     | 99.99th=[  634]
   bw (  KiB/s): min=249660, max=3056831, per=100.00%, avg=624106.73, stdev=74202.92, samples=471
   iops        : min=    4, max=   91, avg=15.93, stdev= 2.33, samples=471
  lat (msec)   : 10=1.75%, 20=0.96%, 50=0.70%, 100=0.35%, 250=80.44%
  lat (msec)   : 500=13.68%, 750=2.11%
  cpu          : usr=0.39%, sys=0.02%, ctx=1298, majf=0, minf=4
  IO depths    : 1=100.4%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,1140,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=508MiB/s (533MB/s), 508MiB/s-508MiB/s (533MB/s-533MB/s), io=35.6GiB (38.3GB), run=71763-71763msec
```

# Main RAID array without SLOG

ZFS, 6x HDD RAID Z2 vdev, 3x SATA SSD mirror special

```log
root@truenas[/mnt/main/data/torrent-data]# fio --ioengine=posixaio --rw=randwrite --bs=32m --numjobs=4 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --size=1g --name=seq-write
seq-write: (g=0): rw=randwrite, bs=(R) 32.0MiB-32.0MiB, (W) 32.0MiB-32.0MiB, (T) 32.0MiB-32.0MiB, ioengine=posixaio, iodepth=1
...
fio-3.25
Starting 4 processes
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
Jobs: 4 (f=4): [F(4)][100.0%][eta 00m:00s]
seq-write: (groupid=0, jobs=1): err= 0: pid=1430626: Tue Jul  4 16:19:12 2023
  write: IOPS=0, BW=27.3MiB/s (28.6MB/s)(2304MiB/84546msec); 0 zone resets
    slat (usec): min=500, max=3021, avg=968.43, stdev=419.36
    clat (msec): min=14, max=1458, avg=836.89, stdev=361.43
     lat (msec): min=15, max=1459, avg=837.86, stdev=361.15
    clat percentiles (msec):
     |  1.00th=[   15],  5.00th=[   15], 10.00th=[   32], 20.00th=[  751],
     | 30.00th=[  894], 40.00th=[  978], 50.00th=[  986], 60.00th=[  986],
     | 70.00th=[ 1003], 80.00th=[ 1003], 90.00th=[ 1036], 95.00th=[ 1167],
     | 99.00th=[ 1452], 99.50th=[ 1452], 99.90th=[ 1452], 99.95th=[ 1452],
     | 99.99th=[ 1452]
   bw (  KiB/s): min=63258, max=655360, per=66.06%, avg=74987.23, stdev=74916.32, samples=62
   iops        : min=    1, max=   20, avg= 2.15, stdev= 2.33, samples=62
  lat (msec)   : 20=8.33%, 50=4.17%, 100=1.39%, 250=1.39%, 750=4.17%
  lat (msec)   : 1000=51.39%, 2000=29.17%
  cpu          : usr=0.08%, sys=0.00%, ctx=152, majf=0, minf=48
  IO depths    : 1=101.4%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,72,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
seq-write: (groupid=0, jobs=1): err= 0: pid=1430627: Tue Jul  4 16:19:12 2023
  write: IOPS=0, BW=28.0MiB/s (29.4MB/s)(2368MiB/84547msec); 0 zone resets
    slat (usec): min=496, max=1967, avg=922.50, stdev=245.84
    clat (msec): min=9, max=1441, avg=818.45, stdev=377.01
     lat (msec): min=11, max=1442, avg=819.37, stdev=376.85
    clat percentiles (msec):
     |  1.00th=[   11],  5.00th=[   13], 10.00th=[   15], 20.00th=[  743],
     | 30.00th=[  885], 40.00th=[  969], 50.00th=[  978], 60.00th=[  986],
     | 70.00th=[  995], 80.00th=[ 1011], 90.00th=[ 1028], 95.00th=[ 1133],
     | 99.00th=[ 1435], 99.50th=[ 1435], 99.90th=[ 1435], 99.95th=[ 1435],
     | 99.99th=[ 1435]
   bw (  KiB/s): min=63258, max=786432, per=67.89%, avg=77062.34, stdev=91567.79, samples=62
   iops        : min=    1, max=   24, avg= 2.19, stdev= 2.84, samples=62
  lat (msec)   : 10=1.35%, 20=9.46%, 50=2.70%, 100=1.35%, 250=1.35%
  lat (msec)   : 500=1.35%, 750=2.70%, 1000=55.41%, 2000=24.32%
  cpu          : usr=0.08%, sys=0.00%, ctx=156, majf=0, minf=47
  IO depths    : 1=101.4%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,74,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
seq-write: (groupid=0, jobs=1): err= 0: pid=1430628: Tue Jul  4 16:19:12 2023
  write: IOPS=0, BW=27.0MiB/s (29.4MB/s)(2368MiB/84578msec); 0 zone resets
    slat (usec): min=453, max=1898, avg=860.45, stdev=257.75
    clat (msec): min=13, max=1447, avg=819.60, stdev=378.35
     lat (msec): min=15, max=1448, avg=820.46, stdev=378.21
    clat percentiles (msec):
     |  1.00th=[   14],  5.00th=[   15], 10.00th=[   17], 20.00th=[  718],
     | 30.00th=[  902], 40.00th=[  978], 50.00th=[  986], 60.00th=[  995],
     | 70.00th=[  995], 80.00th=[ 1011], 90.00th=[ 1028], 95.00th=[ 1200],
     | 99.00th=[ 1452], 99.50th=[ 1452], 99.90th=[ 1452], 99.95th=[ 1452],
     | 99.99th=[ 1452]
   bw (  KiB/s): min=63258, max=784862, per=67.85%, avg=77016.53, stdev=91371.26, samples=62
   iops        : min=    1, max=   23, avg= 2.19, stdev= 2.71, samples=62
  lat (msec)   : 20=12.16%, 50=1.35%, 100=1.35%, 250=1.35%, 500=1.35%
  lat (msec)   : 750=4.05%, 1000=54.05%, 2000=24.32%
  cpu          : usr=0.08%, sys=0.00%, ctx=154, majf=0, minf=45
  IO depths    : 1=101.4%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,74,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
seq-write: (groupid=0, jobs=1): err= 0: pid=1430629: Tue Jul  4 16:19:12 2023
  write: IOPS=0, BW=27.6MiB/s (28.0MB/s)(2336MiB/84578msec); 0 zone resets
    slat (usec): min=519, max=2348, avg=913.09, stdev=287.12
    clat (msec): min=9, max=1436, avg=831.09, stdev=371.68
     lat (msec): min=11, max=1437, avg=832.00, stdev=371.49
    clat percentiles (msec):
     |  1.00th=[   10],  5.00th=[   15], 10.00th=[   21], 20.00th=[  760],
     | 30.00th=[  869], 40.00th=[  978], 50.00th=[  986], 60.00th=[  995],
     | 70.00th=[ 1003], 80.00th=[ 1020], 90.00th=[ 1036], 95.00th=[ 1167],
     | 99.00th=[ 1435], 99.50th=[ 1435], 99.90th=[ 1435], 99.95th=[ 1435],
     | 99.99th=[ 1435]
   bw (  KiB/s): min=63258, max=720896, per=66.95%, avg=76003.19, stdev=83245.07, samples=62
   iops        : min=    1, max=   22, avg= 2.15, stdev= 2.59, samples=62
  lat (msec)   : 10=1.37%, 20=8.22%, 50=4.11%, 250=2.74%, 750=2.74%
  lat (msec)   : 1000=52.05%, 2000=28.77%
  cpu          : usr=0.08%, sys=0.01%, ctx=138, majf=0, minf=45
  IO depths    : 1=101.4%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,73,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=111MiB/s (116MB/s), 27.3MiB/s-28.0MiB/s (28.6MB/s-29.4MB/s), io=9376MiB (9831MB), run=84546-84578msec
```

ZFS, Truenas Core:

```LOG
root@truenas[/mnt/main/data/torrent-data/test]# fio --ioengine=posixaio --rw=write --bs=32m --numjobs=4 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --size=1g --group_reporting --name=seq-write
seq-write: (g=0): rw=write, bs=(R) 32.0MiB-32.0MiB, (W) 32.0MiB-32.0MiB, (T) 32.0MiB-32.0MiB, ioengine=posixaio, iodepth=1
...
fio-3.28
Starting 4 processes
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
seq-write: Laying out IO file (1 file / 1024MiB)
Jobs: 3 (f=3): [F(3),_(1)][100.0%][eta 00m:00s]                  
seq-write: (groupid=0, jobs=4): err= 0: pid=3583: Tue Jul  4 11:45:42 2023
  write: IOPS=17, BW=557MiB/s (584MB/s)(35.4GiB/65193msec); 0 zone resets
    slat (usec): min=446, max=84476, avg=1169.15, stdev=2696.94
    clat (usec): min=4, max=884532, avg=210574.32, stdev=109324.97
     lat (msec): min=8, max=884, avg=211.74, stdev=108.91
    clat percentiles (msec):
     |  1.00th=[   12],  5.00th=[  153], 10.00th=[  163], 20.00th=[  169],
     | 30.00th=[  174], 40.00th=[  180], 50.00th=[  186], 60.00th=[  190],
     | 70.00th=[  199], 80.00th=[  213], 90.00th=[  288], 95.00th=[  468],
     | 99.00th=[  642], 99.50th=[  743], 99.90th=[  877], 99.95th=[  885],
     | 99.99th=[  885]
   bw (  KiB/s): min=253524, max=3241918, per=100.00%, avg=637554.11, stdev=80974.22, samples=458
   iops        : min=    4, max=   96, avg=15.91, stdev= 2.52, samples=458
  lat (usec)   : 10=0.97%
  lat (msec)   : 20=1.06%, 50=1.85%, 100=0.44%, 250=83.60%, 500=7.67%
  lat (msec)   : 750=4.06%, 1000=0.35%
  cpu          : usr=0.43%, sys=0.01%, ctx=1315, majf=0, minf=4
  IO depths    : 1=100.4%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,1134,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=557MiB/s (584MB/s), 557MiB/s-557MiB/s (584MB/s-584MB/s), io=35.4GiB (38.1GB), run=65193-65193msec
```

# NVMe Intel Optane M10 16GB MEMPEK1J016GAL

```log
root@truenas[/mnt/test-optane/1]# fio --ioengine=posixaio --rw=write --bs=32m --numjobs=4 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --size=1g --name=seq-write
seq-write: (g=0): rw=write, bs=(R) 32.0MiB-32.0MiB, (W) 32.0MiB-32.0MiB, (T) 32.0MiB-32.0MiB, ioengine=posixaio, iodepth=1
...
fio-3.25
Starting 4 processes
Jobs: 4 (f=4): [W(4)][100.0%][w=96.0MiB/s][w=3 IOPS][eta 00m:00s]
seq-write: (groupid=0, jobs=1): err= 0: pid=1728552: Tue Jul  4 16:30:10 2023
  write: IOPS=1, BW=38.1MiB/s (39.0MB/s)(2304MiB/60410msec); 0 zone resets
    slat (usec): min=537, max=1508, avg=867.94, stdev=145.94
    clat (msec): min=72, max=1354, avg=832.87, stdev=569.81
     lat (msec): min=73, max=1354, avg=833.74, stdev=569.82
    clat percentiles (msec):
     |  1.00th=[   73],  5.00th=[   74], 10.00th=[   79], 20.00th=[   82],
     | 30.00th=[   84], 40.00th=[ 1250], 50.00th=[ 1250], 60.00th=[ 1250],
     | 70.00th=[ 1250], 80.00th=[ 1267], 90.00th=[ 1267], 95.00th=[ 1267],
     | 99.00th=[ 1351], 99.50th=[ 1351], 99.90th=[ 1351], 99.95th=[ 1351],
     | 99.99th=[ 1351]
   bw (  KiB/s): min=65405, max=131072, per=59.36%, avg=91659.50, stdev=32326.39, samples=50
   iops        : min=    1, max=    4, avg= 2.68, stdev= 0.94, samples=50
  lat (msec)   : 100=36.11%, 2000=63.89%
  cpu          : usr=0.10%, sys=0.00%, ctx=74, majf=0, minf=46
  IO depths    : 1=101.4%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,72,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
seq-write: (groupid=0, jobs=1): err= 0: pid=1728553: Tue Jul  4 16:30:10 2023
  write: IOPS=1, BW=38.3MiB/s (40.1MB/s)(2304MiB/60190msec); 0 zone resets
    slat (usec): min=526, max=1974, avg=873.51, stdev=174.31
    clat (msec): min=72, max=1365, avg=832.71, stdev=569.75
     lat (msec): min=73, max=1366, avg=833.58, stdev=569.73
    clat percentiles (msec):
     |  1.00th=[   73],  5.00th=[   75], 10.00th=[   78], 20.00th=[   81],
     | 30.00th=[   86], 40.00th=[ 1250], 50.00th=[ 1250], 60.00th=[ 1250],
     | 70.00th=[ 1250], 80.00th=[ 1267], 90.00th=[ 1267], 95.00th=[ 1267],
     | 99.00th=[ 1368], 99.50th=[ 1368], 99.90th=[ 1368], 99.95th=[ 1368],
     | 99.99th=[ 1368]
   bw (  KiB/s): min=65145, max=131072, per=60.21%, avg=92965.74, stdev=32590.73, samples=50
   iops        : min=    1, max=    4, avg= 2.74, stdev= 1.01, samples=50
  lat (msec)   : 100=36.11%, 2000=63.89%
  cpu          : usr=0.11%, sys=0.00%, ctx=75, majf=0, minf=46
  IO depths    : 1=101.4%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,72,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
seq-write: (groupid=0, jobs=1): err= 0: pid=1728554: Tue Jul  4 16:30:10 2023
  write: IOPS=1, BW=37.5MiB/s (39.3MB/s)(2272MiB/60650msec); 0 zone resets
    slat (usec): min=576, max=1635, avg=850.46, stdev=153.12
    clat (msec): min=72, max=1366, avg=844.82, stdev=565.70
     lat (msec): min=73, max=1367, avg=845.67, stdev=565.70
    clat percentiles (msec):
     |  1.00th=[   73],  5.00th=[   77], 10.00th=[   79], 20.00th=[   84],
     | 30.00th=[   90], 40.00th=[ 1250], 50.00th=[ 1250], 60.00th=[ 1250],
     | 70.00th=[ 1250], 80.00th=[ 1267], 90.00th=[ 1267], 95.00th=[ 1267],
     | 99.00th=[ 1368], 99.50th=[ 1368], 99.90th=[ 1368], 99.95th=[ 1368],
     | 99.99th=[ 1368]
   bw (  KiB/s): min=64000, max=131072, per=57.37%, avg=88590.18, stdev=31590.88, samples=51
   iops        : min=    1, max=    4, avg= 2.61, stdev= 0.92, samples=51
  lat (msec)   : 100=35.21%, 2000=64.79%
  cpu          : usr=0.10%, sys=0.00%, ctx=75, majf=0, minf=46
  IO depths    : 1=101.4%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,71,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1
seq-write: (groupid=0, jobs=1): err= 0: pid=1728555: Tue Jul  4 16:30:10 2023
  write: IOPS=1, BW=37.8MiB/s (39.7MB/s)(2304MiB/60907msec); 0 zone resets
    slat (usec): min=529, max=1481, avg=861.33, stdev=137.78
    clat (msec): min=72, max=1358, avg=833.14, stdev=569.02
     lat (msec): min=73, max=1359, avg=834.00, stdev=569.04
    clat percentiles (msec):
     |  1.00th=[   73],  5.00th=[   75], 10.00th=[   80], 20.00th=[   83],
     | 30.00th=[   85], 40.00th=[ 1250], 50.00th=[ 1250], 60.00th=[ 1250],
     | 70.00th=[ 1250], 80.00th=[ 1267], 90.00th=[ 1267], 95.00th=[ 1267],
     | 99.00th=[ 1351], 99.50th=[ 1351], 99.90th=[ 1351], 99.95th=[ 1351],
     | 99.99th=[ 1351]
   bw (  KiB/s): min=64503, max=131072, per=56.82%, avg=87734.62, stdev=31314.02, samples=53
   iops        : min=    1, max=    4, avg= 2.57, stdev= 1.01, samples=53
  lat (msec)   : 100=36.11%, 2000=63.89%
  cpu          : usr=0.10%, sys=0.00%, ctx=73, majf=0, minf=47
  IO depths    : 1=101.4%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,72,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=151MiB/s (158MB/s), 37.5MiB/s-38.3MiB/s (39.3MB/s-40.1MB/s), io=9184MiB (9630MB), run=60190-60907msec
```
