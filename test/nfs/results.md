

# random 4k 100m

fio --size=100MB --direct=1 --rw=randrw   --bs=4k --ioengine=libaio --iodepth=1 --runtime=15 --numjobs=1 --time_based --group_reporting --name=iops-test-job --eta-newline=1 --filename=./fio-test-file

## nas boot-pool
bw (  KiB/s): min=267184, max=307160, per=100.00%, avg=291063.76, stdev=13130.84, samples=29
iops        : min=66796, max=76790, avg=72765.83, stdev=3282.69, samples=29
lat (nsec)   : 500=49.86%, 750=47.10%, 1000=2.37%
lat (usec)   : 2=0.62%, 4=0.01%, 10=0.02%, 20=0.01%, 50=0.01%
lat (usec)   : 100=0.01%, 250=0.01%, 1000=0.01%

## nas system-mount
bw (  KiB/s): min=  896, max=322688, per=100.00%, avg=263246.36, stdev=88246.80, samples=28
iops        : min=  224, max=80672, avg=65811.57, stdev=22061.69, samples=28
lat (nsec)   : 500=70.75%, 750=27.87%, 1000=1.16%
lat (usec)   : 2=0.19%, 4=0.01%, 10=0.01%, 20=0.01%, 50=0.01%
lat (usec)   : 100=0.01%

## nas main-pool
bw (  KiB/s): min=226812, max=301688, per=99.98%, avg=283597.72, stdev=18739.91, samples=29
iops        : min=56703, max=75422, avg=70899.38, stdev=4685.03, samples=29
lat (nsec)   : 500=49.05%, 750=48.35%, 1000=2.03%
lat (usec)   : 2=0.50%, 4=0.02%, 10=0.02%, 20=0.02%, 50=0.01%
lat (usec)   : 100=0.01%, 250=0.01%, 500=0.01%, 750=0.01%

## local proxmox
bw (  KiB/s): min=359008, max=389176, per=99.97%, avg=378067.59, stdev=9015.17, samples=29
iops        : min=89752, max=97294, avg=94516.90, stdev=2253.65, samples=29
lat (nsec)   : 500=92.12%, 750=7.32%, 1000=0.43%
lat (usec)   : 2=0.11%, 4=0.01%, 10=0.01%, 20=0.01%, 50=0.01%

## k8s worker
bw (  KiB/s): min=25240, max=34944, per=100.00%, avg=30963.31, stdev=2165.38, samples=29
iops        : min= 6310, max= 8736, avg=7740.83, stdev=541.35, samples=29
lat (nsec)   : 1000=0.01%
lat (usec)   : 2=0.01%, 4=0.01%, 20=0.01%, 50=63.07%, 100=36.27%
lat (usec)   : 250=0.55%, 500=0.06%, 750=0.01%, 1000=0.01%
lat (msec)   : 2=0.01%, 4=0.01%, 10=0.01%, 20=0.01%

## k8s master
bw (  KiB/s): min=22200, max=35504, per=100.00%, avg=30488.90, stdev=3386.72, samples=29
iops        : min= 5550, max= 8876, avg=7622.21, stdev=846.68, samples=29
lat (nsec)   : 1000=0.01%
lat (usec)   : 2=0.07%, 4=0.04%, 10=0.01%, 20=0.04%, 50=65.49%
lat (usec)   : 100=32.93%, 250=1.22%, 500=0.12%, 750=0.03%, 1000=0.02%
lat (msec)   : 2=0.02%, 4=0.01%, 10=0.01%, 20=0.01%, 50=0.01%

## local k8s pod
bw (  KiB/s): min=26712, max=34232, per=100.00%, avg=30751.45, stdev=1884.04, samples=29
iops        : min= 6678, max= 8558, avg=7687.86, stdev=471.01, samples=29
lat (nsec)   : 750=0.01%, 1000=0.01%
lat (usec)   : 2=0.01%, 4=0.01%, 10=0.01%, 20=0.01%, 50=64.82%
lat (usec)   : 100=34.66%, 250=0.44%, 500=0.03%, 750=0.01%, 1000=0.01%
lat (msec)   : 2=0.01%, 4=0.01%, 10=0.01%, 50=0.01%

