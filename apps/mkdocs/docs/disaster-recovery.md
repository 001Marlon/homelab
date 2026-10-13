# Disaster Recovery

Vollständige Wiederherstellung des Homelabs nach einem Totalausfall oder einer Neuinstallation. Die Schritte bauen aufeinander auf.

## 1. Proxmox installieren

Bootbaren USB-Stick (z. B. mit Ventoy) mit der vorbereiteten Proxmox-ISO verwenden (`proxmox-ve_9.2-1-auto-homelab.iso`), am Server einstecken, davon booten. Die automatisierte Installation läuft selbstständig durch.

## 2. Repository klonen

Auf der Kontrollmaschine (unter Windows z. B. via WSL):

```bash
git clone https://github.com/001Marlon/homelab.git
cd homelab
```

## 3. Terraform installieren

```bash
terraform --version
# falls nicht vorhanden:
sudo snap install terraform
```

## 4. Secrets und Terraform-Variablen vorbereiten

Alle Zugangsdaten kommen aus einer zentralen, nicht versionierten Datei:

```bash
cp homelab-secrets.yml.example homelab-secrets.yml
```

`homelab-secrets.yml` öffnen und sämtliche Platzhalter mit echten Werten befüllen - SSH-Keys, Proxmox-Zugangsdaten, App-Secrets, NetBird-API-Token. Details zur Struktur: [Sicherheit](security.md).

Daraus die `terraform.tfvars` rendern:

```bash
cd infrastructure/ansible
ansible-playbook playbooks/render-terraform-vars.yml
```

Terraform initialisieren:

```bash
cd ../proxmox/terraform
terraform init
```

## 5. Infrastruktur erstellen

```bash
terraform plan
terraform apply
```

Mit `yes` bestätigen. Danach existieren TrueNAS- und Debian-VM.

## 6. TrueNAS einrichten

Terraform legt nur die VM an und reicht die beiden HDDs durch - Installation, Pool, Benutzer und Shares sind (noch) Handarbeit in der TrueNAS-Weboberfläche.

1. **TrueNAS installieren**: VM `homelab-truenas01` in Proxmox über die Konsole von der eingehängten ISO installieren, danach die feste IP `192.168.178.201/24` setzen und die Weboberfläche unter `https://192.168.178.201` öffnen.
2. **Pool**: *Storage → Create Pool*, Name `tank`, beide HDDs als **Mirror**.

    !!! note
        Ist der Pool nach einer Neuinstallation von TrueNAS noch auf den Platten vorhanden, stattdessen *Storage → Import Pool* verwenden - sonst sind die Daten weg.

3. **Dataset**: `tank` auswählen → *Add Dataset*, Name `media`, Preset **SMB**. Filme, Serien und Downloads liegen bewusst im selben Dataset, sonst funktionieren die Hardlinks/Atomic-Moves des Arr-Stacks nicht (siehe `apps/arr-stack/docker-compose.yml`). Struktur darin: `movies`, `tv`, `downloads/torrents`, `downloads/usenet/incomplete`.
4. **Gruppe und Benutzer für UID/GID 3000** (entspricht `PUID`/`PGID` des Arr-Stacks):
      - *Credentials → Groups → Add*: Name `media`, GID `3000`
      - *Credentials → Users → Add*: z. B. `marlon`, UID `3000`, primäre Gruppe `media`, **SMB User** aktiv, Passwort setzen
      - Beim Dataset `media` unter *Permissions → Edit* Owner `marlon` / Group `media` setzen (rekursiv)
5. **SMB-Share** (Zugriff vom Windows-PC): Dataset `media` → *Create SMB Share*, Pfad `/mnt/tank/media`, Name `media`. SMB-Dienst starten und auf „Start automatically" stellen. Test im Explorer: `\\192.168.178.201\media`.
6. **NFS-Share** (für den Docker-Host): Dataset `media` → *Create NFS Share*, Pfad `/mnt/tank/media`, Hosts `192.168.178.202`, unter *Advanced Options* **Mapall User** `marlon` und **Mapall Group** `media`. NFS-Dienst starten und auf „Start automatically" stellen.

Durch Mapall gehört alles, was die Container über NFS schreiben, UID/GID 3000 - unabhängig davon, als wer der Container schreibt.

Gemountet wird der Share später automatisch von der `storage`-Rolle (Schritt 10). Quelle und Ziel stehen in `homelab-secrets.yml` unter `storage.nfs_mounts`:

```yaml
storage:
  nfs_mounts:
    - src: "<TrueNAS-IP>:/mnt/<pool>/<dataset>"
      path: /homelab/data/media
```

## 7. Docker-Host prüfen

```bash
ssh root@192.168.178.202
exit
```

Die Anmeldung sollte ohne Passwort funktionieren (SSH-Key aus Terraform). Falls nicht: Proxmox-, Netzwerk- und Cloud-Init-Konfiguration prüfen.

