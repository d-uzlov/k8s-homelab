
# Run test

https://arstechnica.com/gadgets/2020/02/how-fast-are-your-disks-find-out-the-open-source-way-with-fio/

```bash
# test on a filesystem
fio --ioengine=posixaio --rw=randwrite --bs=4k --numjobs=1 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --name=random-write --size=4g
# test on a device
fio --ioengine=posixaio --rw=randwrite --bs=4k --numjobs=1 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --name=random-write --filename=/dev/nvme0n1
```

# Main RAID array

ZFS, 6x HDD RAID Z2 vdev, 3x SATA SSD mirror special, 1x NVMe Optane SLOG

Truenas Core:

```log
root@truenas[/mnt/main/data/torrent-data/test]# fio --ioengine=posixaio --rw=randwrite --bs=4k --numjobs=1 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --name=random-write --size=4g
random-write: (g=0): rw=randwrite, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=posixaio, iodepth=1
fio-3.28
Starting 1 process
random-write: Laying out IO file (1 file / 4096MiB)
Jobs: 1 (f=1): [F(1)][100.0%][w=2462KiB/s][w=615 IOPS][eta 00m:00s]
random-write: (groupid=0, jobs=1): err= 0: pid=16413: Wed Jul  5 06:30:48 2023
  write: IOPS=786, BW=3147KiB/s (3222kB/s)(188MiB/61029msec); 0 zone resets
    slat (nsec): min=1120, max=358438, avg=5976.22, stdev=4334.80
    clat (nsec): min=719, max=13528k, avg=1240309.01, stdev=658102.61
     lat (usec): min=10, max=13539, avg=1246.29, stdev=658.30
    clat percentiles (usec):
     |  1.00th=[  127],  5.00th=[  840], 10.00th=[  873], 20.00th=[  930],
     | 30.00th=[  988], 40.00th=[ 1045], 50.00th=[ 1106], 60.00th=[ 1172],
     | 70.00th=[ 1287], 80.00th=[ 1418], 90.00th=[ 1762], 95.00th=[ 2180],
     | 99.00th=[ 3589], 99.50th=[ 4359], 99.90th=[10945], 99.95th=[11600],
     | 99.99th=[11994]
   bw (  KiB/s): min=  678, max=14661, per=100.00%, avg=3211.05, stdev=1334.38, samples=117
   iops        : min=  169, max= 3665, avg=802.43, stdev=333.58, samples=117
  lat (nsec)   : 750=0.01%, 1000=0.01%
  lat (usec)   : 2=0.01%, 10=0.01%, 20=0.01%, 50=0.26%, 100=0.19%
  lat (usec)   : 250=2.19%, 500=0.69%, 750=0.46%, 1000=28.66%
  lat (msec)   : 2=61.01%, 4=5.84%, 10=0.54%, 20=0.12%
  cpu          : usr=0.50%, sys=0.81%, ctx=48449, majf=0, minf=1
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,48012,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=3147KiB/s (3222kB/s), 3147KiB/s-3147KiB/s (3222kB/s-3222kB/s), io=188MiB (197MB), run=61029-61029msec
```

# Main RAID array without SLOG

ZFS, 6x HDD RAID Z2 vdev, 3x SATA SSD mirror special

```log
root@truenas[/mnt/main/data/torrent-data]# fio --ioengine=posixaio --rw=randwrite --bs=4k --numjobs=1 --size=4g --iodepth=1 --runtime=60 --time_based --end_fsync=1 --name=random-write  
random-write: (g=0): rw=randwrite, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=posixaio, iodepth=1
fio-3.25
Starting 1 process
random-write: Laying out IO file (1 file / 4096MiB)
Jobs: 1 (f=1): [w(1)][100.0%][w=6728KiB/s][w=1682 IOPS][eta 00m:00s]
random-write: (groupid=0, jobs=1): err= 0: pid=1360825: Tue Jul  4 15:57:20 2023
  write: IOPS=2322, BW=9290KiB/s (9513kB/s)(545MiB/60119msec); 0 zone resets
    slat (nsec): min=490, max=7309.3k, avg=4647.89, stdev=23512.86
    clat (nsec): min=1620, max=92360k, avg=422744.69, stdev=581284.79
     lat (usec): min=15, max=92364, avg=427.39, stdev=582.02
    clat percentiles (usec):
     |  1.00th=[   24],  5.00th=[   36], 10.00th=[   81], 20.00th=[  239],
     | 30.00th=[  314], 40.00th=[  367], 50.00th=[  416], 60.00th=[  457],
     | 70.00th=[  502], 80.00th=[  553], 90.00th=[  635], 95.00th=[  734],
     | 99.00th=[ 1106], 99.50th=[ 1582], 99.90th=[ 5407], 99.95th=[ 8291],
     | 99.99th=[25560]
   bw (  KiB/s): min= 6179, max=19832, per=100.00%, avg=9325.47, stdev=2327.69, samples=119
   iops        : min= 1544, max= 4958, avg=2331.24, stdev=581.94, samples=119
  lat (usec)   : 2=0.01%, 4=0.01%, 20=0.55%, 50=8.50%, 100=1.14%
  lat (usec)   : 250=11.13%, 500=48.70%, 750=25.56%, 1000=3.13%
  lat (msec)   : 2=0.95%, 4=0.20%, 10=0.11%, 20=0.02%, 50=0.02%
  lat (msec)   : 100=0.01%
  cpu          : usr=1.64%, sys=1.41%, ctx=171700, majf=0, minf=45
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,139625,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=9290KiB/s (9513kB/s), 9290KiB/s-9290KiB/s (9513kB/s-9513kB/s), io=545MiB (572MB), run=60119-60119msec
```

