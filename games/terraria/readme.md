
# Terraria / TShock

References:
- https://github.com/beardedio/terraria
- https://ikebukuro.tshock.co/#/command-line-parameters

# Local environment setup

```bash
mkdir -p ./games/terraria/main-app/env/
 cat << EOF > ./games/terraria/main-app/env/passwords.env
server_password=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 10)
EOF
 cat << EOF > ./games/terraria/main-app/env/terraria.env
max_players=20

# a world is linked to a name
# using a new name will create a new world
world_name=My local Terraria

# world generation parameters below will be ignored if the world already exists
seed=$(LC_ALL=C tr -dc A-Za-z0-9 </dev/urandom | head -c 10)
# Possible values: random, corrupt, crimson
world_evil=random
# Possible values: 0 for normal, 1 for expert, 2 for master, 3 for journey
difficulty=0
EOF
```

# Deploy

```bash
kl create ns terraria
kl label ns terraria pod-security.kubernetes.io/enforce=baseline

kl apply -k ./games/terraria/loadbalancer/
kl -n terraria get svc

kl apply -k ./games/terraria/main-app/
kl -n terraria get pvc
kl -n terraria get pod -o wide
kl -n terraria logs sts/terraria

# connect to terraria server console
# you can exit via `ctrl + D`
kl -n terraria attach pods/terraria-0 -i
```

Optional additional config:
- [Guide: Making a TShock server that feels like a normal Terraria server](https://github.com/Pryaxis/TShock/discussions/2065)

# Cleanup

```bash
kl delete -k ./games/terraria/main-app/
kl delete -k ./games/terraria/loadbalancer/
kl delete ns terraria
```
