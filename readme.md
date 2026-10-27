# Linux Performance Analyzer

A lightweight, zero-dependency Bash script designed to generate a comprehensive system performance snapshot instantly. It reads directly from the Linux `/proc` filesystem and standard core utilities without requiring external packages like `sysstat` or `bc`.

---

## Features

* **Host & Kernel Overview:** Captures hostname, current timestamp, kernel version, architecture, and system uptime.
* **Accurate CPU Sampling:** Measures true CPU utilization via a 1-second delta calculation across all cores using `/proc/stat`.
* **Memory Breakdown:** Computes total, used, and available RAM using `/proc/meminfo` (accounting for reclaimable cache).
* **Filesystem Disk Usage:** Filters out virtual filesystems (`tmpfs`, `devtmpfs`) to display real disk utilization via `df`.
* **Resource Hog Identification:** Lists the top 5 processes consuming the highest CPU and Memory.

---

## Prerequisites

* **Operating System:** Any modern Linux distribution.
* **Shell:** Bash (v4.0+ recommended).
* **Dependencies:** Standard core utilities (`awk`, `uname`, `uptime`, `df`, `ps`). No extra installations needed.

---

## Installation & Usage

1. **Clone or download the script:**
   ```bash
   git clone https://github.com/your-username/linux-performance-repo.git
   cd linux-performance-repo
   ```

2. **Make the script executable:**
   ```bash
   chmod +x linux-performance.sh
   ```

3. **Run the script:**
   ```bash
   ./linux-performance.sh
   ```

---

## Example Output

```text
============================================================
 LINUX PERFORMANCE REPORT
============================================================
Hostname        : localhost
Date            : 2026-10-27 22:15:00 +08
Kernel          : 6.8.0-31-generic
Architecture    : x86_64
Uptime          : up 4 days, 12 hours, 30 minutes

============================================================
 1. CPU USAGE
============================================================
Total CPU Usage : 12.50%
Measurement     : 1-second average across all CPUs

============================================================
 2. MEMORY USAGE
============================================================
Total Memory    : 16384.00 MiB
Used Memory     : 4520.10 MiB (27.59%)
Free/Available  : 11863.90 MiB (72.41%)
Note: Available memory includes reclaimable cache.

============================================================
 3. DISK USAGE
============================================================
FILESYSTEM                  TOTAL       USED       FREE    USED%  MOUNTPOINT
/dev/nvme0n1p2             158.3G      65.2G      85.1G   43.4%  /
Note: Disk figures use filesystem-reported capacity.

============================================================
 4. TOP 5 PROCESSES BY CPU
============================================================
PID      PROCESS                        CPU%       MEM%      
1420     gnome-shell                     3.5        2.1      
2104     code                            2.1        4.5      
1        systemd                         0.0        0.2      

============================================================
 5. TOP 5 PROCESSES BY MEMORY
============================================================
PID      PROCESS                        MEM%       CPU%      
2104     code                            4.5        2.1      
1420     gnome-shell                     2.1        3.5      
1        systemd                         0.2        0.0      

============================================================
 REPORT COMPLETE
============================================================
Finished at     : 2026-10-27 22:15:01 +08
```

---

## License

Open-source under the [MIT License](LICENSE).