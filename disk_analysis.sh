#!/bin/bash
# Student: Ben Marsh  ID: F5037922
# I confirm I have not used generative AI for this submission.
# disk_analysis.sh - store df result, extract total & avail, compute percent used

df_output=$(df -k / | tail -n 1)

total_kb=$(echo "$df_output" | awk '{print $2}')
avail_kb=$(echo "$df_output" | awk '{print $4}')
used_kb=$(( total_kb - avail_kb ))

if [ "$total_kb" -gt 0 ]; then
    percent_used=$(( 100 * used_kb / total_kb ))
else
    percent_used=0
fi

echo "Total disk size: ${total_kb} KB"
echo "Available disk space: ${avail_kb} KB"
echo "Used disk space: ${used_kb} KB"
echo "Percentage of disk used: ${percent_used}%"

