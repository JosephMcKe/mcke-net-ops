# Backup & Recovery Plan

- **Tool:** restic to offline USB (label: `Mcke-Backup-1`).
- **Scope:** Daily configs/DBs/secrets; Weekly photos/docs; media excluded (snapshots only).
- **Retention:** 14 daily / 6 weekly / 6 monthly.
- **Test-restore:** Monthly automated sample restore & report → alert if failed.
- **USB hygiene:** Keep unplugged except during backup window (02:00–04:00).

## Verify (quick)
- `restic snapshots` shows new snapshots after nightly job.
- Monthly test-restore report is present in `backups/reports/` and marked PASS.
