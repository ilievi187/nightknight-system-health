#!/usr/bin/env bash
set -u

BOOT="${1:--1}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="$SCRIPT_DIR/reports"
STAMP="$(date '+%Y%m%d-%H%M%S')"
REPORT="$REPORT_DIR/crash-${STAMP}-boot${BOOT#-}.txt"
mkdir -p "$REPORT_DIR"

section() {
  printf '\n===== %s =====\n' "$1"
}

exec > >(tee "$REPORT") 2>&1
printf 'NightKnight Crash Report\n'
printf 'Generated: %s\n' "$(date --iso-8601=seconds)"
printf 'Boot index: %s\n' "$BOOT"
printf 'Host: %s\n' "$(hostname)"
printf 'Kernel: %s\n' "$(uname -r)"
printf 'Command line: %s\n' "$(cat /proc/cmdline)"

section 'System Health Now'
"$SCRIPT_DIR/system-health.sh" || true

section 'Boot History'
journalctl --list-boots --no-pager | tail -12

section 'Target Boot Kernel Errors'
journalctl -k -b "$BOOT" --no-pager 2>/dev/null | grep -Ei \
  'amdgpu|DMCUB|SMU: No response|ring .*timeout|GPU reset|watchdog|soft lockup|hard lockup|rcu.*stall|MCE|machine check|hardware error|EDAC|nvme.*(i/o error|timeout|controller reset|csts|abort)|AER|PCIe Bus Error' \
  | tail -400 || true

section 'Target Boot Last 120 Lines'
journalctl -b "$BOOT" --no-pager 2>/dev/null | tail -120 || true

section 'Hardware Summary'
lspci -nnk | grep -A3 -Ei 'VGA|Display|Non-Volatile' || true
lsblk -o NAME,MODEL,SIZE,FSTYPE,MOUNTPOINTS || true

printf '\nSaved report: %s\n' "$REPORT"
