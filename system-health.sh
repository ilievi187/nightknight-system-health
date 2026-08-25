#!/usr/bin/env bash
set -u

BOLD='\033[1m'
CYAN='\033[36m'
YELLOW='\033[33m'
RESET='\033[0m'

section() {
  printf '\n%b== %s ==%b\n' "$BOLD$CYAN" "$1" "$RESET"
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
    /Tctl:|Tdie:|Package id 0:|edge:|junction:|Composite:/ {
      print "  " $0
    }
  '
else
  printf '%b%s%b\n' "$YELLOW" 'lm_sensors not installed' "$RESET"
fi

section 'Top CPU Processes'
ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 8

section 'Summary'
printf 'CPU cores: %s\n' "$(nproc)"
printf 'Root usage: %s\n' "$(df -h / | awk 'NR==2 {print $5}')"
printf 'Memory used: %s / %s\n' \
  "$(free -h | awk '/Mem:/ {print $3}')" \
  "$(free -h | awk '/Mem:/ {print $2}')"
