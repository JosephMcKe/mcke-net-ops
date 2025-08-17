# Migration & Build Plan (Phased)

## Phase 1 – DeepThought + HAL
1. Prepare TrueNAS pool (mirrors), datasets, snapshots; configure LACP on NAS and switch.
2. HAL: Ubuntu LTS minimal; Docker/Compose; mount NFS datasets; deploy `compose/phase1/hal` stack.
3. Configure Traefik, authentik, Postgres/Redis, Nextcloud+Collabora, Jellyfin, PhotoPrism, Paperless, Calibre-Web, Tandoor, Ollama, Whisper/Piper, Netdata, Trivy.

**Verify:** Traefik dashboard (admins only), SSO login, media plays, Nextcloud login, Paperless ingest via consume folder.

## Phase 2 – Temporary HA on HAL
1. Stop legacy HA on old hardware; export snapshot/backup.
2. Deploy HA on HAL using `compose/phase2/hal-with-ha`.
3. Restore HA snapshot; plug ZHA USB into HAL (USB extension). Update device path in HA.
4. Keep break-glass local admin; configure LAN-only bypass route.

**Backout:** stop HA on HAL, re-enable old hardware, restore snapshot if needed.

## Phase 3 – Build Marvin & migrate HA back
1. Marvin: Ubuntu LTS; Docker/Compose; Proton Bridge (systemd); chrony; deploy `compose/phase3/marvin`.
2. Move ZHA dongle to Marvin (USB extension); update HA device path; migrate HA from HAL with snapshot.
3. Enable Kuma, diun, Homepage, Gitea, n8n, Scrutiny, Kiwix, Proton Bridge centralized SMTP/IMAP.
4. Remove HA from HAL (phase 2 stack), keep final HAL stack from phase 1.

**Verify:** HA responsiveness, voice path (HAL inference → Marvin HA), TVs reach Jellyfin, backups & heartbeats pass.
