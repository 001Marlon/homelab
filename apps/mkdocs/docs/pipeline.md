# Pipeline (GitHub Actions)

GitHub ist die Quelle der Wahrheit. Ein Push genügt, den Rest erledigt die Pipeline. Lokal muss weder Terraform noch Ansible installiert sein.

## Ablauf

```text
Push auf main (homelab)         Push auf main (private-homelab-secrets)
        │                                   │
        ▼                                   │
"Trigger deploy" (GitHub-Cloud)             │
  stößt per repository_dispatch an ─────────┤
                                            ▼
                     "Deploy" auf homelab-runner01 (im Heimnetz)
                       1. Ansible docker-host.yml
                          /homelab aktualisieren, .env rendern,
                          neue Images ziehen, docker compose up -d
                       2. Ansible sync-reverse-proxy.yml
                       3. terraform plan → Ergebnis in der Job-Zusammenfassung

Per Klick:    "Terraform apply"  → apply, State wird ins Secrets-Repo committet
Sonntags:     "Update images"    → dasselbe ohne Push, damit :latest-Images
                                   auch in ruhigen Wochen aktuell bleiben
```

Alle Workflows mit Zugriff aufs Heimnetz liegen im **privaten** Repo `private-homelab-secrets` (Ordner `.github/workflows/`). Das öffentliche Repo enthält nur `trigger-deploy.yml`, das auf einem GitHub-Cloud-Runner läuft und nichts im Heimnetz ausführt. Pull Requests (auch von Forks) lösen keinen Deploy aus.

Es läuft immer nur ein Workflow gleichzeitig gegen das Homelab (`concurrency: homelab`), weitere warten.

## Terraform-Änderungen anwenden

1. Änderung an `infrastructure/proxmox/terraform` pushen.
2. Im privaten Repo unter **Actions → Deploy** den Lauf öffnen. Die Zusammenfassung zeigt den Plan.
3. Passt der Plan: **Actions → Terraform apply → Run workflow → Run workflow**.

Der Apply rechnet den Plan unmittelbar vorher neu. Zwischen Ansehen und Klick sollte also niemand etwas pushen.

## Image-Updates

Jeder Deploy zieht die neuesten Images (`docker compose pull`) und startet nur die Container neu, deren Image sich geändert hat. Wer `:latest` als Tag setzt, bekommt also bei jedem Push die aktuelle Version. Danach werden nicht mehr genutzte Images gelöscht.

Zusätzlich läuft **Update images** sonntags um 03:00 UTC, auch wenn in der Woche nichts gepusht wurde. Soll eine App auf einer Version bleiben, im Compose-File einen festen Tag statt `latest` setzen.

## Runner `homelab-runner01`

| | |
|---|---|
| Typ | Unprivilegierter LXC auf Proxmox, ID 103 |
| IP | 192.168.178.203 |
| Labels | `self-hosted`, `homelab` |
| Software | GitHub Actions Runner (aktualisiert sich selbst), Ansible (Debian-Paket), Terraform (feste Version im Playbook) |
| Zugang zum Debian-Host | SSH-Schlüssel `github-actions-homelab-runner01` (User `runner`) in `/root/.ssh/authorized_keys` auf homelab-debian01 |
| Zugang zu Proxmox | API-Token `terraform@pve!github-actions-homelab-runner01`, Rolle `TerraformRole`, kein root |

Der Runner verbindet sich ausgehend zu GitHub. Im Router muss kein Port geöffnet werden.

### Henne-Ei: Der Runner verwaltet sich nicht selbst

Der Runner gehört zur **Bootstrap-Schicht**. Die Pipeline verwaltet alles außer dem Runner, auf dem sie selbst läuft. Sonst könnte ein Apply den Runner mitten im Job ersetzen.

- Terraform: `infrastructure/bootstrap/terraform/` (eigener State: `terraform/bootstrap.tfstate` im Secrets-Repo)
- Einrichtung: `infrastructure/ansible/playbooks/github-runner.yml`

Änderungen daran werden **von Hand** angewendet. Siehe Abschnitt „Runner neu aufsetzen“ in der [Disaster Recovery](disaster-recovery.md#runner-neu-aufsetzen).

## Zugangsdaten

| Was | Wo |
|---|---|
| Alle App-Secrets, Proxmox-API-Token, Terraform-State | Privates Repo, wird pro Lauf ausgecheckt und danach aus dem Arbeitsordner gelöscht |
| `HOMELAB_DISPATCH_TOKEN` | Actions-Secret im öffentlichen Repo. Fine-grained Token `homelab-deploy-dispatch`, nur `private-homelab-secrets`, nur *Contents: Read and write*. **Läuft nach einem Jahr ab** und muss dann erneuert werden. Ohne Token schlägt „Trigger deploy“ fehl. |

## Störungen

- **Workflow hängt auf „Waiting for a runner“.** Der Runner ist offline. Auf Proxmox prüfen, ob LXC 103 läuft, dann `ssh root@192.168.178.203 'cd /home/runner/actions-runner && ./svc.sh status'`.
- **„Trigger deploy“ schlägt mit 401/403 fehl.** `HOMELAB_DISPATCH_TOKEN` ist abgelaufen oder falsch.
- **Notfall ohne Pipeline.** Alle Playbooks funktionieren weiterhin von Hand, siehe [Runbook](operations.md).
