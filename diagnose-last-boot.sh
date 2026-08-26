#!/usr/bin/env bash
set -u

BOLD='\033[1m'
CYAN='\033[36m'
RESET='\033[0m'

section() {
  printf '\n%b== %s ==%b\n' "$BOLD$CYAN" "$1" "$RESET"
}

BOOT=${1:--1}
printf '%bNightKnight Previous-Boot Diagnostics%b\n' "$BOLD" "$RESET"
printf 'Inspecting boot: %s\n' "$BOOT"
printf 'Generated: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"

section 'Boot Summary'
journalctl --list-boots --no-pager | tail -10

section 'AMDGPU / GPU Reset Events'
journalctl -k -b "$BOOT" --no-pager 2>/dev/null | \
  grep -Ei 'amdgpu|dmcub|smu: no response|ring .*timeout|gpu reset|scheduler .*not ready' | \
  tail -160 || true

section 'CPU / RAM / Watchdog Events'
journalctl -k -b "$BOOT" --no-pager 2>/dev/null | \
  grep -Ei 'mce|machine check|hardware error|edac|watchdog.*timed out|soft lockup|hard lockup|rcu.*stall' | \
  tail -100 || true
section 'NVMe / Storage Events'
journalctl -k -b "$BOOT" --no-pager 2>/dev/null | \
  grep -Ei 'nvme.*(i/o error|timeout|controller reset|csts|abort)|blk_update_request|buffer i/o error' | \
  tail -100 || true

section 'PCIe / AER Events'
journalctl -k -b "$BOOT" --no-pager 2>/dev/null | \
  grep -Ei 'aer:|pcie.*error|pcie bus error|uncorrected.*error|corrected.*error' | \
  tail -100 || true

section 'Last 80 Kernel Lines'
journalctl -k -b "$BOOT" --no-pager 2>/dev/null | tail -80

printf '\nTip: pass another boot index, e.g. %s -2\n' "$0"