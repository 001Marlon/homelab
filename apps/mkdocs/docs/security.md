# Sicherheit

## Secrets

Alle Zugangsdaten - Terraform-Variablen, App-Secrets, NetBird-API-Token - liegen in einer einzigen Datei: `homelab-secrets.yml` im Repository-Root. Diese Datei:

- existiert nur auf der Kontrollmaschine, nie auf einem Server
- wird nie committed (`.gitignore`: `/homelab-secrets.yml`)
- wird bei jedem Ansible-Lauf lokal von der Kontrollmaschine gelesen und daraus werden `.env`-Dateien bzw. `terraform.tfvars` gerendert

Das Repository selbst enthält dadurch nirgends echte Zugangsdaten und könnte öffentlich auf GitHub liegen. `homelab-secrets.yml.example` dokumentiert die erwartete Struktur mit Platzhaltern.

Faustregel für neue Compose-Files: alles Nicht-Geheime (Zeitzone, Pfade, Ports, öffentliche URLs) fest ins Compose-File schreiben. Nur echte Secrets über `${VARIABLE}` referenzieren und in `homelab-secrets.yml` pflegen.

`homelab-secrets.yml` selbst enthält bewusst keine Kommentare - die Struktur ist hier dokumentiert, damit die Datei beim Bearbeiten übersichtlich bleibt.

### Struktur

| Block | Enthält |
| --- | --- |
| `netbird_reverse_proxy` | API-Zugang zum NetBird-Server, Referenz auf den Docker-Host-Peer, das gemeinsame Reverse-Proxy-Passwort, die Liste der öffentlichen Services (siehe [Runbook](operations.md)) |
| `terraform` | SSH-Public-Keys, Proxmox-Zugangsdaten, sowie je ein Werte-Satz für die TrueNAS- und die Debian-VM (VM-ID, Name, IP, Image) |
| `apps.<name>` | Secrets/Config je App, ein Block pro Ordner unter `apps/`. Key muss exakt dem Ordnernamen entsprechen (z. B. `arr-stack` für `apps/arr-stack`) |

Innerhalb von `apps.<name>` steht optionalen, noch nicht eingerichteten Integrationen (z. B. ein API-Key für ein Widget, das noch nicht konfiguriert ist) der Wert `null` - das rendert als leere, aber vorhandene Umgebungsvariable statt eines Fehlers.

## Öffentliche vs. interne Erreichbarkeit

Nur Apps ohne sensible Admin- oder Download-Oberfläche bekommen eine öffentliche Domain (siehe [Services](services.md)). Download-Clients und *arr-Admin-Panels (qBittorrent, SABnzbd, Prowlarr, Sonarr, Radarr) bleiben bewusst nur per VPN/LAN erreichbar - das sind übliche Angriffsziele, wenn sie ohne Zusatz-Auth im Internet stehen.

## Reverse-Proxy-Schutz

Jede öffentliche App hat zwei Schutzebenen:

1. Der eigene Login der Anwendung
2. Ein gemeinsames Passwort auf Ebene des NetBird-Reverse-Proxy-Service (`password_auth`), bevor die Anfrage überhaupt bei der Anwendung ankommt

Verwaltet über `infrastructure/ansible/playbooks/sync-reverse-proxy.yml`. Das Passwort steht in `homelab-secrets.yml` unter `netbird_reverse_proxy.shared_password`.

## NetBird API-Zugriff

Die Automatisierung nutzt einen NetBird Service User mit Personal Access Token statt eines persönlichen Accounts (Team → Service Users im NetBird-Dashboard). Der Token liegt in `homelab-secrets.yml` unter `netbird_reverse_proxy.api_token`.

## Traffic-Fluss

Anfragen an eine öffentliche Domain laufen: Internet → Traefik (TLS-Terminierung, TLS-Passthrough für den NetBird-Proxy) → NetBird Reverse Proxy → verschlüsseltes WireGuard-Mesh → Docker-Host zu Hause. Zu keinem Zeitpunkt muss am heimischen Router ein Port geöffnet werden.

## Verantwortlichkeiten je Datei

| Datei | Enthält Secrets? | Versioniert? |
| --- | --- | --- |
| `apps/*/docker-compose.yml` | Nein | Ja |
| `apps/*/.env` | Ja | Nein (`.gitignore`) |
| `homelab-secrets.yml` | Ja | Nein (`.gitignore`) |
| `homelab-secrets.yml.example` | Nein (nur Platzhalter) | Ja |
| `infrastructure/proxmox/terraform/terraform.tfvars` | Ja | Nein (`.gitignore`) |