Truenas Core:

```log
root@truenas[/mnt/main/data/torrent-data/test]# fio --ioengine=posixaio --rw=randwrite --bs=4k --numjobs=1 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --name=random-write --size=4g  
random-write: (g=0): rw=randwrite, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=posixaio, iodepth=1
fio-3.28
Starting 1 process
random-write: Laying out IO file (1 file / 4096MiB)
Jobs: 1 (f=1): [F(1)][100.0%][w=212KiB/s][w=53 IOPS][eta 00m:00s]  
random-write: (groupid=0, jobs=1): err= 0: pid=3081: Tue Jul  4 11:00:16 2023
  write: IOPS=775, BW=3103KiB/s (3178kB/s)(187MiB/61757msec); 0 zone resets
    slat (nsec): min=1020, max=1654.1k, avg=6760.61, stdev=19778.02
    clat (nsec): min=710, max=12114k, avg=1242305.78, stdev=672595.43
     lat (usec): min=8, max=12121, avg=1249.07, stdev=671.82
    clat percentiles (usec):
     |  1.00th=[  116],  5.00th=[  824], 10.00th=[  865], 20.00th=[  930],
     | 30.00th=[  988], 40.00th=[ 1057], 50.00th=[ 1123], 60.00th=[ 1188],
     | 70.00th=[ 1287], 80.00th=[ 1418], 90.00th=[ 1713], 95.00th=[ 2212],
     | 99.00th=[ 3752], 99.50th=[ 4817], 99.90th=[ 8848], 99.95th=[11469],
     | 99.99th=[11600]
   bw (  KiB/s): min=  594, max=15321, per=100.00%, avg=3199.19, stdev=1386.84, samples=118
   iops        : min=  148, max= 3830, avg=799.47, stdev=346.72, samples=118
  lat (nsec)   : 750=0.01%, 1000=0.30%
  lat (usec)   : 2=0.14%, 4=0.01%, 10=0.01%, 20=0.04%, 50=0.11%
  lat (usec)   : 100=0.02%, 250=2.06%, 500=0.69%, 750=0.70%, 1000=27.66%
  lat (msec)   : 2=61.78%, 4=5.68%, 10=0.72%, 20=0.09%
  cpu          : usr=0.34%, sys=0.91%, ctx=48578, majf=0, minf=1
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,47911,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=3103KiB/s (3178kB/s), 3103KiB/s-3103KiB/s (3178kB/s-3178kB/s), io=187MiB (196MB), run=61757-61757msec
```

# NVMe Intel Optane M10 16GB MEMPEK1J016GAL

