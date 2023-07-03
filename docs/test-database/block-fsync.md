
# Run test

https://www.ibm.com/cloud/blog/using-fio-to-tell-whether-your-storage-is-fast-enough-for-etcd

```bash
# test on a filesystem
fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --directory=test-data
# test raw device
fio --rw=write --ioengine=sync --fdatasync=1 --size=22m --bs=4k --name=mytest --filename=/dev/nvme0n1
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

# SATA TEAM T253X2512G 500GB TPBF2206080010103840

ZFS, block 2300:

```log
root@truenas[/mnt/test-3]# fio --rw=write --ioengine=sync --fdatasync=1 --directory=test-data --size=22m --bs=2300 --name=mytest
mytest: (g=0): rw=write, bs=(R) 2300B-2300B, (W) 2300B-2300B, (T) 2300B-2300B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1): [W(1)][100.0%][w=2201KiB/s][w=979 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=2805037: Sun Jun 25 21:35:02 2023
  write: IOPS=980, BW=2202KiB/s (2255kB/s)(21.0MiB/10230msec); 0 zone resets
    clat (nsec): min=10270, max=88294, avg=17759.90, stdev=6629.40
     lat (nsec): min=10510, max=88654, avg=18077.21, stdev=6680.55
    clat percentiles (nsec):
     |  1.00th=[11968],  5.00th=[12224], 10.00th=[12352], 20.00th=[13120],
     | 30.00th=[13632], 40.00th=[14528], 50.00th=[16512], 60.00th=[19072],
     | 70.00th=[20352], 80.00th=[20608], 90.00th=[21632], 95.00th=[25984],
     | 99.00th=[49408], 99.50th=[58112], 99.90th=[64768], 99.95th=[70144],
     | 99.99th=[79360]
   bw (  KiB/s): min= 1972, max= 2286, per=100.00%, avg=2202.60, stdev=65.72, samples=20
   iops        : min=  878, max= 1018, avg=980.80, stdev=29.25, samples=20
  lat (usec)   : 20=64.53%, 50=34.57%, 100=0.90%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=431, max=19624, avg=999.15, stdev=553.03
    sync percentiles (usec):
     |  1.00th=[  453],  5.00th=[  469], 10.00th=[  478], 20.00th=[  490],
     | 30.00th=[  498], 40.00th=[  515], 50.00th=[ 1418], 60.00th=[ 1450],
     | 70.00th=[ 1467], 80.00th=[ 1483], 90.00th=[ 1500], 95.00th=[ 1532],
     | 99.00th=[ 1663], 99.50th=[ 1729], 99.90th=[ 1958], 99.95th=[ 2704],
     | 99.99th=[13960]
  cpu          : usr=0.90%, sys=5.71%, ctx=20058, majf=0, minf=13
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,10029,0,0 short=10029,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=2202KiB/s (2255kB/s), 2202KiB/s-2202KiB/s (2255kB/s-2255kB/s), io=21.0MiB (23.1MB), run=10230-10230msec
```

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
