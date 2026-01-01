#!/bin/bash
# Student: Ben Marsh  ID: F5037922
# I confirm I have not used generative AI for this submission.
# user_greeting.sh - prompts for user name, prints greeting, saves greeting.txt

read -p "Enter your name: " username

greeting="Hello, $username!"

echo "$greeting"
echo "$greeting" > greeting.txt

echo "Greeting saved to greeting.txt"

