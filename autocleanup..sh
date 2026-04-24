#!/bin/bash

TARGET_DIR="/var/tmp/application"
AGENT_DIR="/var/log/agent/parkee-agent"

get_storage_usage() {
    df / | awk 'NR==2 {print $5}' | sed 's/%//'
}

USAGE=$(get_storage_usage)

# Validasi angka
if ! [[ "$USAGE" =~ ^[0-9]+$ ]]; then
    exit 1
fi

if [ $USAGE -ge 85 ]; 1then
    [ -d "$TARGET_DIR" ] && sudo find "$TARGET_DIR" -type f \( -name "*.log" -o -name "*.log.gz" \) -delete
    
    USAGE=$(get_storage_usage)
    
    if [ $USAGE -gt 80 ] && [ -d "$AGENT_DIR" ]; then
        sudo find "$AGENT_DIR" -type f -name "*.log" -mtime +14 -exec gzip {} \;
    fi
fi