## nfs 64k nc 16t
bw (  KiB/s): min= 4952, max= 6648, per=99.90%, avg=6068.14, stdev=445.96, samples=29
iops        : min= 1238, max= 1662, avg=1517.03, stdev=111.49, samples=29
lat (usec)   : 250=44.52%, 500=53.33%, 750=1.78%, 1000=0.12%
lat (msec)   : 2=0.19%, 4=0.03%, 10=0.03%, 20=0.01%, 50=0.01%

## nfs 64k nc 160t
bw (  KiB/s): min= 4152, max= 6640, per=100.00%, avg=6022.62, stdev=493.12, samples=29
iops        : min= 1038, max= 1660, avg=1505.66, stdev=123.28, samples=29
lat (usec)   : 250=43.26%, 500=54.37%, 750=2.07%, 1000=0.09%
lat (msec)   : 2=0.12%, 4=0.05%, 10=0.02%, 20=0.01%, 50=0.01%

## nfs 64k cached 16t
bw (  KiB/s): min= 4880, max= 6744, per=100.00%, avg=6170.21, stdev=420.31, samples=29
iops        : min= 1220, max= 1686, avg=1542.55, stdev=105.08, samples=29
lat (usec)   : 250=45.16%, 500=53.02%, 750=1.39%, 1000=0.18%
lat (msec)   : 2=0.19%, 4=0.03%, 10=0.03%, 50=0.01%


# random 4k 100m read-only

fio              --direct=1 --rw=randread --bs=4k --ioengine=libaio --iodepth=1 --runtime=15 --numjobs=1 --time_based --group_reporting --name=iops-test-job --eta-newline=1 --readonly --filename=./fio-test-file

## prox local
bw (  KiB/s): min=208096, max=1095424, per=99.96%, avg=1040105.93, stdev=161520.55, samples=29
iops        : min=52024, max=273856, avg=260026.41, stdev=40380.12, samples=29
lat (nsec)   : 500=93.99%, 750=5.68%, 1000=0.22%
lat (usec)   : 2=0.09%, 4=0.01%, 10=0.01%, 20=0.01%, 50=0.01%

## k8s worker
bw (  KiB/s): min=56944, max=76680, per=100.00%, avg=68369.93, stdev=3963.80, samples=29
iops        : min=14236, max=19170, avg=17092.48, stdev=990.95, samples=29
lat (nsec)   : 1000=0.01%
lat (usec)   : 2=0.01%, 20=0.01%, 50=81.79%, 100=18.13%, 250=0.07%
lat (usec)   : 500=0.01%, 750=0.01%, 1000=0.01%
lat (msec)   : 2=0.01%, 4=0.01%, 10=0.01%

## k8s pod local
bw (  KiB/s): min=55344, max=72872, per=100.00%, avg=68159.17, stdev=3257.77, samples=29
iops        : min=13836, max=18218, avg=17039.79, stdev=814.44, samples=29
lat (nsec)   : 750=0.01%, 1000=0.01%
lat (usec)   : 2=0.01%, 4=0.01%, 10=0.01%, 20=0.01%, 50=85.02%
lat (usec)   : 100=14.82%, 250=0.10%, 500=0.02%, 750=0.01%, 1000=0.01%
lat (msec)   : 2=0.01%, 4=0.01%, 10=0.01%

## nfs 64k cached 16t
bw (  KiB/s): min=16808, max=19024, per=99.99%, avg=17978.34, stdev=485.14, samples=29
iops        : min= 4202, max= 4756, avg=4494.59, stdev=121.28, samples=29
lat (usec)   : 250=95.62%, 500=4.26%, 750=0.05%, 1000=0.02%
lat (msec)   : 2=0.03%, 4=0.01%, 10=0.01%

1. Почитать про proxmox hook scripts
2. Найти как переместить рут кубернетиса в шару
3. Настроить автоматическую шару




# Выводы

Нативная производительность zfs volume девайсов на чтение составляет 5-10к IOPS в один поток.
Производительность ZFS поверх volume в truenas составляет 50-100к IOPS, как на чтение, так и на запись.
Очевидно, используется какое-то кэширование.
В ебунте что бы я ни делал, производительность на запись составляет 7-8к IOPS на запись и чуть больше на чтение.
Я не понимаю, что с этим еще можно сделать, так что можно забить хуй и пользоваться как есть.


