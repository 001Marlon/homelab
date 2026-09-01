# Security Notes

## Priority controls

- Keep secrets in `.env` files only.
- Avoid publishing admin surfaces directly to the internet.
- Pin image versions for critical services when stability is more important than convenience.

## Current exposure profile

High-sensitivity services:

- `vaultwarden` (credentials)
- `paperless-ngx` (documents)
- `immich` (photos + metadata)
- `portainer` / `dockge` (infrastructure control)

## Hardening checklist

1. Enable MFA where supported (Cloudflare, admin UIs).
2. Rotate API tokens on schedule.
3. Restrict who can edit compose/env files.
4. Review externally reachable services monthly.
5. Move from `latest` tags to fixed versions for critical apps.

## Logging and audit

- Keep container logs available for short-term incident analysis.
- For long-term traceability, ship important logs to a central store.
- Document sensitive config changes in a change log or commit history.

## Important note on tunnels

Tunnel config errors can expose internal services quickly. Any tunnel routing change should be peer-reviewed before deploy.
