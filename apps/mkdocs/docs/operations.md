# Runbook

## Tägliche Kontrolle

1. Uptime Kuma öffnen, aktive Incidents prüfen.
2. Auf dem Debian-Host: `docker ps -a` auf Restart-Loops prüfen.

```bash
ssh root@192.168.178.202
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

## App-Stand aktualisieren

Ein einzelner Ansible-Lauf bringt Repository-Stand, Secrets und laufende Container synchron:

```bash
cd infrastructure/ansible
ansible-playbook playbooks/docker-host.yml
```

Das klont/aktualisiert `/homelab` auf dem Host, rendert alle `.env`-Dateien aus `homelab-secrets.yml` neu und führt für jede gefundene `docker-compose.yml` ein `docker compose up -d` aus. Bereits laufende, unveränderte Stacks werden dabei nicht neu gestartet.

Einzelne App manuell aktualisieren:

```bash
ssh root@192.168.178.202
cd /homelab/apps/<app>
docker compose pull
docker compose up -d
docker compose ps
```

Nach dem Update: Login/UI prüfen, Logs auf Fehler kontrollieren.

## Neue App hinzufügen

1. `apps/<name>/docker-compose.yml` anlegen. Feste, nicht-geheime Werte (Zeitzone, Ports, Pfade) direkt ins Compose-File schreiben. Nur echte Secrets als `${VARIABLE}` referenzieren.
2. Falls die App Secrets braucht: Block in `homelab-secrets.yml` unter `apps.<name>` ergänzen (Key muss dem Ordnernamen entsprechen), passende Platzhalter in `homelab-secrets.yml.example` nachziehen.
3. `ansible-playbook playbooks/docker-host.yml` ausführen - klont die neue App, rendert die `.env`, startet den Stack.
4. Optional, falls die App öffentlich erreichbar sein soll: siehe unten.

## Neuen Reverse-Proxy-Eintrag anlegen

Nur für Apps ohne sensible Admin-/Download-Oberfläche - siehe [Sicherheit](security.md).

1. In `homelab-secrets.yml` unter `netbird_reverse_proxy.services` einen Eintrag mit `domain` und `port` ergänzen.
2. Ausführen:

```bash
cd infrastructure/ansible
ansible-playbook playbooks/sync-reverse-proxy.yml
```

Das legt fehlende Services an, bringt bestehende auf den deklarierten Stand (Ziel, Port, Passwort) und **entfernt Services, deren Eintrag aus der Liste gelöscht wurde**. Ein Eintrag entfernen und den Playbook-Lauf wiederholen macht eine App wieder VPN-only.

### Einzelnen Service vom Passwortschutz ausnehmen

Das gemeinsame Zusatz-Passwort ist standardmäßig für jeden Eintrag aktiv. Um eine bestimmte App davon auszunehmen (öffentlich erreichbar, aber ohne den zusätzlichen Passwort-Prompt), beim jeweiligen Eintrag `password_protected: false` ergänzen:

```yaml
services:
  - domain: immich.marlonslk.de
    port: 8007
    password_protected: false
```

Danach `sync-reverse-proxy.yml` erneut ausführen - der Service bleibt bestehen, nur `password_auth` wird deaktiviert. Weglassen von `password_protected` (oder `true`) bedeutet weiterhin geschützt.

## Terraform-Änderungen anwenden

```bash
cd infrastructure/ansible
ansible-playbook playbooks/render-terraform-vars.yml
cd ../proxmox/terraform
terraform plan
terraform apply
```

## Störung: App nicht erreichbar

1. `docker compose ps` im App-Ordner
2. `docker compose logs --tail=200`
3. Portbelegung prüfen (`docker ps -a --format '{{.Names}}\t{{.Ports}}'`)
4. Bei öffentlichen Apps: NetBird-Reverse-Proxy-Status prüfen (Dashboard oder `GET /api/reverse-proxies/services`)

## Störung: Container crasht wiederholt

1. Env-Datei und gemountete Pfade prüfen (`cat /homelab/apps/<app>/.env`)
2. Rechte auf gemountete Host-Verzeichnisse prüfen, insbesondere wenn ein `user:` im Compose-File gesetzt ist
3. Bei kürzlich geändertem Image-Tag: auf vorherige Version zurückrollen
4. Bei Datenverlust-Verdacht: aus Snapshot/Backup wiederherstellen, bevor weiter debuggt wird

## Backup-Prioritäten

Diese Pfade zuerst sichern:

- `/homelab/apps/immich`
- `/homelab/apps/paperless`
- `/homelab/apps/arr-stack/config`
- `homelab-secrets.yml` (nur außerhalb des Repos, z. B. Passwort-Manager)
