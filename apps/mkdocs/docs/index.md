# Homelab Wiki

Dokumentation für Betrieb, Wiederherstellung und Aufbau des Homelabs.

## Bereiche

| Seite | Inhalt |
| --- | --- |
| [Architektur](platform.md) | Aufbau von Proxmox bis zur einzelnen App, Secrets-Fluss |
| [Hardware](hardware.md) | Server-Spezifikationen |
| [Services](services.md) | Alle laufenden Apps mit Port und Erreichbarkeit |
| [Runbook](operations.md) | Wiederkehrende Aufgaben: Updates, neue App, neuer Reverse-Proxy-Eintrag |
| [Sicherheit](security.md) | Umgang mit Secrets, Zugriffsschutz |
| [Disaster Recovery](disaster-recovery.md) | Vollständige Wiederherstellung nach Totalausfall |

## Kurzüberblick

Das Homelab läuft auf einem Proxmox-Host zu Hause. Terraform erstellt daraus die VMs, Ansible installiert Docker und startet die Anwendungen. Ein separater VPS stellt über NetBird den öffentlichen Zugriff auf ausgewählte Apps bereit. Alle Zugangsdaten liegen zentral in einer einzigen, nicht versionierten Datei (`homelab-secrets.yml`) - Details dazu unter [Sicherheit](security.md).

Das GitHub-Repository [`001Marlon/homelab`](https://github.com/001Marlon/homelab) ist die alleinige Quelle für Infrastruktur- und Anwendungskonfiguration und enthält keine sensiblen Daten.
