# Operations Runbook

## Daily checks

1. Open Uptime Kuma and verify no active incidents.
2. Check `docker ps` for restart loops.
3. Confirm tunnel services are running.

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

## Safe update workflow

Run updates one service at a time.

```bash
cd /homelab/apps/<service>
docker compose pull
docker compose up -d
docker compose ps
```

Post-update:

- verify app login/UI
- verify background jobs (if any)
- check logs for migration errors

## Incident flow

### Service not reachable

1. `docker compose ps`
2. `docker compose logs --tail=200`
3. check bound port conflicts
4. verify tunnel and DNS route if public

### Container crash loop

1. inspect env + mounted path
2. roll back image tag if recently updated
3. restore data snapshot if migration failed

## Backup priorities

Backup these paths first:

- `/homelab/apps/immich`
- `/homelab/apps/paperless`
- `/homelab/apps/vaultwarden`
- `/homelab/apps/portainer`
- `/homelab/apps/uptime-kuma`
- `/homelab/apps/mcsmanager`

## Command snippets

```bash
# stack-wide compose file discovery
find /homelab/apps -maxdepth 2 -name docker-compose.yml

# check for old absolute paths
grep -RIn '/homelab/docker' /homelab/apps
```
