
Source:
https://virtio-fs.gitlab.io/howto-qemu.html

1. Run virtio binary

/usr/lib/kvm/virtiofsd --socket-path=/run/qemu-server/104-test.virtiofsd -o source=/root/virtio-fs-test -o cache=always
/usr/lib/kvm/virtiofsd --socket-path=/run/qemu-server/104-test.virtiofsd -o source=/root/virtio-fs-test -o cache=always --daemonize > /dev/null 2>&1 &

2. Add qemu args:

nano /etc/pve/qemu-server/104.conf

args: -chardev socket,id=char0,path=/run/qemu-server/104-test.virtiofsd -device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=virtio-fs-test -m 4G -object memory-backend-file,id=mem,size=4G,mem-path=/dev/shm,share=on -numa node,memdev=mem

3. mount inside VM

sudo mkdir /mnt/virtio-fs-test
sudo mount -t virtiofs virtio-fs-test /mnt/virtio-fs-test

4. test

fio --size=100MB --direct=1 --rw=randrw   --bs=4k --ioengine=libaio --iodepth=1 --runtime=15 --numjobs=1 --time_based --group_reporting --name=iops-test-job --eta-newline=1 --filename=/mnt/virtio-fs-test/fio-test-file

bw (  KiB/s): min=31232, max=39392, per=99.39%, avg=35596.69, stdev=1782.52, samples=29
iops        : min= 7808, max= 9848, avg=8899.10, stdev=445.69, samples=29
lat (nsec)   : 750=0.01%
lat (usec)   : 2=0.01%, 10=0.01%, 20=0.02%, 50=96.77%, 100=3.09%
lat (usec)   : 250=0.11%, 500=0.01%, 750=0.01%, 1000=0.01%
lat (msec)   : 2=0.01%, 10=0.01%

fio              --direct=1 --rw=randread --bs=4k --ioengine=libaio --iodepth=1 --runtime=15 --numjobs=1 --time_based --group_reporting --name=iops-test-job --eta-newline=1 --readonly --filename=/mnt/virtio-fs-test/fio-test-file

bw (  KiB/s): min=80304, max=119408, per=99.87%, avg=92588.14, stdev=7848.94, samples=29
iops        : min=20076, max=29852, avg=23147.03, stdev=1962.24, samples=29
lat (nsec)   : 750=0.01%, 1000=0.01%
lat (usec)   : 2=0.02%, 4=0.01%, 10=0.01%, 20=0.35%, 50=98.61%
lat (usec)   : 100=0.99%, 250=0.02%, 500=0.01%, 750=0.01%, 1000=0.01%


## alt

Source:
https://the-b.org/proxmox/

1. Create `/var/lib/vz/snippets/exec-cmds` with the following contents:

exec-cmds.sh

2. Add a comment to the top of the config to each VM that needs it under /etc/pve/qemu-server/<VMID>.conf. It denotes the directory from the local machine to share.

```bash
#virtiofsd /media
```

3. Add args option to proxmox conf file:

args: -chardev socket,id=char0,path=/run/qemu-server/101-media.virtiofsd -device vhost-user-fs-pci,queue-size=1024,chardev=char0,tag=/media -object memory-backend-file,id=mem,size=4G,mem-path=/dev/shm,share=on -numa node,memdev=mem

# path=/run/qemu-server/101-media.virtiofsd -- '101' should be changed to match the VMID and 'media' should be changed to match the shared directory name without slashes.
# size=4G -- should be changed to be equal to the VM's RAM size
# tag=/media  -- this is used by the VM to mount the correct virtiofs share

## fstab

https://www.reddit.com/r/Proxmox/comments/qq99l0/does_proxmox_have_virtiofs_support/?sort=confidence

This is the line in VM's fstab :

data-servers /mnt/data-servers virtiofs rw,nosuid,nodev 0 0

data-servers is the tag, /mnt/data-servers the mount point in the VM


# hubepages

/dev/shm can be replaced with /dev/hugepages

Need to read more about huge pages



# proxmox snippets guide

```bash
#snippets folder didn't exist so I created it
mkdir /var/lib/vz/snippets

#Copied the template to the folder
cp /usr/share/pve-docs/examples/guest-example-hookscript.pl /var/lib/vz/snippets/secon-hookscript.pl

#modified the perl script with the applicable commands
nano /var/lib/vz/snippets/secon-hookscript.pl

# Made it executable
chmod +x /var/lib/vz/snippets/secon-hookscript.pl

#Set it to the applicable VM
qm set 102 --hookscript local:snippets/secon-hookscript.pl
```

Currently it's only possible to add a hookscript via CLI.
hookscripts have to be on a 'snippets'-capable storage.
All you have to do is create a script in the snippets directory
(for the default 'local' storage it is /var/lib/vz/snippets),
but subdirectories are not supported.

Choose whatever name fits the file and add it via 'qm set --hookscript <storage>:snippets/<file>'. The same applies to containers and 'pct'.



