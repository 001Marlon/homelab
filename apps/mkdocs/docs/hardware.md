# Hardware Profile

## Host specification

| Component | Value |
| :--- | :--- |
| CPU | AMD Ryzen 7 5700G (8c/16t) |
| Mainboard | ASRock B550M-ITX/ac |
| RAM | 64 GB DDR4 (2x32 GB) |
| System disk | Samsung 990 PRO NVMe (1 TB) |
| Capacity disks | 4x 4 TB HDD |

## Capacity intent

- NVMe is reserved for responsive workloads: databases, indexes, metadata, app config.
- HDD capacity is reserved for heavy data: media, archives, long-term storage.

## Practical constraints

- Some services are I/O sensitive (`immich`, `paperless`, metadata-heavy apps).
- Game workloads can spike CPU + disk at the same time.
- Monitoring and docs should stay lightweight and always available.

## Upgrade priorities

If growth continues, recommended order:

1. Expand NVMe capacity for service metadata and DBs.
2. Separate hot data and cold archive more aggressively.
3. Add explicit backup target independent from app host.
