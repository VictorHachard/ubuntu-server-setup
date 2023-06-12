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

## Add Nginx and remove old TLS
sudo apt-get install nginx -y
sudo sed -i "s/ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;/ssl_protocols TLSv1.2 TLSv1.3;/g" /etc/nginx/nginx.conf
sudo systemctl enable nginx.service --now

cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    listen [::]:80;

    server_name _;

    location / {
        default_type text/html;
        return 200 "<!DOCTYPE html><h2>$(hostname)</h2>\n";
    }
}
EOF

sudo nginx -s reload

# Auto upgrade system
sudo apt install unattended-upgrades -y

sudo sed -i 's#//\s*"${distro_id}:${distro_codename}-updates";#        "${distro_id}:${distro_codename}-updates";#g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's#//Unattended-Upgrade::Automatic-Reboot "false";#Unattended-Upgrade::Automatic-Reboot "true";#g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's#//Unattended-Upgrade::Automatic-Reboot-Time "02:00";#Unattended-Upgrade::Automatic-Reboot-Time "02:00";#g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's#//Unattended-Upgrade::Remove-Unused-Dependencies "false";#Unattended-Upgrade::Remove-Unused-Dependencies "true";#g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's#//Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";#Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";#g' /etc/apt/apt.conf.d/50unattended-upgrades
sudo sed -i 's#//Unattended-Upgrade::Remove-New-Unused-Dependencies "true";#Unattended-Upgrade::Remove-New-Unused-Dependencies "true";#g' /etc/apt/apt.conf.d/50unattended-upgrades

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

## Install ufw
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2233
sudo ufw allow http
sudo ufw allow https

sudo ufw --force enable

## Run tests
echo -e "\n==== Run tests ===="

error=false

if ! sudo ufw status | grep "Status: active"; then
    echo "UFW firewall is not active!"
    error=true
fi

if ! timedatectl | grep "Time zone: Europe/Brussels"; then
    echo "Timezone is not set correctly!"
    error=true
fi

if ! systemctl status nginx | grep "active (running)"; then
    echo "Nginx is not running!"
    error=true
fi

if [ ! grep -q "^TLSv1" /etc/nginx/nginx.conf ]; then
    echo "TLSv1 is not removed."
    error=true
fi

if ! grep -q "^TLSv1.1" /etc/nginx/nginx.conf; then
    echo "TLSv1.1 is not removed."
    error=true
fi

if ! curl http://localhost | grep "<h2>"; then
    echo "Nginx server is not responding!"
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

if ! grep -q "APT::Periodic::Unattended-Upgrade" /etc/apt/apt.conf.d/20auto-upgrades; then
    echo "Auto-upgrades are not enabled."
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