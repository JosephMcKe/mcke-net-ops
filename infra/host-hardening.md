# Host Hardening (Ubuntu LTS)

- Minimal install; enable unattended-upgrades.
- Users: create admin user; SSH keys (ed25519), disable password auth.
- UFW: allow 22/tcp from LAN/VPN only; allow 443/tcp on HAL (Traefik).
- Time: point to Marvin chrony; DNS via edge.
- Docker: install engine + compose; set log-driver local with rotation.
- Filesystems: mount NAS via NFSv4 where needed; least privilege mounts.
