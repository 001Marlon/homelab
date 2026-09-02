# Services

Alle Anwendungen laufen als Docker-Compose-Stack unter `/homelab/apps/<name>` auf dem Debian-Host. Quelle: die jeweilige `docker-compose.yml` im Repository.

## Öffentlich erreichbar

Diese Apps haben einen NetBird-Reverse-Proxy-Service mit eigener Domain und automatischem TLS-Zertifikat. Zusätzlich zum Login der Anwendung selbst greift standardmäßig ein gemeinsames Passwort-Gate auf Proxy-Ebene (siehe [Sicherheit](security.md)) - einzelne Apps können davon ausgenommen werden (`password_protected: false`).

| App | Domain | Host-Port | Zusatz-Passwort | Ordner |
| --- | --- | --- | --- | --- |
| Glance | marlonslk.de | 8000 | Nein (dient als öffentliche Startseite) | `apps/glance` |
| MkDocs | docs.marlonslk.de | 8001 | Ja | `apps/mkdocs` |
| Arcane | arcane.marlonslk.de | 8002 | Ja | `apps/arcane` |
| Uptime Kuma | uptime.marlonslk.de | 8003 | Ja | `apps/uptime-kuma` |
| MCSManager (Web) | mcsmanager.marlonslk.de | 8004 | Ja | `apps/mcsmanager` |
| Paperless-ngx | paperless.marlonslk.de | 8006 | Ja | `apps/paperless` |
| Immich | immich.marlonslk.de | 8007 | Ja | `apps/immich` |
| Beszel | beszel.marlonslk.de | 8009 | Ja | `apps/beszel` |
| Jellyfin | jellyfin.marlonslk.de | 8100 | Ja | `apps/arr-stack` |
| Seerr | seerr.marlonslk.de | 8101 | Ja | `apps/arr-stack` |

Verwaltet über `infrastructure/ansible/playbooks/sync-reverse-proxy.yml`, gesteuert durch die `services`-Liste in `homelab-secrets.yml`.

## Nur per VPN/LAN erreichbar

Bewusst nicht öffentlich, da Admin-Oberflächen bzw. Downloadclients ohne eigenes starkes Auth-Konzept:

| App | Host-Port | Ordner |
| --- | --- | --- |
| SABnzbd | 8102 | `apps/arr-stack` |
| qBittorrent | 8103 (über Gluetun) | `apps/arr-stack` |
| Prowlarr | 8105 (über Gluetun) | `apps/arr-stack` |
| Radarr | 8106 | `apps/arr-stack` |
| Sonarr | 8107 | `apps/arr-stack` |
| FlareSolverr | 8108 (intern, kein UI) | `apps/arr-stack` |
| MCSManager Daemon | 24444, 25565 | `apps/mcsmanager` |

## Infrastruktur

| Komponente | Ort | Zweck |
| --- | --- | --- |
| Netbird-Client | `apps/netbird` (Debian-Host) | VPN-Mesh-Beitritt des Docker-Hosts |
| NetBird Server + Dashboard | VPS | Selbstgehostetes Management, `netbird.vps.marlonslk.de` |
| NetBird Reverse Proxy + Traefik | VPS | TLS-Terminierung und Routing für die öffentlichen Domains oben |

## Neue App hinzufügen

Siehe [Runbook](operations.md).
