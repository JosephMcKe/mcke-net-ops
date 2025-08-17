# Architecture Overview (Standalone)

**Updated 2025-08-16 22:34.**

- **Edge:** UCG Ultra (192.168.1.1) – DNS, VPN (LAN-only), Bonjour Gateway LAN↔IoT with `_ipp/_ipps` allowlist.
- **LAN (192.168.1.0/24 / mcke.lan):**
  - **HAL** `app1.mcke.lan` `192.168.1.11`: Traefik (ingress), authentik (IdP), Jellyfin, Nextcloud+Collabora, PhotoPrism, Paperless-ngx, Ollama, Whisper/Piper, Calibre-Web, Tandoor, Postgres, Redis, Netdata agent, Trivy agent.
  - **Marvin** `app2.mcke.lan` `192.168.1.12`: Home Assistant + ZHA + Music Assistant, n8n, Gitea, Homepage, Uptime Kuma, diun, Scrutiny (server), chrony (NTP), **Proton Bridge (centralized SMTP/IMAP)**, Kiwix (LAN-open), Netdata agent, Trivy agent.
  - **DeepThought (TrueNAS)** `nas.mcke.lan` `192.168.1.13`: ZFS pool (2× mirrors now; 3rd mirror later), NFSv4/SMB exports, NUT server, USB backup (4TB, label: `Mcke-Backup-1`), dual NIC **LACP** to switch.
- **IoT (192.168.2.0/24 / mcke.iot):**
  - TVs: Samsung `192.168.2.104` and Fire Stick `192.168.2.105` → **allowlist to Jellyfin (HAL:443)** only; DLNA blocked cross-VLAN (app uses direct URL).
- **Printer:** HP M283fdw `print.mcke.lan` `192.168.1.24` (LAN). AirPrint via IPP (631/tcp).
- **Guest (192.168.3.0/24 / mcke.gst):** Internet only (no inter-VLAN).

**Ingress & SSO:** Traefik on HAL with forward-auth to authentik for private apps; admin UIs require WebAuthn.  
**LAN-open routes (no SSO, LAN-only):** Homepage (read-only), Jellyfin (in-app auth; no self-register/remote), Calibre-Web (view-only), Tandoor (view-only), Kiwix (read-only).  
**Backups:** restic → offline USB, lean retention (14/6/6), monthly automated **test-restore**.  
**Secrets:** SOPS + age (repo contains only encrypted placeholders).  
**NTP:** chrony on Marvin; DHCP option 42 points to `192.168.1.12`; block outbound NTP elsewhere.
