# One-Page “Run Order” Cheat Sheet

**Where:** LAN terminal (with DNS working), per-host as noted.

1) **DeepThought (TrueNAS)**  
   - Pool (mirrors) healthy; NFS export ready at `nas.mcke.lan:/pool/apps`.

2) **HAL (Phase-1)**
```bash
# OS prep + Docker
sudo apt-get install -y nfs-common docker.io docker-compose-plugin

# Mount storage
sudo mkdir -p /mnt/nas && echo "nas.mcke.lan:/pool/apps /mnt/nas nfs4 defaults,_netdev 0 0" | sudo tee -a /etc/fstab && sudo mount -a

# Repo + env
git clone <YOUR-REMOTE> mcke-homelab && cd mcke-homelab
cp env/hal.env.example env/hal.env   # paste manifest values
cd compose/phase1/hal
export $(grep -v '^#' ../../../env/hal.env | xargs) || true

# Bring up
docker compose pull && docker compose up -d && docker compose ps
```
**Verify:**  
`https://ingress.mcke.lan` (Traefik), `https://sso.mcke.lan`, `https://media.mcke.lan`, `https://cloud.mcke.lan/status.php`, `https://photos.mcke.lan`, `https://docs.mcke.lan`.

3) **HA temporary on HAL (Phase-2)**
```bash
cd ../../phase2/hal-with-ha
export $(grep -v '^#' ../../../env/hal.env | xargs) || true
docker compose up -d
```
- Restore HA snapshot; set ZHA device path.  
**Verify:** Automations/devices OK.

4) **Marvin (Phase-3)**
```bash
# OS prep + chrony + Docker
sudo apt-get install -y nfs-common docker.io docker-compose-plugin chrony
sudo cp infra/ntp/chrony.conf /etc/chrony/chrony.conf && sudo systemctl restart chrony

# Proton Bridge (central SMTP)
sudo cp infra/systemd/proton-bridge@.service /etc/systemd/system/
proton-bridge --cli     # login as mckeops@protonmail.com, create app password
sudo systemctl daemon-reload && sudo systemctl enable --now proton-bridge@$USER

# Repo + env
cd ~/mcke-homelab
cp env/marvin.env.example env/marvin.env  # paste manifest values
cd compose/phase3/marvin
export $(grep -v '^#' ../../../env/marvin.env | xargs) || true

# Bring up
docker compose pull && docker compose up -d && docker compose ps
```

5) **Move HA to Marvin**
- Stop HA on HAL (`docker compose down` in Phase-2 dir).  
- Move ZHA USB to Marvin, restore snapshot in `https://ha.mcke.lan`.  
**Verify:** HA responsive, voice path works, TVs play Jellyfin.

6) **Ops checks**
- `https://status.mcke.lan` (Kuma all green).  
- `make backup` then `make test-restore`.  
- Diun notifications received; Scrutiny lists disks.
