This directory holds **SOPS-encrypted** files only.
Add your age recipients to `.sops.yaml` before adding secrets.
Recommended secret files to create (encrypted): 
- `proton-bridge.env` (SMTP_USER, SMTP_PASS app password)
- `db-postgres.env` (POSTGRES_PASSWORD, etc.)
- `authentik.env` (secrets)
