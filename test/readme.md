
# Test random read IOPS of a device

https://docs.oracle.com/en-us/iaas/Content/Block/References/samplefiocommandslinux.htm

```bash
fio --direct=1 --rw=randread --bs=4k --ioengine=libaio --iodepth=1 --runtime=120 --numjobs=4 --time_based --group_reporting --name=iops-test-job --eta-newline=1 --readonly --filename=/path

fio --size=100MB --direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=1 --runtime=15 --numjobs=1 --time_based --group_reporting --name=iops-test-job --eta-newline=1 --filename=/var/www/html/fio-test-file
fio --size=100MB --direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=1 --runtime=15 --numjobs=1 --time_based --group_reporting --name=iops-test-job --eta-newline=1 --filename=/var/fio-test-file
fio --size=100MB --direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=1 --runtime=15 --numjobs=1 --time_based --group_reporting --name=iops-test-job --eta-newline=1 --filename=./fio-test-file
```
