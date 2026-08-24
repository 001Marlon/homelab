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

## 2. Proxmox API-Zugang für Terraform erstellen

Nach der Proxmox-Installation wird ein eigener Benutzer für Terraform angelegt.

### 2.1 Terraform-Benutzer und Rolle erstellen

Auf dem Proxmox-Host als `root` ausführen:

```bash
pveum user add terraform@pve

pveum role add TerraformRole -privs "Datastore.AllocateSpace,Datastore.Allocate,Datastore.Audit,Datastore.AllocateTemplate,Pool.Allocate,Sys.Audit,Sys.Console,Sys.Modify,Sys.AccessNetwork,VM.Allocate,VM.Audit,VM.Clone,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Migrate,VM.PowerMgmt,VM.Snapshot,SDN.Use"

pveum acl modify / -user terraform@pve -role TerraformRole
```

### 2.2 API-Token erstellen

Den Terraform-API-Token ohne Privilege Separation erstellen:

```bash
pveum user token add terraform@pve terraform --privsep 0
```

> **Wichtig:** Den ausgegebenen Token direkt sicher zwischenspeichern. Der Secret-Wert wird später für Terraform benötigt.

---

## 3. Homelab Repository lokal klonen

Das Repository enthält den Terraform-Code sowie die restliche Homelab-Konfiguration.

### 3.1 WSL bzw. Linux-Terminal öffnen

Unter Windows kann dafür WSL verwendet werden.

### 3.2 Repository klonen

```bash
git clone git@github.com:001Marlon/homelab.git
```

Anschließend in das Repository wechseln:

```bash
cd homelab
```

---

## 4. Terraform installieren

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

## 5. Terraform konfigurieren

Terraform verwendet Umgebungsvariablen für die Zugangsdaten zu Proxmox.

### 5.1 Proxmox-Variablen setzen

```bash
export TF_VAR_proxmox_endpoint="https://192.168.178.200:8006/"
export TF_VAR_proxmox_api_token="terraform@pve!terraform=DEIN_TOKEN"
export TF_VAR_ssh_public_key="DEIN_SSH_PUBLIC_KEY"
```

`DEIN_TOKEN` durch den zuvor erstellten Proxmox-API-Token ersetzen.
`DEIN_SSH_PUBLIC_KEY` durch deinen öffentlichen SSH-Key ersetzen.

### 5.2 In das Proxmox-Terraform-Verzeichnis wechseln

```bash
cd infrastructure/proxmox/terraform
```

### 5.3 Terraform initialisieren

```bash
terraform init
```

Dadurch werden unter anderem die benötigten Terraform-Provider heruntergeladen.

---

## 6. Infrastruktur mit Terraform erstellen

### 6.1 Terraform Plan erstellen

Zunächst prüfen, welche Änderungen Terraform durchführen würde:

```bash
terraform plan
```

Den Plan kontrollieren.

### 6.2 Infrastruktur erstellen

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

---

## Wiederherstellungsablauf im Überblick

```text
┌─────────────────────────────┐
│ 1. Proxmox installieren     │
│    Auto-Installer           │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 2. Terraform API-Zugang     │
│    User + Role + Token       │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 3. Git Repository klonen     │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 4. Terraform installieren   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 5. Terraform konfigurieren  │
│    Variablen + init         │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│ 6. terraform plan            │
│    ↓                         │
│    terraform apply           │
└─────────────────────────────┘
```

## Aktueller Stand

Nach Schritt 6 sollte Terraform die grundlegende Proxmox-Infrastruktur wiederherstellen, insbesondere die im Terraform-Code definierten VMs und Ressourcen.

Weitere Konfigurationen wie Debian, Docker, Docker-Compose-Stacks und Anwendungen werden anschließend über die dafür vorgesehenen Terraform-/Ansible-Konfigurationen des Repositories wiederhergestellt.
