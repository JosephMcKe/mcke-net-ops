# Runbooks & Procedures

## Daily
- Check Uptime Kuma: all services green.
- Review diun digest (new images).

## Weekly
- Photos/docs weekly backup runs (restic) – verify in Kuma/report.
- Trivy weekly scan – review report for critical CVEs.
- Jellyfin library cleanup (orphans, bad matches).

## Monthly
- Test-restore: HA snapshot + PhotoPrism album + Jellyfin config → PASS.
- Refresh Kiwix ZIMs (if due).

## Quarterly
- Rotate application tokens where possible.
- Review firewall rules and SSO group membership.
- Check SMART/NVMe wear in Scrutiny; plan replacements.

## Annual
- Rotate internal TLS leaf certs; verify trust store.
- Review storage capacity & pool health; plan drive upgrades.
- Full disaster-recovery drill (restore key apps to a temp path).

## Break-glass HA
- Enable LAN-only bypass route in Traefik.
- Log the time & reason; sign in with `local-mcke-admin`.
- Complete maintenance; disable bypass; rotate passphrase; record event.
