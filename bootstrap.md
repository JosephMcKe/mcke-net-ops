# Bootstrap Guide (Bare Ubuntu → Phase 1→2→3)

## 0) Assumptions
- Hosts & IPs: HAL (192.168.1.11), Marvin (192.168.1.12), NAS (192.168.1.13).
- DNS resolves `*.mcke.lan` internally. NFS export available at `nas.mcke.lan:/pool/apps`.

## 1) Base OS prep (HAL/Marvin)
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release nfs-common git
sudo apt-get install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
```

**Expected:** `docker --version` prints a version; `docker ps` works without sudo after re-login.

## 2) Mount storage
```bash
sudo mkdir -p /mnt/nas
echo "nas.mcke.lan:/pool/apps /mnt/nas nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab
sudo mount -a
```

**Expected:** `df -h | grep /mnt/nas` shows the mount.

## 3) Clone repo & prepare env
```bash
git clone <YOUR-REMOTE> mcke-homelab
cd mcke-homelab
cp env/hal.env.example env/hal.env
cp env/marvin.env.example env/marvin.env
```

Fill `SMTP_PASS` (Proton Bridge app password via SOPS), image names/tags.

## 4) Proton Bridge on Marvin
```bash
sudo cp infra/systemd/proton-bridge@.service /etc/systemd/system/
proton-bridge --cli   # login as mckeops@protonmail.com; create app password
sudo systemctl daemon-reload
sudo systemctl enable --now proton-bridge@$USER
```

**Expected:** `ss -lntp | grep 1025` shows Bridge listening on 1025.

## 5) Phase 1 on HAL
```bash
cd compose/phase1/hal
export $(grep -v '^#' ../../../env/hal.env | xargs) || true
docker compose up -d
```

**Expected:** Traefik responds at `https://ingress.mcke.lan` (admins only), and initial apps come up.

## 6) Phase 2: HA temporarily on HAL
```bash
cd ../../phase2/hal-with-ha
export $(grep -v '^#' ../../../env/hal.env | xargs) || true
docker compose up -d
```

Restore your HA snapshot via UI; set ZHA USB path.

## 7) Phase 3 on Marvin (migrate HA back)
```bash
cd ../../phase3/marvin
export $(grep -v '^#' ../../../env/marvin.env | xargs) || true
docker compose up -d
```

Move the ZHA dongle to Marvin; update device path; validate automations.

## 8) Validation & Backups
- Uptime Kuma: `https://status.mcke.lan` all green.
- `make backup` then `make test-restore` from repo root.
