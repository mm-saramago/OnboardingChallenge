#!/bin/bash

# Get metrics
HOSTNAME=$(hostname)
DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# CPU usage
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'.' -f1)
CPU_USAGE=$((100 - CPU_IDLE))

# Load averages
read LOAD1 LOAD5 LOAD15 _ < /proc/loadavg

# Memory usage (in MB)
read _ TOTAL USED FREE _ <<< $(free -m | awk '/Mem:/ {print $1, $2, $3, $4}')

# Disk usage
DISK_TOTAL=$(df -h --total | grep total | awk '{print $2}')
DISK_USED=$(df -h --total | grep total | awk '{print $3}')
DISK_FREE=$(df -h --total | grep total | awk '{print $4}')
DISK_USAGE=$(df -h --total | grep total | awk '{print $5}')

# Uptime (in human-readable and seconds)
UPTIME_HUMAN=$(uptime -p)
UPTIME_SECONDS=$(awk '{print int($1)}' /proc/uptime)

# Output JSON
cat <<EOF
{
  "hostname": "$HOSTNAME",
  "timestamp": "$DATE",
  "cpu": {
    "usage_percent": $CPU_USAGE,
    "load_avg": {
      "1min": $LOAD1,
      "5min": $LOAD5,
      "15min": $LOAD15
    }
  },
  "memory": {
    "total_mb": $TOTAL,
    "used_mb": $USED,
    "free_mb": $FREE
  },
  "disk": {
    "total": "$DISK_TOTAL",
    "used": "$DISK_USED",
    "free": "$DISK_FREE",
    "usage_percent": "$DISK_USAGE"
  },
  "uptime": {
    "human": "$UPTIME_HUMAN",
    "seconds": $UPTIME_SECONDS
  }
}
EOF
