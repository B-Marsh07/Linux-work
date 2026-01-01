#!/bin/bash
# Student: Ben Marsh  ID: F5037922
# I confirm I have not used generative AI for this submission.
# log_analyser.sh - counts occurrences of "error" in a log file
# Usage: bash log_analyser.sh log.txt

# wget -O log.txt "[BLACKBOARD_LOG_URL]"

if [ -z "$1" ]; then
    echo "Usage: bash log_analyser.sh <logfile>"
    exit 1
fi

logfile="$1"

if [ ! -f "$logfile" ]; then
    echo "File not found: $logfile"
    exit 1
fi

count=$(grep -oi '\berror\b' "$logfile" | wc -l)

echo "Number of occurrences of 'error' in $logfile: $count"

