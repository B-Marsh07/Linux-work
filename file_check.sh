#!/bin/bash
# Student: Ben Marsh  ID: F5037922
# I confirm I have not used generative AI for this submission.
# file_check.sh - checks file existence and writability

if [ -z "$1" ]; then
    echo "Usage: bash file_check.sh <filename>"
    exit 1
fi

filename="$1"

if [ -e "$filename" ]; then
    echo "File exists."
    if [ -w "$filename" ]; then
        echo "File is writable."
    else
        echo "File is NOT writable."
    fi
else
    echo "File does not exist."
fi

