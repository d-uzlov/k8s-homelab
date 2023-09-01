
# Debian initial setup

Use `su` to install `sudo`:
```bash
apt update && apt upgrade && apt install -y sudo
# Adjust user name to match your user
sudo adduser your-user-name sudo
```

Create a new ssh session and check that `sudo` is working:
```bash
sudo apt moo
```

Add `/usr/local/sbin` to `$PATH` for `sudoers`:
```shell
sudo visudo
```

In the opened `nano` editor, add `/usr/local/sbin` to `$PATH`. For example:
```conf
Defaults        secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/sbin"
```

Also add this folder to the user PATH:
```bash
echo 'PATH="$PATH:/usr/local/sbin"' >> ~/.bashrc
```

# Reset DHCP lease

```bash
sudo dhclient -r; sudo dhclient
```
