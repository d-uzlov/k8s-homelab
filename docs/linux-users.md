
# Linux users

# Create new user

```bash

username=
sudo useradd --create-home --shell /bin/bash "$username"

# set password in interactive terminal
sudo passwd "$username"

# or set password in a script
password=
usermod --password $(echo "$password" | openssl passwd -1 -stdin) "$username"

# enable sudo for the new user
sudo adduser "$username" sudo

# switch login to user
# useful if you want to change SSH settings to be able to login remotely
sudo su - "$username"

```

You probably want to set up SSH next: [SSH tips](./ssh.md#allow-login-with-your-ssh-key)

# List users

```bash
cat /etc/passwd
```

# Delete a user

```bash
sudo userdel "$username"
```

# `sudo` without password

```bash

# when creating user
echo "$username ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$username

# when already running as user
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER

```
