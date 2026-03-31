#!/bin/bash
# Script cek kesehatan server versi sederhana

echo "==================================="
echo "  SERVER HEALTH CHECK"
echo "==================================="
echo "Waktu    : $(date)"
echo "Hostname : $(hostname)"
echo "User     : $(whoami)"
echo ""
# Uptime
echo "-- UPTIME & LOAD --"
uptime
echo ""

# Memory
echo "-- MEMORY --"
free -h
echo ""

# Disk
echo "-- DISK --"
df -h | grep -E '^/dev|Filesystem'
echo ""

# Service
echo "-- SERVICE --"
for service in ssh systemd-resolved; do
    if systemctl is-active --quiet $service; then
        echo "$service : RUNNING"
    else
        echo "$service : STOPPED"
    fi
done
echo ""

# Network
echo "-- NETWORK --"
ip -4 addr show | grep inet | grep -v 127.0.0.1
ping -c 2 8.8.8.8 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Internet: CONNECTED"
else
    echo "Internet: DISCONNECTED"
fi
echo "==================================="
