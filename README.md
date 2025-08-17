# MCKE Homelab

This repository contains a **complete, self-contained** homelab for home automation and self-hosting.
It includes architecture, decisions, network/security policy, backups, phased Compose stacks, and runbooks.

**Hosts**
- **HAL** — `app1.mcke.lan` — `192.168.1.11`
- **Marvin** — `app2.mcke.lan` — `192.168.1.12`
- **DeepThought (TrueNAS)** — `nas.mcke.lan` — `192.168.1.13`
- **Printer** — `print.mcke.lan` — `192.168.1.24`

**VLANs**
- LAN `192.168.1.0/24`, IoT `192.168.2.0/24` (TVs), Guest `192.168.3.0/24`

**Ingress & SSO**
- Traefik (HAL) with forward-auth to authentik. Admin UIs require MFA/WebAuthn.
- **LAN-open** (no SSO, LAN-only): Homepage, Jellyfin, Calibre-Web, Tandoor, Kiwix.

**Email**
- Centralized **Proton Bridge** on Marvin for SMTP (all apps point to `app2.mcke.lan:1025`).
- Alert email: **mckeops@protonmail.com**.

**Backups**
- restic → USB (label: `Mcke-Backup-1`), 14/6/6 retention, monthly test-restore.

---

## Repository Layout

- `docs/` – architecture, decision log, network policy, backups, runbooks, migration plan.
- `compose/` – phase1 (HAL), phase2 (HA temp on HAL), phase3 (Marvin).
- `config/` – Traefik dynamic config, Uptime Kuma checks.
- `infra/` – UCG firewall notes, **chrony** config, **Proton Bridge** systemd unit, host hardening.
- `env/` – `*.env.example` for HAL & Marvin.
- `scripts/` – restic backup & test-restore, Trivy scans.
- `make/` – Makefile with common tasks.
- `secrets/` – SOPS-managed (placeholders only).

See `docs/migration-plan.md` to build in phases.

---

## Prerequisites (Ubuntu LTS on HAL/Marvin)

```bash
# As root or via sudo
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release nfs-common git

# Docker Engine (from Ubuntu repo for simplicity)
apt-get install -y docker.io docker-compose-plugin
systemctl enable --now docker
usermod -aG docker $SUDO_USER || true
```

Mount NAS exports where needed (example):
```bash
mkdir -p /mnt/nas
echo "nas.mcke.lan:/pool/apps /mnt/nas nfs4 defaults,_netdev 0 0" >> /etc/fstab
mount -a
```

---

## Environment Files

Copy and edit the examples:
```bash
cp env/hal.env.example env/hal.env
cp env/marvin.env.example env/marvin.env
# Fill SMTP_PASS (Proton Bridge app password via SOPS), set image names/tags
```

**Images/Tags placeholders:** All Compose files use `IMG_*` and `TAG_*` variables.
Populate them in the relevant `*.env` before `docker compose up -d`.

---

## Proton Bridge (central SMTP on Marvin)

1. Install Proton Bridge (CLI) on Marvin and login to **mckeops@protonmail.com**:
   ```bash
   proton-bridge --cli
   ```
   Create an app password.

2. Save SMTP creds with **SOPS** (see `secrets/README.md`) and reference as `SMTP_PASS` in `env/*.env`.

3. Enable the systemd unit:
   ```bash
   cp infra/systemd/proton-bridge@.service /etc/systemd/system/
   systemctl daemon-reload
   systemctl enable --now proton-bridge@$(whoami)
   ```

HAL apps send mail to `app2.mcke.lan:1025`.

---

## Build & Run (Phased)

### Phase 1 — DeepThought + HAL
```bash
cd compose/phase1/hal
export $(grep -v '^#' ../../../env/hal.env | xargs) || true
docker compose up -d
```

### Phase 2 — Temporary HA on HAL
```bash
cd ../../phase2/hal-with-ha
export $(grep -v '^#' ../../../env/hal.env | xargs) || true
docker compose up -d
```

### Phase 3 — Marvin + HA migrate back
```bash
cd ../../phase3/marvin
export $(grep -v '^#' ../../../env/marvin.env | xargs) || true
docker compose up -d
```

**Verification:** See `docs/runbooks.md` and `config/uptime-kuma/checks.yml`.

---

## Make Targets (from repo root)

```bash
make up           # bring up the current directory's compose stack
make down         # stop it
make pull         # pull images
make backup       # restic backup of /srv/app-config
make test-restore # sample restore to /tmp
make scan         # Trivy scan of local images
```

> TIP: Run `make` from inside the compose folder you're managing.

---

## Secrets & SOPS

- Policy in `.sops.yaml` (age recipients: edit before use).
- **Do not commit plaintext secrets.** Everything under `secrets/` except README is ignored by git.

---

## License

MIT (see `LICENSE`). Replace the placeholder copyright line.

---

## Support

All instructions are in-repo. If you need adjustments (paths, hostnames, retention), update the env/examples and compose files.