```log
root@truenas[/mnt/test-optane/1]# fio --ioengine=posixaio --rw=randwrite --bs=4k --numjobs=1 --size=4g --iodepth=1 --runtime=60 --time_based --end_fsync=1 --name=random-write
random-write: (g=0): rw=randwrite, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=posixaio, iodepth=1
fio-3.25
Starting 1 process
random-write: Laying out IO file (1 file / 4096MiB)
Jobs: 1 (f=1): [w(1)][100.0%][w=85.8MiB/s][w=21.0k IOPS][eta 00m:00s]
random-write: (groupid=0, jobs=1): err= 0: pid=1249265: Tue Jul  4 15:54:13 2023
  write: IOPS=15.7k, BW=61.2MiB/s (64.2MB/s)(3716MiB/60690msec); 0 zone resets
    slat (nsec): min=490, max=958794, avg=3320.53, stdev=3265.25
    clat (nsec): min=320, max=1564.5M, avg=58700.14, stdev=4615533.38
     lat (usec): min=17, max=1564.5k, avg=62.02, stdev=4615.54
    clat percentiles (usec):
     |  1.00th=[   21],  5.00th=[   29], 10.00th=[   31], 20.00th=[   34],
     | 30.00th=[   37], 40.00th=[   38], 50.00th=[   39], 60.00th=[   40],
     | 70.00th=[   42], 80.00th=[   44], 90.00th=[   47], 95.00th=[   52],
     | 99.00th=[   72], 99.50th=[  122], 99.90th=[  265], 99.95th=[  322],
     | 99.99th=[ 1012]
   bw (  KiB/s): min= 1168, max=100568, per=100.00%, avg=73816.54, stdev=26617.56, samples=102
   iops        : min=  292, max=25142, avg=18454.12, stdev=6654.38, samples=102
  lat (nsec)   : 500=0.01%
  lat (usec)   : 2=0.01%, 20=0.47%, 50=93.56%, 100=5.37%, 250=0.49%
  lat (usec)   : 500=0.09%, 750=0.01%, 1000=0.01%
  lat (msec)   : 2=0.01%, 4=0.01%, 10=0.01%, 20=0.01%, 50=0.01%
  lat (msec)   : 500=0.01%, 750=0.01%, 1000=0.01%, 2000=0.01%
  cpu          : usr=7.79%, sys=7.05%, ctx=1016186, majf=2, minf=46
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,951406,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=61.2MiB/s (64.2MB/s), 61.2MiB/s-61.2MiB/s (64.2MB/s-64.2MB/s), io=3716MiB (3897MB), run=60690-60690msec
```

Truenas Core:

```log
root@truenas[/mnt/test-optane/1]# fio --ioengine=posixaio --rw=randwrite --bs=4k --numjobs=1 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --name=random-write --size=4g
random-write: (g=0): rw=randwrite, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=posixaio, iodepth=1
fio-3.28
Starting 1 process
random-write: Laying out IO file (1 file / 4096MiB)
Jobs: 1 (f=1): [F(1)][100.0%][w=3KiB/s][w=0 IOPS][eta 00m:00s]       
random-write: (groupid=0, jobs=1): err= 0: pid=2055: Tue Jul  4 08:44:38 2023
  write: IOPS=22.0k, BW=86.0MiB/s (90.2MB/s)(5249MiB/61015msec); 0 zone resets
    slat (nsec): min=820, max=2236.0k, avg=2805.72, stdev=6111.21
    clat (nsec): min=500, max=1172.3M, avg=41078.37, stdev=4706686.20
     lat (usec): min=6, max=1172.3k, avg=43.88, stdev=4706.68
    clat percentiles (nsec):
     |  1.00th=[   740],  5.00th=[   804], 10.00th=[  7264], 20.00th=[  8384],
     | 30.00th=[  8640], 40.00th=[  9024], 50.00th=[  9920], 60.00th=[ 10304],
     | 70.00th=[ 10560], 80.00th=[ 11072], 90.00th=[ 13504], 95.00th=[ 18304],
     | 99.00th=[ 43776], 99.50th=[ 60160], 99.90th=[109056], 99.95th=[214016],
     | 99.99th=[468992]
   bw (  KiB/s): min=  917, max=286452, per=100.00%, avg=113732.68, stdev=67586.59, samples=93
   iops        : min=  229, max=71613, avg=28432.77, stdev=16896.69, samples=93
  lat (nsec)   : 750=1.55%, 1000=5.44%
  lat (usec)   : 2=1.96%, 4=0.35%, 10=43.48%, 20=43.12%, 50=3.30%
  lat (usec)   : 100=0.68%, 250=0.07%, 500=0.03%, 750=0.01%, 1000=0.01%
  lat (msec)   : 2=0.01%, 4=0.01%, 250=0.01%, 500=0.01%, 750=0.01%
  lat (msec)   : 1000=0.01%, 2000=0.01%
  cpu          : usr=5.58%, sys=6.58%, ctx=1389571, majf=0, minf=1
  IO depths    : 1=100.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,1343860,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=86.0MiB/s (90.2MB/s), 86.0MiB/s-86.0MiB/s (90.2MB/s-90.2MB/s), io=5249MiB (5504MB), run=61015-61015msec
```
