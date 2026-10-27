#!/usr/bin/env bash

# Linux Performance Analysis Script
# Compatible with most Linux distributions using Bash and /proc.
# No additional packages required on typical Linux installations.

set -o pipefail

# Colours for terminal output
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    YELLOW='\033[1;33m'
    RESET='\033[0m'
else
    GREEN=''
    CYAN=''
    YELLOW=''
    RESET=''
fi

section() {
    printf "\n${CYAN}============================================================${RESET}\n"
    printf "${CYAN} %s${RESET}\n" "$1"
    printf "${CYAN}============================================================${RESET}\n"
}

# Read CPU counters from /proc/stat
read_cpu() {
    local cpu user nice system idle iowait irq softirq steal rest

    read -r cpu user nice system idle iowait irq softirq steal rest \
        < /proc/stat

    CPU_IDLE=$((idle + iowait))
    CPU_TOTAL=$((user + nice + system + idle + iowait + irq + softirq + steal))
}

# Host information
section "LINUX PERFORMANCE REPORT"

printf "Hostname       : %s\n" "$(hostname)"
printf "OS Version     : %s\n" "$(. /etc/os-release && echo "$PRETTY_NAME")"
printf "Date           : %s\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
printf "Kernel         : %s\n" "$(uname -r)"
printf "Architecture   : %s\n" "$(uname -m)"
printf "Uptime         : %s\n" "$(uptime -p 2>/dev/null || uptime)"

# 1. CPU USAGE
section "1. CPU USAGE"

if [[ -r /proc/stat ]]; then
    read_cpu
    idle_before=$CPU_IDLE
    total_before=$CPU_TOTAL

    # Sample CPU counters over one second
    sleep 1

    read_cpu
    idle_after=$CPU_IDLE
    total_after=$CPU_TOTAL

    total_delta=$((total_after - total_before))
    idle_delta=$((idle_after - idle_before))

    if (( total_delta > 0 )); then
        cpu_usage=$(awk -v total="$total_delta" \
            -v idle="$idle_delta" \
            'BEGIN { printf "%.2f", (total-idle)*100/total }')

        printf "Total CPU Usage : %s%%\n" "$cpu_usage"
        printf "Measurement     : 1-second average across all CPUs\n"
    else
        printf "CPU Usage       : Unable to calculate\n"
    fi
else
    printf "CPU Usage       : /proc/stat unavailable\n"
fi

# 2. MEMORY USAGE
section "2. MEMORY USAGE"

if [[ -r /proc/meminfo ]]; then
    mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    mem_available=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    mem_free=$(awk '/^MemFree:/ {print $2}' /proc/meminfo)

    # Fallback for older kernels without MemAvailable
    if [[ -z "$mem_available" ]]; then
        mem_available=$mem_free
    fi

    if [[ "$mem_total" =~ ^[0-9]+$ ]] &&
       [[ "$mem_available" =~ ^[0-9]+$ ]] &&
       (( mem_total > 0 )); then

        mem_used=$((mem_total - mem_available))

        awk -v total="$mem_total" \
            -v used="$mem_used" \
            -v available="$mem_available" '
            BEGIN {
                printf "Total Memory    : %.2f MiB\n", total/1024
                printf "Used Memory     : %.2f MiB (%.2f%%)\n",
                    used/1024, used*100/total
                printf "Free/Available  : %.2f MiB (%.2f%%)\n",
                    available/1024, available*100/total
            }'
    else
        printf "Memory Usage    : Unable to read memory information\n"
    fi
else
    printf "Memory Usage    : /proc/meminfo unavailable\n"
fi

printf "${YELLOW}Note: Available memory includes reclaimable cache.${RESET}\n"

# 3. DISK USAGE
section "3. DISK USAGE"

if command -v df >/dev/null 2>&1; then
    printf "%-24s %10s %10s %10s %7s  %s\n" \
        "FILESYSTEM" "TOTAL" "USED" "FREE" "USED%" "MOUNTPOINT"

    df -P -k -x tmpfs -x devtmpfs 2>/dev/null |
        awk '
        NR > 1 && $2 ~ /^[0-9]+$/ && $2 > 0 {
            total = $2
            used = $3
            free = $4
            pct = used * 100 / total

            printf "%-24.24s %9.1fG %9.1fG %9.1fG %6.1f%%  %s\n",
                $1, total/1048576, used/1048576,
                free/1048576, pct, $6
        }'
else
    printf "Disk Usage      : df command unavailable\n"
fi

printf "${YELLOW}Note: Disk figures use filesystem-reported capacity.${RESET}\n"

# 4. TOP 5 PROCESSES BY CPU
section "4. TOP 5 PROCESSES BY CPU"

if command -v ps >/dev/null 2>&1; then
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu 2>/dev/null |
        awk 'NR == 1 {printf "%-8s %-25s %10s %10s\n",
                         "PID", "PROCESS", "CPU%", "MEM%"}
             NR > 1 && NR <= 6 {
                 printf "%-8s %-25.25s %10s %10s\n",
                     $1, $2, $3, $4
             }'
else
    printf "Process listing unavailable\n"
fi

# 5. TOP 5 PROCESSES BY MEMORY
section "5. TOP 5 PROCESSES BY MEMORY"

if command -v ps >/dev/null 2>&1; then
    ps -eo pid,comm,%mem,%cpu --sort=-%mem 2>/dev/null |
        awk 'NR == 1 {printf "%-8s %-25s %10s %10s\n",
                         "PID", "PROCESS", "MEM%", "CPU%"}
             NR > 1 && NR <= 6 {
                 printf "%-8s %-25.25s %10s %10s\n",
                     $1, $2, $3, $4
             }'
else
    printf "Process listing unavailable\n"
fi

section "REPORT COMPLETE"
printf "Finished at    : %s\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')"

# 6. NETWORKING - LISTENING PORTS
section "6. NETWORKING - LISTENING PORTS"

if command -v ss >/dev/null 2>&1; then
    printf "%-8s %-30s %-15s %-25s\n" "PROTO" "LOCAL ADDRESS" "STATE" "PROCESS"
    
    ss -tulpn 2>/dev/null | awk '
    NR > 1 {
        proto = $1
        state = $2
        local_addr = $4
        process = ($7 != "" ? $7 : "N/A")
        
        # Clean up process string formatting from ss output
        gsub(/users:\(\(/, "", process)
        gsub(/\),\)/, "", process)
        gsub(/"/, "", process)
        
        printf "%-8s %-30s %-15s %-25.25s\n", proto, local_addr, state, process
    }'
elif command -v netstat >/dev/null 2>&1; then
    netstat -tulpn 2>/dev/null | awk '
    NR > 2 {
        printf "%-8s %-30s %-15s %-25s\n", $1, $4, $6, $7
    }'
else
    printf "Port listing unavailable (neither ss nor netstat found)\n"
fi

printf "${YELLOW}Note: Showing listening TCP/UDP ports. Process names may require root/sudo privileges.${RESET}\n"