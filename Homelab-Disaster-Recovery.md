# Homelab Disaster Recovery

Diese Anleitung beschreibt die grundlegenden Schritte, um das Homelab nach einem vollständigen Ausfall bzw. einer Neuinstallation wiederherzustellen.

---

## 1. Proxmox installieren

### 1.1 Boot-Medium vorbereiten

- Bootable Flashdrive oder Ventoy verwenden.
- Die vorbereitete Proxmox-ISO auf den USB-Stick kopieren:

`proxmox-ve_9.2-1-auto-homelab.iso`

### 1.2 Proxmox installieren

1. USB-Stick in den Homelab-Server einstecken.
2. Server starten.
3. Vom USB-Stick booten.
4. Die automatisierte Installation sollte selbstständig durchlaufen.
5. Nach Abschluss ist Proxmox installiert.

---

## 2. Homelab Repository lokal klonen

Das Repository ist die zentrale Source of Truth für das Homelab. Es enthält unter anderem:

- die Proxmox-Terraform-Konfiguration
- die Ansible-Konfiguration für den Debian-Docker-Host
- die Docker-Compose-Konfigurationen der Homelab-Anwendungen
- Dokumentation und Disaster-Recovery-Anweisungen

### 2.1 WSL bzw. Linux-Terminal öffnen

Unter Windows kann dafür WSL verwendet werden.

### 2.2 Repository klonen

```bash
git clone https://github.com/001Marlon/homelab.git
```

Anschließend in das Repository wechseln:

```bash
cd homelab
```

---

## 3. Terraform installieren

Zuerst prüfen, ob Terraform bereits installiert ist:

```bash
terraform --version
```

Falls Terraform noch nicht installiert ist, kann es beispielsweise über Snap installiert werden:

```bash
sudo snap install terraform
```

Anschließend erneut prüfen:

```bash
terraform --version
```

---

## 4. Terraform konfigurieren

### 4.1 tfvars-Datei erzeugen

Terraform verwendet eine `.tfvars`-Datei für Zugangsdaten und umgebungsspezifische Konfigurationswerte. Diese Werte kommen nicht mehr aus einer eigenen Terraform-Vorlage, sondern aus der zentralen `homelab-secrets.yml` im Repository-Root, die auch die Secrets aller Docker-Apps enthält. Sie liegt nicht im Repository; stattdessen gibt es dort eine Vorlage.

Im Repository-Root eine Kopie der Vorlage erstellen:

```bash
cp homelab-secrets.yml.example homelab-secrets.yml
```

Anschließend `homelab-secrets.yml` öffnen und alle Platzhalter durch echte Werte ersetzen, unter anderem im `terraform`-Block:

- `ssh_public_keys` – die öffentlichen SSH-Keys, die Zugriff auf die erstellten Systeme erhalten sollen
- Proxmox-Zugangsdaten (`proxmox_endpoint`, `proxmox_username`, `proxmox_password`)
- gegebenenfalls weitere umgebungsspezifische Werte wie VM-IDs, IP-Adressen oder Hardware-Konfigurationen

Danach die `terraform.tfvars` daraus rendern:

```bash
cd infrastructure/ansible
ansible-playbook playbooks/render-terraform-vars.yml
```

Das erzeugt `infrastructure/proxmox/terraform/terraform.tfvars`. Der Dateiname `terraform.tfvars` wird von Terraform automatisch geladen, ohne dass er bei den folgenden Befehlen über `-var-file` mitgegeben werden muss.

### 4.2 Terraform initialisieren

```bash
cd ../proxmox/terraform
terraform init
```

Dadurch werden unter anderem die benötigten Terraform-Provider heruntergeladen.

---

## 5. Infrastruktur mit Terraform erstellen

### 5.1 Terraform Plan erstellen

Zunächst prüfen, welche Änderungen Terraform durchführen würde:

```bash
terraform plan
```

Den Plan kontrollieren.

### 5.2 Infrastruktur erstellen

Wenn der Plan korrekt aussieht:

```bash
terraform apply
```

Terraform fragt anschließend nach einer Bestätigung:

```text
Do you want to perform these actions?

Only 'yes' will be accepted to approve.
```

Mit

```text
yes
```

bestätigen.

Nach erfolgreichem Abschluss sollte die von Terraform definierte Infrastruktur erstellt sein. Dazu gehört insbesondere die Debian-VM, die später als Docker-Host für die Homelab-Anwendungen verwendet wird.

---

## 6. Debian-Docker-Host prüfen

