# Service Inventory

This is the current inventory based on compose files in `/homelab/apps/*/docker-compose.yml`.

## Critical services

| Service | Why critical | Access |
| :--- | :--- | :--- |
| Cloudflare Tunnel | External access for web services | `host network` |
| Playit Tunnel | External access for game services | `host network` |
| Portainer | Operational control plane | `8002 -> 9443` |
| Uptime Kuma | Fast outage visibility | `8003 -> 3001` |

## Application services

| Service | Category | Host Port(s) | Path |
| :--- | :--- | :--- | :--- |
| glance | Dashboard | `8000` | `/homelab/apps/glance` |
| mkdocs | Documentation | `8001` | `/homelab/apps/mkdocs` |
| mcsmanager (web) | Game admin | `8004` | `/homelab/apps/mcsmanager` |
| dockge | Compose UI | `8005` | `/homelab/apps/dockge` |
| paperless-ngx | Documents | `8006` | `/homelab/apps/paperless` |
| immich | Photos | `8007` | `/homelab/apps/immich` |
| vaultwarden | Password manager | `8008` | `/homelab/apps/vaultwarden` |
| beszel | Monitoring | `8009` | `/homelab/apps/beszel` |
| jellyfin | Media | `8010`, `7359/udp` | `/homelab/apps/jellyfin` |
| qui | Download tooling | `8011` | `/homelab/apps/qui` |
| qbittorrent | Downloads | `8012`, `6881/tcp+udp` | `/homelab/apps/qbittorrent` |
| astroneer-server | Game server | `63089/udp` | `/homelab/apps/astroneer-server` |
| mcsmanager (daemon) | Game runtime | `24444`, `25565` | `/homelab/apps/mcsmanager` |
| website (nginx) | Static sites | `80` | `/homelab/apps/website` |

## Known conflicts and sharp edges

!!! warning "Port overlap"
    `glance` and any other dashboard planned for `8000` cannot run on the same host port at the same time.

!!! warning "Host networking"
    `cloudflare-tunnel`, `playit-tunnel`, and `beszel-agent` use host networking. Changes there bypass normal bridge isolation.

## Quick locate

```bash
# list all stacks
ls -1 /homelab/apps

# inspect one stack
cd /homelab/apps/<service>
docker compose ps
```
