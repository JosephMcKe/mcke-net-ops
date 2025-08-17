# MCKE Homelab – Consolidated Decision Record
_Last updated: 2025-08-16_

## Ingress / Reverse Proxy
- **Decision:** Traefik  
- **Fallback:** NGINX  
- **Why:** Native Docker label integration, dynamic routing, forward-auth to IdP, simpler ops than NGINX for homelab.

## Identity / SSO & MFA
- **Decision:** authentik  
- **Fallback:** Keycloak  
- **Why:** Easier to run/operate in homelab, good OIDC/OAuth2 support, WebAuthn MFA, Traefik outpost.

## Remote Access
- **Decision:** VPN primary (no public exposure)  
- **Fallback / Option:** Mesh (e.g., TailScale) for **admin devices only**  
- **Why:** Minimize attack surface; mesh optional for operator convenience.

## Certificates
- **Decision:** Internal CA (mkcert)  
- **Fallback:** Reverse proxy ACME (if a public domain is added later)  
- **Why:** LAN-only services; fast and simple issuance for internal FQDNs.

## Home Automation
- **Decision:** Home Assistant, **hosted on Marvin** (final state)  
- **Migration:** Temporarily run on HAL during Phase 2, then move back to Marvin in Phase 3  
- **Why:** Keep HA near ZHA USB; isolate from heavier media/AI loads on HAL.

### HA Integrations & Choices
- **Zigbee:** ZHA with Sonoff USB gateway  
- **Cloud cams:** ARLO via HACS (cloud-only)  
- **Voice pipeline:** Local whisper (STT) + piper (TTS) + HA Assist; Ollama on HAL for LLM intents  
- **Notifications:** Push  
- **Snapshots:** Nightly  
- **Break-glass:** LAN-only bypass route + local admin (`local-mcke-admin`)

## Media Server & Automation
- **Decision:** Jellyfin  
- **Automation:** qBittorrent + Sonarr + Radarr (Prowlarr optional)  
- **Why:** FOSS, hardware decode support, family-friendly UI; automation optional and separable.

## File Sync / Collaboration
- **Decision:** Nextcloud + Collabora  
- **Fallback:** None (for now)  
- **Why:** Self-hosted docs/sheets; complements Proton (which currently lacks full suite).

## Photos
- **Decision:** PhotoPrism  
- **Fallback:** Nextcloud Photos (not selected)  
- **Why:** Better AI indexing/browsing; NC Photos kept off to reduce overlap.

## Document Management / OCR
- **Decision:** Paperless-ngx  
- **Fallback:** Nextcloud OCR plugins (not selected)  
- **Why:** Superior ingest/labels/OCR workflow; NC remains for files/collab only.

## Recipes & eBooks
- **Decision (recipes):** Tandoor (LAN-open)  
- **Decision (eBooks):** Calibre-Web (LAN-open, read-only)  
- **Why:** Lightweight, easy household access with guardrails.

## Git Hosting
- **Decision:** Gitea  
- **Fallback:** Forgejo  
- **Why:** Larger integrations/community, familiar UX, no Actions/LFS needed for this homelab.

## Observability / Jobs
- **Decision:** Uptime Kuma (HTTP checks) + Netdata (host metrics)  
- **Disk health:** Scrutiny  
- **Image updates:** diun  
- **Vuln scans:** Trivy (weekly)  
- **Why:** Simple, operator-friendly coverage across availability, health, and updates.

## Local AI / Voice
- **Decision:** Ollama on HAL (LLMs) + whisper + piper  
- **Why:** Keep CPU/GPU-heavy inference off Marvin where HA runs.

## Knowledge / Offline Preparedness
- **Decision:** Kiwix (LAN-open) with ZIMs: Wikipedia, Wikibooks, Wikisource, MDwiki, First Aid, Gardening  
- **Why:** Offline reference; fits “preparedness” use-case.

## Backup Tooling & Policy
- **Decision:** restic → offline USB (4TB `Mcke-Backup-1`)  
- **Retention:** 14 daily / 6 weekly / 6 monthly  
- **Test-restore:** Monthly automated sample restore  
- **Scope:** Daily configs/DBs/secrets; weekly photos/docs; media via snapshots only  
- **Why:** Lean, verifiable; single USB for now (agreed).

## Secrets Management
- **Decision:** SOPS + age in-repo (encrypted); Bitwarden for human vault  
- **Why:** Git-friendly secret storage; keep app creds out of plaintext.

