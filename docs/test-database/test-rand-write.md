
# Run test

https://arstechnica.com/gadgets/2020/02/how-fast-are-your-disks-find-out-the-open-source-way-with-fio/

```bash
# test on a filesystem
fio --ioengine=posixaio --rw=randwrite --bs=4k --numjobs=1 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --name=random-write --size=4g
# test on a device
fio --ioengine=posixaio --rw=randwrite --bs=4k --numjobs=1 --iodepth=1 --runtime=60 --time_based --end_fsync=1 --name=random-write --filename=/dev/nvme0n1
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
