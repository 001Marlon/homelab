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

Das Repository enthält den Terraform-Code sowie die restliche Homelab-Konfiguration.

### 2.1 WSL bzw. Linux-Terminal öffnen

Unter Windows kann dafür WSL verwendet werden.

### 2.2 Repository klonen

```bash
git clone git@github.com:001Marlon/homelab.git
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

> **Hinweis:** Ein separater `terraform@pve`-Benutzer mit eigener Rolle und API-Token wird nicht mehr benötigt. Der Provider authentifiziert sich direkt als `root@pam` (Benutzername + Passwort), da die TrueNAS-VM per Disk-Passthrough auf die physischen HDDs zugreift – und das erlaubt Proxmox ausschließlich einer echten `root@pam`-Session, nicht mal einem API-Token mit vollen Rechten. `root@pam` existiert bereits automatisch nach der Proxmox-Installation, es ist also kein zusätzlicher Setup-Schritt auf dem Proxmox-Host nötig.

### 4.1 tfvars-Datei anlegen

Terraform verwendet eine `.tfvars`-Datei für alle Zugangsdaten und Konfigurationswerte. Da `homelab.tfvars` sensible Daten (u. a. das Proxmox-Root-Passwort) enthält, liegt sie nicht im Repository – stattdessen gibt es dort nur eine Vorlage.

Im Terraform-Verzeichnis eine Kopie der Vorlage erstellen:

```bash
cp homelab.tfvars.example homelab.tfvars
```

Anschließend `homelab.tfvars` öffnen und die nötigen Werte anpassen, u. a.:

- `ssh_public_key` – eigener öffentlicher SSH-Key
- Proxmox-Zugangsdaten (`proxmox_endpoint`, `proxmox_username`, `proxmox_password`)
- ggf. weitere umgebungsspezifische Werte (VM-IDs, IPs, HDD-IDs etc.)

> **Wichtig:** `homelab.tfvars` niemals ins Git-Repo committen – sie enthält das Proxmox-Root-Passwort.

### 4.2 In das Proxmox-Terraform-Verzeichnis wechseln

```bash
cd infrastructure/proxmox/terraform
```

### 4.3 Terraform initialisieren

```bash
terraform init
```

Dadurch werden unter anderem die benötigten Terraform-Provider heruntergeladen.

---

## 5. Infrastruktur mit Terraform erstellen

Ab hier muss die `.tfvars`-Datei bei **jedem** Terraform-Befehl über `-var-file` mitgegeben werden.

### 5.1 Terraform Plan erstellen

Zunächst prüfen, welche Änderungen Terraform durchführen würde:

```bash
terraform plan -var-file="homelab.tfvars"
```

Den Plan kontrollieren.

### 5.2 Infrastruktur erstellen

Wenn der Plan korrekt aussieht:

```bash
terraform apply -var-file="homelab.tfvars"
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