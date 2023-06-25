
# Run test

```bash
fio --rw=write --ioengine=sync --fdatasync=1 --directory=test-data --size=22m --bs=2300 --name=mytest
```

# TESLA 2TB 2022092T0075

```log
root@truenas[/mnt/test-2]# fio --rw=write --ioengine=sync --fdatasync=1 --directory=test-data --size=22m --bs=2300 --name=mytest
mytest: (g=0): rw=write, bs=(R) 2300B-2300B, (W) 2300B-2300B, (T) 2300B-2300B, ioengine=sync, iodepth=1
fio-3.25
Starting 1 process
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1): [W(1)][100.0%][w=5371KiB/s][w=2391 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=2146840: Sun Jun 25 15:26:05 2023
  write: IOPS=2324, BW=5222KiB/s (5347kB/s)(21.0MiB/4314msec); 0 zone resets
    clat (usec): min=9, max=262, avg=13.43, stdev= 9.64
     lat (usec): min=9, max=262, avg=13.67, stdev= 9.65
    clat percentiles (usec):
     |  1.00th=[   11],  5.00th=[   12], 10.00th=[   12], 20.00th=[   12],
     | 30.00th=[   12], 40.00th=[   12], 50.00th=[   13], 60.00th=[   13],
     | 70.00th=[   13], 80.00th=[   14], 90.00th=[   14], 95.00th=[   15],
     | 99.00th=[   40], 99.50th=[   42], 99.90th=[  221], 99.95th=[  227],
     | 99.99th=[  243]
   bw (  KiB/s): min= 5067, max= 5377, per=99.99%, avg=5221.88, stdev=113.82, samples=8
   iops        : min= 2256, max= 2394, avg=2325.00, stdev=50.68, samples=8
  lat (usec)   : 10=0.38%, 20=96.73%, 50=2.66%, 100=0.06%, 250=0.16%
  lat (usec)   : 500=0.01%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=379, max=4126, avg=414.31, stdev=60.77
    sync percentiles (usec):
     |  1.00th=[  388],  5.00th=[  392], 10.00th=[  396], 20.00th=[  400],
     | 30.00th=[  404], 40.00th=[  408], 50.00th=[  412], 60.00th=[  416],
     | 70.00th=[  416], 80.00th=[  420], 90.00th=[  429], 95.00th=[  437],
     | 99.00th=[  457], 99.50th=[  478], 99.90th=[ 1221], 99.95th=[ 1369],
     | 99.99th=[ 3130]
  cpu          : usr=0.39%, sys=11.66%, ctx=20079, majf=8, minf=14
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,10029,0,0 short=10029,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=5222KiB/s (5347kB/s), 5222KiB/s-5222KiB/s (5347kB/s-5347kB/s), io=21.0MiB (23.1MB), run=4314-4314msec
```

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

# TEAM T253X2512G 500GB TPBF2206080010103840

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

# Samsung 970 EVO 1TB

```log
C:\Users\danil\Documents\k8s-public-copy>fio --rw=write --ioengine=sync --fdatasync=1 --directory=test-data --size=22m --bs=2300 --name=mytest
fio: this platform does not support process shared mutexes, forcing use of threads. Use the 'thread' option to get rid of this warning.
mytest: (g=0): rw=write, bs=(R) 2300B-2300B, (W) 2300B-2300B, (T) 2300B-2300B, ioengine=sync, iodepth=1
fio-3.35
Starting 1 thread
mytest: Laying out IO file (1 file / 22MiB)
Jobs: 1 (f=1): [W(1)][100.0%][w=2037KiB/s][w=907 IOPS][eta 00m:00s]
mytest: (groupid=0, jobs=1): err= 0: pid=39580: Sun Jun 25 21:43:33 2023
  write: IOPS=895, BW=2011KiB/s (2060kB/s)(22.0MiB/11200msec); 0 zone resets
    clat (usec): min=4, max=173, avg=11.44, stdev=12.47
     lat (usec): min=4, max=173, avg=11.62, stdev=12.47
    clat percentiles (usec):
     |  1.00th=[    6],  5.00th=[    7], 10.00th=[    7], 20.00th=[    7],
     | 30.00th=[    8], 40.00th=[    8], 50.00th=[    8], 60.00th=[    9],
     | 70.00th=[    9], 80.00th=[   10], 90.00th=[   13], 95.00th=[   42],
     | 99.00th=[   67], 99.50th=[   78], 99.90th=[  106], 99.95th=[  118],
     | 99.99th=[  137]
   bw (  KiB/s): min= 1393, max= 2156, per=100.00%, avg=2013.27, stdev=156.70, samples=22
   iops        : min=  620, max=  960, avg=896.36, stdev=69.87, samples=22
  lat (usec)   : 10=83.14%, 20=7.93%, 50=5.68%, 100=3.13%, 250=0.12%
  fsync/fdatasync/sync_file_range:
    sync (usec): min=882, max=61702, avg=1103.42, stdev=886.12
    sync percentiles (usec):
     |  1.00th=[  955],  5.00th=[  979], 10.00th=[  988], 20.00th=[ 1004],
     | 30.00th=[ 1020], 40.00th=[ 1029], 50.00th=[ 1045], 60.00th=[ 1057],
     | 70.00th=[ 1074], 80.00th=[ 1090], 90.00th=[ 1123], 95.00th=[ 1156],
     | 99.00th=[ 3916], 99.50th=[ 3982], 99.90th=[ 4178], 99.95th=[ 4293],
     | 99.99th=[38011]
  cpu          : usr=0.00%, sys=0.00%, ctx=0, majf=0, minf=0
  IO depths    : 1=200.0%, 2=0.0%, 4=0.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=0,10029,0,0 short=10029,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=1

Run status group 0 (all jobs):
  WRITE: bw=2011KiB/s (2060kB/s), 2011KiB/s-2011KiB/s (2060kB/s-2060kB/s), io=22.0MiB (23.1MB), run=11200-11200msec
```