## Container Runtime / Orchestration
- **Decision:** Docker + Compose (no CI/CD)  
- **Fallback:** K8s later if needed (not planned)  
- **Why:** Simplicity, fast iteration, fewer moving parts.

## Storage FS / Pool Layout (TrueNAS on DeepThought)
- **Decision:** **Mirrors** (2-way now; add a 3rd mirror later)  
- **Not chosen:** RAIDZ1 (insufficient resiliency), RAIDZ2 (maybe later for capacity)  
- **Why:** Best small-pool IOPS/latency; simple expansion path; safer rebuilds.

## Network Services
- **DNS:** Edge (UCG Ultra) with internal zones: `mcke.lan`, `mcke.iot`, `mcke.gst`  
- **mDNS:** Bonjour Gateway **LAN↔IoT allowlist only** (`_ipp`, `_ipps`)  
- **NTP:** chrony on Marvin; DHCP option 42 → Marvin; block WAN NTP for others  
- **Why:** Least privilege discovery; consistent time; reduced external deps.

## Network Policy / ACLs (high level)
- **Default:** Inter-VLAN deny; Guest → Internet only  
- **Allow:** LAN (HAL/Marvin) → NAS (NFS/SMB); All VLANs → Marvin:123/UDP (NTP)  
- **IoT TVs:** Only → HAL:443 (Jellyfin)  
- **Printer:** On LAN; AirPrint via IPP  
- **Why:** Minimum necessary flows; locked-down IoT.

## “LAN-Open” Services (with guardrails)
- **Open to LAN:** Homepage (read-only), Jellyfin (in-app auth, no self-register/remote), Calibre-Web (view-only), Tandoor (view-only), **Kiwix** (read-only)  
- **Ingress guardrails:** IP allowlist, security headers, rate-limit; admin paths still require SSO.

## Host Placement & Roles
- **HAL (192.168.1.11):** Ingress (Traefik), IdP (authentik), media (Jellyfin), Nextcloud+Collabora, PhotoPrism, Paperless, AI (Ollama/whisper/piper), misc apps (Calibre-Web, Tandoor), Postgres/Redis, Netdata/Trivy agents  
- **Marvin (192.168.1.12):** Home Assistant (+ZHA, Music Assistant), n8n, Gitea, Homepage, Uptime Kuma, diun, Scrutiny, chrony, **Proton Bridge (central SMTP/IMAP)**, Kiwix, Netdata/Trivy agents  
- **DeepThought (192.168.1.13):** TrueNAS (mirrors), NFS/SMB exports, NUT, USB backups, dual-NIC **LACP**

## NIC Strategy
- **DeepThought:** LACP (2×2.5G)  
- **Marvin:** Active-backup (mode 1); split across switch if possible  
- **HAL:** Single 2.5G (as provided)  
- **Why:** Reliability > raw throughput; NAS benefits from link resilience.

## IPs, DNS, and Inventory
- **HAL:** `192.168.1.11` – `app1.mcke.lan`  
- **Marvin:** `192.168.1.12` – `app2.mcke.lan`  
- **DeepThought:** `192.168.1.13` – `nas.mcke.lan`  
- **Printer:** `192.168.1.24` – `print.mcke.lan`  
- **TVs (IoT):** `192.168.2.104` (Samsung), `192.168.2.105` (FireTV)  
- **Zones/VLANs:** LAN `192.168.1.0/24`, IoT `192.168.2.0/24`, Guest `192.168.3.0/24`  

## Users & Access
- **Admin group:** `mcke-admin`  
- **Power users:** Jackie, Joseph, Aidan, Tyler  
- **HA local admin:** `local-mcke-admin` (break-glass)  
- **Why:** Clear separation of duties; least privilege.

## Alerts / Email
- **Decision:** Centralized **Proton Bridge on Marvin**; SMTP for all apps via `app2.mcke.lan:1025`  
- **Alert address:** `mckeops@protonmail.com`  
- **Why:** One place to manage deliverability and tokens.

## Landing Page
- **Decision:** Homepage  
- **Fallback:** Heimdall/Homarr  
- **Why:** Lightweight, flexible, good LAN “start here” portal.

## Phase Strategy (Build & Migration)
- **Phase 1:** DeepThought + HAL baseline (most apps on HAL)  
- **Phase 2:** Temporary HA on HAL; import snapshot; verify; backout path defined  
- **Phase 3:** Build Marvin; move HA back; enable ops stack (Kuma, diun, Gitea, n8n, Kiwix, Scrutiny); finalize.

