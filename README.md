# NightKnight System Health

A tiny Bash system-health checker for Linux.

It reports:
- uptime and load
- RAM usage
- root filesystem usage
- CPU / GPU / NVMe temperatures from `lm_sensors`
- top CPU-consuming processes
- a short summary

## Run

```bash
chmod +x system-health.sh
./system-health.sh
```

Designed and tested on Omarchy / Arch Linux.