Bevor Ansible ausgeführt wird, muss geprüft werden, ob die von Terraform erstellte Debian-VM erreichbar ist.

### 6.1 Netzwerkverbindung prüfen

Die aktuell konfigurierte Debian-VM ist unter folgender Adresse erreichbar:

```text
192.168.178.202
```

Die Verbindung per SSH testen:

```bash
ssh root@192.168.178.202
```

Die Anmeldung sollte mit einem der in Terraform hinterlegten SSH-Keys ohne Passwort möglich sein.

Die Verbindung anschließend wieder beenden:

```bash
exit
```

Falls die VM nicht erreichbar ist, müssen zunächst die Proxmox-, Netzwerk- und Cloud-Init-Konfigurationen überprüft werden.

---

## 7. Ansible installieren

Ansible wird auf dem lokalen Rechner bzw. im WSL/Linux-Terminal installiert. Es wird nicht auf dem Debian-Docker-Host benötigt.

Zunächst prüfen:

```bash
ansible --version
```

Falls Ansible noch nicht installiert ist:

```bash
sudo apt update
sudo apt install ansible -y
```

Danach erneut prüfen:

```bash
ansible --version
```

---

## 8. Ansible konfigurieren und Verbindung testen

In das Ansible-Verzeichnis wechseln:

```bash
cd ~/homelab/infrastructure/ansible
```

Das Ansible-Projekt verwendet folgende grundlegende Struktur:

```text
infrastructure/ansible/
├── ansible.cfg
├── inventory/
│   └── hosts.yml
├── playbooks/
│   └── docker-host.yml
└── roles/
    ├── common/
    ├── docker/
    └── homelab/
```

### 8.1 Inventory prüfen

Das Inventory enthält den Debian-Docker-Host. Die aktuelle Konfiguration verwendet:

- Hostname in Ansible: `homelab-debian`
- IP-Adresse: `192.168.178.202`
- SSH-Benutzer: `root`
- Python-Interpreter: `/usr/bin/python3`

### 8.2 Ansible-Verbindung testen

```bash
ansible all -m ping
```

Bei erfolgreicher Verbindung sollte ungefähr Folgendes ausgegeben werden:

```text
homelab-debian | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

Erst wenn dieser Test erfolgreich ist, sollte mit der Konfiguration des Docker-Hosts fortgefahren werden.

---

## 9. Debian-Docker-Host mit Ansible konfigurieren

Die Konfiguration des Debian-Servers erfolgt über das Playbook:

```text
playbooks/docker-host.yml
```

Das Playbook führt die Rollen in definierter Reihenfolge aus:

```text
common
    ↓
docker
    ↓
homelab
```

### 9.1 `common`

Die `common`-Rolle installiert allgemeine Pakete, die für den Server und die weitere Konfiguration benötigt werden.

Dazu gehören aktuell:

- `ca-certificates`
- `curl`
- `git`
- `gnupg`

### 9.2 `docker`

Die `docker`-Rolle:

- konfiguriert das offizielle Docker-APT-Repository
- installiert Docker Engine
- installiert Docker CLI
- installiert `containerd`
- installiert das Docker Buildx Plugin
- installiert das Docker Compose Plugin
- aktiviert und startet den Docker-Service

### 9.3 `homelab`

Die `homelab`-Rolle ist für die Bereitstellung der eigentlichen Homelab-Konfiguration zuständig und besteht aus zwei Schritten:

```text
GitHub Repository
       ↓
Ansible: Repository nach /homelab klonen/aktualisieren
       ↓
Ansible: homelab-secrets.yml von der Kontrollmaschine laden
       ↓
Ansible: pro App eine .env aus homelab-secrets.yml rendern
       ↓
