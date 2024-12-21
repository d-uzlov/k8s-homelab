
```bash
sudo mkdir -p /jellyfin/ /jellyfin/config/ /jellyfin/cache/ /jellyfin/media/
sudo chmod 777 /jellyfin/ /jellyfin/config/ /jellyfin/cache/ /jellyfin/media/

mkdir -p ~/jellyfin/
cat << EOF > ~/jellyfin/docker-compose.yaml
services:
  jellyfin:
    image: jellyfin/jellyfin
    container_name: jellyfin
    user: 1001:1001
    # network_mode: hosta
    ports:
    - 127.0.0.1:8096:8096
    volumes:
    - /jellyfin/config/:/config
    - /jellyfin/cache/:/cache
    - type: bind
      source: /jellyfin/media/
      target: /media
    restart: unless-stopped
    # Optional - alternative address used for autodiscovery
    environment:
    - JELLYFIN_PublishedServerUrl=http://example.com
    # Optional - may be necessary for docker healthcheck to pass if running in host network mode
    # extra_hosts:
    # - host.docker.internal:host-gateway
EOF

cd ~/jellyfin/
docker compose up -d
```
