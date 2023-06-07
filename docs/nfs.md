
# cachefilesd

https://www.admin-magazine.com/HPC/Articles/Caching-with-CacheFS

According to the online Red Hat 7 documentation, you need to follow just a couple of rules in setting the caching parameters:
0 ≤ bstop < bcull < brun < 100
0 ≤ fstop < fcull < frun < 100

nano /etc/cachefilesd.conf

# uncomment RUN=yes
nano /etc/default/cachefilesd

sudo systemctl restart cachefilesd
sudo systemctl status cachefilesd

# stats
cat /proc/fs/fscache/stats
ls /var/cache/fscache
cat /proc/fs/nfsfs/servers
cat /proc/fs/nfsfs/volumes

# Cache size
sudo du -sh /var/cache/fscache/

# NFS thread count statistics:
https://support.hpe.com/hpesc/public/docDisplay?docId=emr_na-c02239048

# nfs mount options

https://www.thegeekdiary.com/common-nfs-mount-options-in-linux/
https://learn.microsoft.com/en-us/azure/azure-netapp-files/performance-linux-mount-options
https://docs.aws.amazon.com/efs/latest/ug/mounting-fs-nfs-mount-settings.html
https://linux.die.net/man/5/nfs

# read-ahead

https://learn.microsoft.com/en-us/azure/azure-netapp-files/performance-linux-nfs-read-ahead
