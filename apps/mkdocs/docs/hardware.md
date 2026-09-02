# Hardware

## Proxmox-Host

| Komponente | Wert |
| --- | --- |
| CPU | AMD Ryzen 7 5700G (8C/16T) |
| Mainboard | ASRock B550M-ITX/ac |
| RAM | 64 GB DDR4 (2×32 GB) |
| System-Disk | Samsung 990 PRO NVMe (1 TB) |
| Daten-Disks | 4× 4 TB HDD |

## Aufteilung

Die NVMe trägt reaktionskritische Workloads: Datenbanken, Suchindizes, App-Konfiguration. Die HDDs sind für große, weniger latenzkritische Daten reserviert: Medien, Archive, Langzeit-Speicher.

Storage-seitig I/O-intensive Apps: Immich, Paperless (beide viel Metadaten-/Datenbank-Zugriff).

## Ausbau-Reihenfolge bei Bedarf

1. NVMe-Kapazität für Metadaten/Datenbanken erweitern
2. Heiße und kalte Daten konsequenter trennen
3. Vom App-Host unabhängiges Backup-Ziel einrichten
