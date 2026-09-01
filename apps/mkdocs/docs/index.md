# Homelab Handbook

<div class="hero">
  <p class="hero-kicker">Self-hosted platform</p>
  <h1>One place for operations, not guesswork.</h1>
  <p class="hero-lead">This documentation is written for day-to-day use: what runs, where it runs, and what to check first when something breaks.</p>
</div>

<div class="grid cards" markdown>

- :material-rocket-launch: **Start Here**

  ---

  New deployment? Read [Platform Layout](platform.md) first.

- :material-monitor-dashboard: **Live Services**

  ---

  Open [Service Inventory](services.md) for ports, purpose, and exposure.

- :material-wrench-clock: **On-call Basics**

  ---

  Use [Operations Runbook](operations.md) for updates, restore, and incident flow.

- :material-shield-check: **Risk Controls**

  ---

  Security priorities are listed in [Security Notes](security.md).

</div>

## What matters most

!!! warning "Public edge"
    `cloudflare-tunnel` and `playit-tunnel` are your external entry points. Treat changes there as high-impact.

!!! warning "Single source of truth"
    Compose stacks live under `/homelab/apps/<service>`. Keep paths consistent across Dockge, Komodo, and manual `docker compose` commands.

!!! info "Fast health check"
    If you only have two minutes: verify `uptime-kuma`, `portainer`, `cloudflare-tunnel`, and `immich`.

## Current service footprint

- Total compose projects: `17`
- Primary stack root: `/homelab/apps`
- Typical maintenance command:

```bash
cd /homelab/apps/<service>
docker compose pull && docker compose up -d
```
