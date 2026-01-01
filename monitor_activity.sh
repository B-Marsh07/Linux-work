#!/bin/bash
# Student: Ben Marsh  ID: F5037922
# I confirm I have not used generative AI for this submission.
# monitor_activity.sh - monitors connections every 5s and warns if > 100

THRESHOLD=100

while true; do
    if command -v netstat >/dev/null 2>&1; then
        connections=$(netstat -tun 2>/dev/null | awk 'NR>2' | wc -l)
    else
        connections=$(ss -tun 2>/dev/null | awk 'NR>1' | wc -l)
    fi

    echo "$(date +'%F %T') - Current connections: $connections"

    if [ "$connections" -gt "$THRESHOLD" ]; then
        echo "High number of connections detected!"
    fi

    sleep 5
done

