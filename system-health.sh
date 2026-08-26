#!/usr/bin/env bash
set -u

BOLD='\033[1m'
CYAN='\033[36m'
YELLOW='\033[33m'
RED='\033[31m'
GREEN='\033[32m'
RESET='\033[0m'

section() {
  printf '\n%b== %s ==%b\n' "$BOLD$CYAN" "$1" "$RESET"
}

value_or_na() {
  local file="$1"
  [[ -r "$file" ]] && cat "$file" || printf 'n/a'
}

printf '%bNightKnight System Health%b\n' "$BOLD" "$RESET"
printf 'Time: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
printf 'Host: %s\n' "$(hostname)"
printf 'Kernel: %s\n' "$(uname -r)"

section 'Uptime & Load'
uptime

section 'Memory'
free -h
section 'Disk Usage'
df -h / | awk 'NR==1 || NR==2'

section 'Temperatures'
if command -v sensors >/dev/null 2>&1; then
  sensors | awk '
    /^(k10temp|amdgpu|nvme|coretemp)/ {
      chip=$0
      print "\n" chip
    }
    /Tctl:|Tdie:|Package id 0:|edge:|junction:|mem:|Composite:/ {
      print "  " $0
    }
  '
else
  printf '%b%s%b\n' "$YELLOW" 'lm_sensors not installed' "$RESET"
fi

section 'Discrete AMD GPU'
GPU_DEV=$(for d in /sys/class/drm/card*/device; do [[ -r "$d/mem_info_vram_total" ]] && printf '%s %s\n' "$(cat "$d/mem_info_vram_total")" "$d"; done | sort -nr | awk 'NR==1 {print $2}')
if [[ -n "${GPU_DEV:-}" && -d "$GPU_DEV" ]]; then
  printf 'PCIe speed: %s\n' "$(value_or_na "$GPU_DEV/current_link_speed")"
  printf 'PCIe width: x%s\n' "$(value_or_na "$GPU_DEV/current_link_width")"
  printf 'GPU busy: %s%%\n' "$(value_or_na "$GPU_DEV/gpu_busy_percent")"
  if [[ -r "$GPU_DEV/mem_info_vram_used" && -r "$GPU_DEV/mem_info_vram_total" ]]; then
    awk -v u="$(cat "$GPU_DEV/mem_info_vram_used")" -v t="$(cat "$GPU_DEV/mem_info_vram_total")" 'BEGIN {printf "VRAM: %.2f / %.2f GiB\n", u/1073741824, t/1073741824}'
  fi
else
  printf '%bDiscrete GPU sysfs path not found%b\n' "$YELLOW" "$RESET"
fi
section 'Recent Kernel Health'
GPU_ERRORS=$(journalctl -k -b --no-pager 2>/dev/null | grep -Eic 'amdgpu.*(error|timeout|reset failed|SMU: No response|DMCUB)')
PREV_GPU_ERRORS=$(journalctl -k -b -1 --no-pager 2>/dev/null | grep -Eic 'amdgpu.*(error|timeout|reset failed|SMU: No response|DMCUB)')
CPU_WATCHDOG=$(journalctl -k -b --no-pager 2>/dev/null | grep -Eic 'watchdog.*timed out|soft lockup|hard lockup|rcu.*stall')
NVME_ERRORS=$(journalctl -k -b --no-pager 2>/dev/null | grep -Eic 'nvme.*(i/o error|timeout|controller reset|csts|abort)')

printf 'AMDGPU errors this boot: %s\n' "$GPU_ERRORS"
printf 'AMDGPU errors previous boot: %s\n' "$PREV_GPU_ERRORS"
printf 'CPU/watchdog warnings this boot: %s\n' "$CPU_WATCHDOG"
printf 'NVMe error-like messages this boot: %s\n' "$NVME_ERRORS"

if (( GPU_ERRORS > 0 || CPU_WATCHDOG > 0 )); then
  printf '%bHealth flag: CHECK LOGS%b\n' "$RED" "$RESET"
else
  printf '%bHealth flag: OK%b\n' "$GREEN" "$RESET"
fi

section 'Top CPU Processes'
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 8

section 'Summary'
printf 'CPU threads: %s\n' "$(nproc)"
printf 'Root usage: %s\n' "$(df -h / | awk 'NR==2 {print $5}')"
printf 'Memory used: %s / %s\n' \
  "$(free -h | awk '/Mem:/ {print $3}')" \
  "$(free -h | awk '/Mem:/ {print $2}')"