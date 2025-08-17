# Phase Readiness Checklists

## Phase 1 — DeepThought + HAL (Marvin not built yet)
**Goal:** Stand up storage + core apps on HAL. (Optional: temporary SMTP on HAL.)

### 1) Pre-flight (do once)
```bash
# On HAL (Ubuntu LTS)
hostnamectl                           # expect "app1.mcke.lan"
ip addr | grep 192.168.1.11           # static IP present
getent hosts nas.mcke.lan             # DNS resolves

sudo apt-get update
sudo apt-get install -y nfs-common git ca-certificates curl gnupg lsb-release docker.io docker-compose-plugin
sudo systemctl enable --now docker
docker --version                      # expect version output
groups $USER | grep docker || sudo usermod -aG docker $USER
# (log out/in if group just added)
```

```bash
# Storage mount for app data
sudo mkdir -p /mnt/nas
echo "nas.mcke.lan:/pool/apps /mnt/nas nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab
sudo mount -a
df -h | grep /mnt/nas                 # expect an NFS line
```

### 2) Repo & env
```bash
# In a working directory
git clone <YOUR-REMOTE> mcke-homelab
cd mcke-homelab
cp env/hal.env.example env/hal.env
```
- Fill `env/hal.env` with **images/tags** from the manifest.
- **SMTP (Phase-1 options):**
  - **A (recommended)**: run without outbound email until Marvin exists (apps will still run).
  - **B (optional)**: run a **temporary Proton Bridge on HAL**, set `SMTP_HOST=localhost`, then later switch to Marvin in Phase-3.

### 3) Bring up Phase-1 stack
```bash
cd compose/phase1/hal
# load env vars
export $(grep -v '^#' ../../../env/hal.env | xargs) || true
docker compose pull
docker compose up -d
docker compose ps
```

### 4) Verify (green checks)
```bash
# DNS for service hostnames (LAN)
getent hosts ingress.mcke.lan sso.mcke.lan cloud.mcke.lan media.mcke.lan photos.mcke.lan docs.mcke.lan
# TLS + basic HTTP reachability (from a LAN client)
```
- `https://ingress.mcke.lan` – Traefik dashboard (admins only via SSO).
- `https://sso.mcke.lan` – authentik login page.
- `https://cloud.mcke.lan/status.php` – Nextcloud status JSON.
- `https://media.mcke.lan` – Jellyfin landing; confirm playback.
- `https://photos.mcke.lan` – PhotoPrism loads.
- `https://docs.mcke.lan` – Paperless loads.

### 5) Backout (safe)
```bash
cd compose/phase1/hal
docker compose down
# leave NFS mounts and repo intact
```

---

## Phase 2 — Temporary Home Assistant on HAL (migration)
**Goal:** Move HA from old hardware → HAL temporarily, keep ZHA working, keep a rollback.

### 1) Pre-flight
- On **old HA**: create **full backup** (snapshot) and download it.
- Identify ZHA adapter path on HAL (`/dev/ttyUSB0` expected):
```bash
ls -l /dev/serial/by-id/              # note your Sonoff dongle symlink
```

### 2) Deploy HA on HAL
```bash
cd compose/phase2/hal-with-ha
# reuse HAL env (no extra images needed unless tag changes)
export $(grep -v '^#' ../../../env/hal.env | xargs) || true
docker compose pull
docker compose up -d
docker compose ps
```

### 3) Restore & ZHA
- Open `https://ha.mcke.lan`, restore the snapshot from old HA.
- Check **ZHA** integration; if device path differs, update to your `/dev/serial/by-id/...`.

### 4) Break-glass (optional during maintenance)
- Enable the **LAN-only HA bypass** host `ha-bypass.mcke.lan` in Traefik (we ship it **disabled by default**).
- After maintenance, **disable** it again and rotate HA local admin passphrase.

### 5) Verify
- Automations fire; lights/switches respond.
- Mobile app reconnects.
- Notifications (if SMTP configured) work; otherwise skip for now.

### 6) Backout
- Stop HA on HAL:
```bash
cd compose/phase2/hal-with-ha
docker compose down
```
- Restart HA on the old hardware; restore last good snapshot if needed.

---

## Phase 3 — Build Marvin & migrate HA back (final)
**Goal:** Stand up Marvin (ops + HA final), centralize SMTP, move ZHA dongle.

### 1) Pre-flight (Marvin)
```bash
# On Marvin (Ubuntu LTS)
hostnamectl                           # expect "app2.mcke.lan"
ip addr | grep 192.168.1.12
sudo apt-get update
sudo apt-get install -y nfs-common git ca-certificates curl gnupg docker.io docker-compose-plugin chrony
sudo systemctl enable --now docker

# Chrony (NTP server)
sudo cp infra/ntp/chrony.conf /etc/chrony/chrony.conf
sudo systemctl restart chrony
chronyc sources -v                    # expect upstream and local clients later
```
- Set **DHCP option 42** on UCG to `192.168.1.12` (Marvin).
- Block WAN NTP for non-Marvin (edge firewall).

### 2) Proton Bridge (central SMTP on Marvin)
```bash
sudo cp infra/systemd/proton-bridge@.service /etc/systemd/system/
proton-bridge --cli                 # login as mckeops@protonmail.com, create app password
sudo systemctl daemon-reload
sudo systemctl enable --now proton-bridge@$USER
ss -lntp | grep 1025                # expect listener on 127.0.0.1:1025
```
- Put the Bridge **app password** in SOPS and reference as `SMTP_PASS` in `env/*.env`.

### 3) Repo & env (Marvin)
```bash
cd mcke-homelab
cp env/marvin.env.example env/marvin.env
# fill with images/tags from manifest and SMTP_PASS (SOPS-managed)
```

### 4) Bring up Phase-3 stack
```bash
cd compose/phase3/marvin
export $(grep -v '^#' ../../../env/marvin.env | xargs) || true
docker compose pull
docker compose up -d
docker compose ps
```

### 5) Migrate HA back to Marvin
- Stop HA on HAL (Phase-2 stack) **after** taking a snapshot.
- Move the ZHA dongle to Marvin, confirm device path (`/dev/serial/by-id/...`).
- Restore snapshot in `https://ha.mcke.lan` (now hosted by Marvin).

### 6) Verify
- **Ops**: `https://status.mcke.lan` (Kuma), diun messages, Scrutiny UI.
- **HA**: automations OK, voice pipeline (HAL Whisper/Piper/Ollama → HA intents) works.
- **LAN-open** portals: Homepage, Jellyfin, Calibre-Web, Tandoor, Kiwix load from LAN only.
- **Backups**: run `make backup` then `make test-restore`.

### 7) Backout
- If HA misbehaves, stop HA on Marvin and re-enable HA on HAL (Phase-2 stack), restore last good snapshot.