/homelab/apps/<app>/.env auf dem Debian-Host
```

**Schritt 1 – Repository klonen:** Das vollständige Repository wird auf dem Debian-Docker-Host nach `/homelab` geklont bzw. aktualisiert. Dadurch ist das Repository auch auf dem Docker-Host die zentrale Beschreibung der Homelab-Konfiguration. Da die Docker-Compose-Dateien keine Secrets enthalten, ist dieser Teil unproblematisch öffentlich.

**Schritt 2 – Secrets ausrollen:** Ansible liest `homelab-secrets.yml` direkt von der Kontrollmaschine (die Datei wird dafür nie auf den Server kopiert oder ins Repository committed) und rendert daraus für jede App in `homelab-secrets.yml` eine `.env`-Datei, die per SSH nach `/homelab/apps/<app>/.env` übertragen wird. Neue Apps müssen dafür nur in `homelab-secrets.yml` ergänzt werden — die Rolle selbst muss nicht angepasst werden.

---

## 10. Ansible Playbook ausführen

Das vollständige Playbook ausführen:

```bash
ansible-playbook playbooks/docker-host.yml
```

Beim ersten Durchlauf installiert und konfiguriert Ansible alle noch fehlenden Komponenten.

Ein erfolgreicher Lauf endet mit:

```text
failed=0
unreachable=0
```

Nach dem ersten erfolgreichen Lauf sollte das Playbook erneut ausgeführt werden:

```bash
ansible-playbook playbooks/docker-host.yml
```

Beim zweiten Lauf sollten bereits konfigurierte Komponenten nicht erneut verändert werden. Idealerweise enthält die Zusammenfassung:

```text
changed=0
failed=0
```

Dies bestätigt, dass die Konfiguration idempotent ist.

---

## 11. Homelab Repository auf dem Debian-Host prüfen

Nach erfolgreicher Ausführung der `homelab`-Rolle auf dem Debian-Host anmelden:

```bash
ssh root@192.168.178.202
```

Den Inhalt prüfen:

```bash
ls -la /homelab
```

Das Repository sollte dort vorhanden sein und die gleiche grundlegende Struktur wie die lokale Source of Truth besitzen.

---

## 12. Docker und Docker Compose prüfen

Auf dem Debian-Docker-Host prüfen, ob Docker installiert wurde:

```bash
docker --version
```

Docker Compose prüfen:

```bash
docker compose version
```

Den Docker-Service prüfen:

```bash
systemctl status docker
```

Der Service sollte aktiv sein.

---

## 13. Docker-Anwendungen wiederherstellen

Die Docker-Compose-Konfigurationen der Homelab-Anwendungen liegen im Repository und werden zusammen mit dem Repository auf den Docker-Host übertragen.

Die Compose-Dateien dürfen keine Secrets direkt enthalten. Secrets und umgebungsspezifische Werte kommen aus `homelab-secrets.yml` (siehe Abschnitt 4.1) und werden von der `homelab`-Ansible-Rolle als `.env`-Datei je App bereitgestellt (siehe Abschnitt 9.3).

Das Repository soll grundsätzlich so aufgebaut sein, dass es ohne sensible Daten öffentlich auf GitHub liegen könnte.

Die Wiederherstellung einer Anwendung folgt diesem Ablauf:

```text
Repository aktualisieren
        ↓
Ansible-Playbook ausführen (klont Repo, rendert .env je App aus homelab-secrets.yml)
        ↓
Auf dem Docker-Host je App: docker compose up -d
        ↓
Anwendung läuft
```

Der letzte Schritt (`docker compose up -d` je App) ist aktuell **nicht** automatisiert. Nach einem Ansible-Lauf liegen alle Compose-Dateien und die passenden `.env`-Dateien bereits korrekt unter `/homelab/apps/<app>` auf dem Docker-Host, gestartet werden müssen die Stacks aber noch manuell:

```bash
ssh root@192.168.178.202
cd /homelab/apps/<app>
docker compose up -d
```

Das für alle Apps zu automatisieren (z. B. ein weiterer Task in der `homelab`-Rolle, der das für jeden Ordner unter `apps/` ausführt) ist ein offener Ausbauschritt.

---

## 14. Weiterer Ausbau

Nach erfolgreicher Wiederherstellung des Debian-Docker-Hosts wird die gleiche Ansible-Struktur schrittweise um weitere Docker-Anwendungen erweitert.

Der langfristige Ablauf des Homelabs ist:

```text
Proxmox installieren
        ↓
Repository klonen
        ↓
homelab-secrets.yml aus der Vorlage befüllen
        ↓
Terraform-Variablen daraus rendern (render-terraform-vars.yml)
        ↓
Terraform erstellt die Infrastruktur
        ↓
Ansible konfiguriert die VMs
        ↓
Docker wird installiert
        ↓
Homelab Repository wird auf dem Docker-Host bereitgestellt
        ↓
Ansible rendert je App eine .env aus homelab-secrets.yml
        ↓
Docker Compose startet die Anwendungen (aktuell manuell je App)
        ↓
Homelab ist wiederhergestellt
```

Das GitHub-Repository ist dabei die zentrale Source of Truth für die deklarative Infrastruktur- und Anwendungskonfiguration. Sensible Zugangsdaten und Secrets liegen ausschließlich in `homelab-secrets.yml`, die nie committed wird und nur auf der Kontrollmaschine existiert.
