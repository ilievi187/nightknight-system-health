# NightKnight System Health

A small Bash health checker for Linux, built for quick terminal diagnostics.

It reports:
- uptime and system load
- RAM usage
- root filesystem usage
- CPU, GPU and NVMe temperatures via `lm_sensors`
- discrete AMD GPU PCIe link, load and VRAM usage
- AMDGPU error count for the current and previous boot
- CPU/watchdog warning count
- serious NVMe error-like messages
- top CPU-consuming processes

## Run

```bash
chmod +x system-health.sh
./system-health.sh
```

## Notes

The GPU section automatically picks the DRM device with the largest VRAM pool, so it works on systems that expose the integrated GPU and discrete AMD GPU in different card order.

The kernel-health section uses `journalctl`, so persistent systemd journal logs are useful for checking the previous boot.

Designed and tested on Omarchy / Arch Linux.

## Diagnose a crash after reboot

By default, inspect the previous boot:

```bash
./diagnose-last-boot.sh
```

Inspect an older boot by index:

```bash
./diagnose-last-boot.sh -2
```

This focuses on AMDGPU reset/timeouts, CPU watchdog or MCE/EDAC events, NVMe failures and PCIe/AER errors.