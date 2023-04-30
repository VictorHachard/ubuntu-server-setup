#!/bin/bash

if ((${EUID:-0} || "$(id -u)")); then
    echo Please run this script as root or using sudo. Script execution aborted.
    exit 1
fi

# Set default values for options and variables
do_update=false
welcome_choice=""
confirm_needed=true

# Parse command-line options
while getopts "yw:" opt; do
  case "${opt}" in
    y)
      do_update=true
      ;;
    w)
      if [[ "${OPTARG}" == "p" || "${OPTARG}" == "c" || "${OPTARG}" == "t" ]]; then
        welcome_choice="${OPTARG}"
      else
        echo "Invalid option argument for -w: ${OPTARG}" >&2
        exit 1
      fi
      ;;
  esac
done

# Check if confirmation is needed
if $do_update; then
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

## Update and upgrade
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

## Set timezone
sudo timedatectl set-timezone Europe/Brussels

## Add Nginx
sudo apt-get install nginx -y && sudo systemctl enable nginx.service --now

# Auto upgrade system
sudo apt install unattended-upgrades -y

sudo dpkg-reconfigure -f noninteractive unattended-upgrades

# Update welcome message
## Remove help
sudo sed -i 's/^.*printf/# &/' /etc/update-motd.d/10-help-text

## Add custom message
if [ -z "$welcome_choice" ]; then
  read -p "Do you want to use the production or test custom welcome message? (p/c/t) " welcome_choice
fi

if [ "$welcome_choice" == "p" ]; then
    cat << EOF > /etc/update-motd.d/99-custom-welcome
#!/bin/sh

echo "██████  ██████   ██████  ██████  ██    ██  ██████ ████████ ██  ██████  ███    ██ "
echo "██   ██ ██   ██ ██    ██ ██   ██ ██    ██ ██         ██    ██ ██    ██ ████   ██ "
echo "██████  ██████  ██    ██ ██   ██ ██    ██ ██         ██    ██ ██    ██ ██ ██  ██ "
echo "██      ██   ██ ██    ██ ██   ██ ██    ██ ██         ██    ██ ██    ██ ██  ██ ██ "
echo "██      ██   ██  ██████  ██████   ██████   ██████    ██    ██  ██████  ██   ████ "
echo ""
echo ""
EOF
    sudo chmod +x /etc/update-motd.d/99-custom-welcome
elif [[ "$welcome_choice" == "c" ]]; then
    cat <<EOF > /etc/update-motd.d/99-custom-welcome
#!/bin/sh

echo " ██████ ███████ ██████  ████████ ██ ███████ ██  ██████  █████  ████████ ██  ██████  ███    ██ "
echo "██      ██      ██   ██    ██    ██ ██      ██ ██      ██   ██    ██    ██ ██    ██ ████   ██ "
echo "██      █████   ██████     ██    ██ █████   ██ ██      ███████    ██    ██ ██    ██ ██ ██  ██ "
echo "██      ██      ██   ██    ██    ██ ██      ██ ██      ██   ██    ██    ██ ██    ██ ██  ██ ██ "
echo " ██████ ███████ ██   ██    ██    ██ ██      ██  ██████ ██   ██    ██    ██  ██████  ██   ████ "
echo ""
echo ""
EOF
    sudo chmod +x /etc/update-motd.d/99-custom-welcome
elif [[ "$welcome_choice" == "t" ]]; then
    cat <<EOF > /etc/update-motd.d/99-custom-welcome
#!/bin/sh

echo "████████ ███████ ███████ ████████ "
echo "   ██    ██      ██         ██    "
echo "   ██    █████   ███████    ██    "
echo "   ██    ██           ██    ██    "
echo "   ██    ███████ ███████    ██    "
echo ""
echo ""
EOF
    sudo chmod +x /etc/update-motd.d/99-custom-welcome
fi

# Get all system usernames (getting uid between 1000 and 1100, excluding nobody)
usernames=$(getent passwd | awk -F: '{if ($3>=1000 && $3<=1100 && $1!="nobody") print $1}')

# Loop through each username and create the .ssh directory and authorized_keys file with correct permissions
for user in $usernames
do
    # Create .ssh directory if it doesn't exist
    if [ ! -d "/home/$user/.ssh" ]
    then
        mkdir /home/$user/.ssh
        chown $user:$user /home/$user/.ssh
        chmod 700 /home/$user/.ssh
        echo "Created .ssh directory for user $user"
    fi

    # Check if authorized_keys file exists or not
    if [ ! -f "/home/$user/.ssh/authorized_keys" ]; then
        # Create authorized_keys file
        sudo touch /home/$user/.ssh/authorized_keys
        sudo chmod 600 /home/$user/.ssh/authorized_keys
        sudo chown $user:$user /home/$user/.ssh/authorized_keys
        echo "Created authorized_keys file for user $user"
    fi
done

## Increase ssh timeout
sudo sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 600/g" /etc/ssh/sshd_config
sudo sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 6/g" /etc/ssh/sshd_config
sudo sed -i "s/#Port 22/Port 2233/g" /etc/ssh/sshd_config

sudo systemctl reload sshd

## Run tests
echo -e "\n==== Run tests ===="

error=false

if ! timedatectl | grep "Time zone: Europe/Brussels"; then
    echo "Timezone is not set correctly!"
    error=true
fi

if ! systemctl status nginx | grep "active (running)"; then
    echo "Nginx is not running!"
    error=true
fi

timeout=$(sudo grep "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}')
if [ "$timeout" != "600" ]; then
    echo "SSH timeout is not set to 600 seconds."
    error=true
fi

timeout=$(sudo grep "^ClientAliveCountMax" /etc/ssh/sshd_config | awk '{print $2}')
if [ "$timeout" != "6" ]; then
    echo "SSH timeout count is not set to 6 seconds."
    error=true
fi

timeout=$(sudo grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
if [ "$timeout" != "2233" ]; then
    echo "SSH port is not set to 2233."
    error=true
fi

if [ ! -f /etc/update-motd.d/99-custom-welcome ]; then
    echo "Custom welcome message is not added."
    error=true
fi

if $error; then
    exit 1
fi

## Clean up
sudo apt autoremove -y
sudo apt clean
sudo rm -rf /var/lib/apt/lists/*

logger "Server configuration completed"
echo "Server configuration completed"
echo "Restarting server in 2 minutes" >> /var/log/restart_server.log
echo "Restarting server in 2 minutes"
sleep 120
sudo shutdown -r now