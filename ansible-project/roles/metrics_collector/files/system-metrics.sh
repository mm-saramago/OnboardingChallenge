#!/bin/bash

# Get CPU usage (1 second sample)
cpu_usage() {
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$3+$4+$5)} END {print usage}' 2>/dev/null || echo "0"
}

# Get memory usage percentage
memory_usage() {
    free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}' 2>/dev/null || echo "0"
}

# Get disk usage percentage for root
disk_usage() {
    df / | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0"
}

# Get uptime in seconds
uptime_seconds() {
    cat /proc/uptime | awk '{print int($1)}' 2>/dev/null || echo "0"
}

# Create metrics directory
mkdir -p /tmp/metrics

# Get values first
CPU=$(cpu_usage)
MEM=$(memory_usage) 
DISK=$(disk_usage)
UPTIME=$(uptime_seconds)
HOST=$(hostname)

# Output JSON (your original format)
cat << EOF > /var/log/metrics.json
{
  "timestamp": "$(date -u +%s)",
  "hostname": "$HOST",
  "metrics": {
    "cpu_usage_percent": $CPU,
    "memory_usage_percent": $MEM,
    "disk_usage_percent": $DISK,
    "uptime_seconds": $UPTIME
  }
}
EOF

# Output Prometheus format to the correct location for docker mount
cat << EOF > /tmp/metrics/custom_metrics.prom
# HELP custom_cpu_usage_percent CPU usage percentage
# TYPE custom_cpu_usage_percent gauge
custom_cpu_usage_percent $CPU

# HELP custom_memory_usage_percent Memory usage percentage
# TYPE custom_memory_usage_percent gauge
custom_memory_usage_percent $MEM

# HELP custom_disk_usage_percent Disk usage percentage
# TYPE custom_disk_usage_percent gauge
custom_disk_usage_percent $DISK

# HELP custom_uptime_seconds System uptime in seconds
# TYPE custom_uptime_seconds gauge
custom_uptime_seconds $UPTIME
EOF