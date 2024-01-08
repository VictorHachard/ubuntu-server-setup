#!/bin/bash

if ((${EUID:-0} || "$(id -u)")); then
    echo Please run this script as root or using sudo. Script execution aborted.
    exit 1
fi

# Set default values for options and variables
force_confirm_needed=false
confirm_needed=true
user_name=""

# Parse command-line options
while getopts "yw:u:" opt; do
  case "${opt}" in
    y)
      force_confirm_needed=true
      ;;
    u)
      user_name="${OPTARG}"
      ;;
  esac
done

# Check if confirmation is needed
if $force_confirm_needed; then
  confirm_needed=false
fi

# Prompt for confirmation if needed
if $confirm_needed; then
  read -p "This script will update and configure your instance. Do you wish to proceed? (y/n) " confirm
  if [ "$confirm" != "y" ]; then
    echo "Script execution aborted."
    exit 1
  fi
fi