## 8. Ansible installieren

Auf der Kontrollmaschine, nicht auf dem Docker-Host:

```bash
sudo apt update
sudo apt install ansible -y
```

## 9. Verbindung testen

Das Inventory (`infrastructure/ansible/inventory/hosts.yml`) verweist auf den Docker-Host mit Hostname `homelab-debian`, IP `192.168.178.202`, SSH-Benutzer `root` und Python-Interpreter `/usr/bin/python3`.

```bash
cd infrastructure/ansible
ansible all -m ping
```

Erwartete Ausgabe:

```text
homelab-debian | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Erst bei erfolgreichem Test weitermachen.

## 10. Docker-Host konfigurieren und alle Apps starten

```bash
ansible-playbook playbooks/docker-host.yml
```

Ein einzelner Lauf erledigt alles:

1. `common`-Rolle: Grundpakete installieren (`ca-certificates`, `curl`, `git`, `gnupg`)
2. `docker`-Rolle: offizielles Docker-APT-Repository einrichten, Docker Engine, Docker CLI, `containerd`, Docker-Buildx-Plugin und Docker-Compose-Plugin installieren, Docker-Service aktivieren und starten
3. `storage`-Rolle:
      - `nfs-common` installieren
      - alle Shares aus `storage.nfs_mounts` mounten und in `/etc/fstab` eintragen (`_netdev,nofail`)
      - Docker per systemd-Drop-in (`/etc/systemd/system/docker.service.d/wait-for-nfs.conf`) erst nach `remote-fs.target` starten, damit die Container nach einem Reboot nicht den leeren lokalen Ordner statt des Shares einbinden
4. `homelab`-Rolle:
      - Repository nach `/homelab` klonen
      - `homelab-secrets.yml` von der Kontrollmaschine laden
      - für jede App eine `.env` rendern und nach `/homelab/apps/<app>/.env` übertragen
      - jede gefundene `docker-compose.yml` mit `docker compose up -d` starten

Ein erfolgreicher Lauf endet mit `failed=0`, `unreachable=0`. Beim erneuten Ausführen sollte `changed=0` erscheinen - das bestätigt Idempotenz.

## 11. Ergebnis prüfen

Auf dem Docker-Host prüfen, ob das Repository korrekt angekommen ist und Docker läuft:

```bash
ssh root@192.168.178.202
ls -la /homelab
docker --version
docker compose version
systemctl status docker
```

`/homelab` sollte dieselbe Grundstruktur wie das lokale Repository haben, der Docker-Service sollte aktiv sein. Danach den Container-Status prüfen:

```bash
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

Alle Container aus [Services](services.md) sollten `Up` sein.

Der TrueNAS-Share muss gemountet sein und die Medien enthalten:

```bash
findmnt /homelab/data/media
ls /homelab/data/media          # movies  tv  downloads
docker exec radarr ls /data     # dieselben Ordner im Container
```

Einzelne Rollen lassen sich per Tag gezielt ausführen, z. B. nur den Storage-Teil:

```bash
ansible-playbook playbooks/docker-host.yml --tags storage
```

!!! warning
    Wird der NFS-Mount nachträglich bei laufenden Containern eingehängt, sehen diese weiterhin den alten lokalen Ordner. Vorher `docker compose down` im betroffenen Stack, danach `docker compose up -d`.

## 12. Öffentlichen Zugriff wiederherstellen

Sobald der Docker-Host im NetBird-Mesh ist, die öffentlichen Reverse-Proxy-Services synchronisieren:

```bash
cd infrastructure/ansible
ansible-playbook playbooks/sync-reverse-proxy.yml
```

Legt alle in `homelab-secrets.yml` unter `netbird_reverse_proxy.services` gelisteten Domains neu an, falls sie nach der Neuinstallation noch nicht existieren.

!!! note
    Läuft der bestehende VPS mit NetBird-Server unverändert weiter, ist dieser Schritt meist nicht nötig - die Services zeigen bereits auf die richtige Peer-IP, sobald sich der Docker-Host neu mit dem Mesh verbindet.

## Kurzfassung

```text
Proxmox installieren
        ↓
Repository klonen
        ↓
homelab-secrets.yml aus der Vorlage befüllen
        ↓
Terraform-Variablen rendern (render-terraform-vars.yml)
        ↓
Terraform erstellt die Infrastruktur
        ↓
TrueNAS: Pool, Benutzer (UID 3000), SMB- und NFS-Share
        ↓
Ansible konfiguriert den Docker-Host und mountet den NFS-Share
        ↓
Ansible rendert Secrets und startet alle Apps
        ↓
NetBird-Reverse-Proxy-Services synchronisieren
        ↓
Homelab ist wiederhergestellt
```
