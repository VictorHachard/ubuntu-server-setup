#!/bin/bash

if ((${EUID:-0} || "$(id -u)")); then
    echo Please run this script as root or using sudo. Script execution aborted..
    exit 0
fi

read -p "This script will update and configure your instance. Do you wish to proceed? (y/n) " confirm
if [ "$confirm" != "y" ]; then
    echo "Script execution aborted."
    exit 0
fi

## Update and upgrade
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y

## Remove iptables and install ufw
sudo systemctl disable iptables && sudo apt-get remove iptables -y
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable

## Set timezone
sudo timedatectl set-timezone Europe/Brussels

## Add Nginx
sudo apt-get install nginx -y && sudo systemctl enable nginx.service --now

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

## Increase ssh timeout
sudo sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 600/g" /etc/ssh/sshd_config
sudo sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 6/g" /etc/ssh/sshd_config

sudo systemctl reload sshd

# Auto upgrade system
sudo apt install unattended-upgrades -y

sudo sed -i 's#//      "${distro_id}:${distro_codename}-updates";#       "${distro_id}:${distro_codename}-updates";#g' /etc/apt/apt.conf.d/50unattended-upgrades

sudo dpkg-reconfigure -f noninteractive unattended-upgrades

# Update welcome message
## Remove help
sudo sed -i 's/^/#/' /etc/update-motd.d/10-help-text

## Add custom message
read -p "Do you want to use the production or test custom welcome message? (p/t) " welcome_choice
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
fi


## Run tests
if ! sudo ufw status | grep "Status: active"; then
    echo "UFW firewall is not active!"
    exit 1
fi

if ! timedatectl | grep "Time zone: Europe/Brussels"; then
    echo "Timezone is not set correctly!"
    exit 1
fi

if ! systemctl status nginx | grep "active (running)"; then
    echo "Nginx is not running!"
    exit 1
fi

if ! curl http://localhost | grep "<h2>"; then
    echo "Nginx server is not responding!"
    exit 1
fi

timeout=$(sudo grep "^ClientAliveInterval" /etc/ssh/sshd_config | awk '{print $2}')
if [ "$timeout" != "600" ]; then
    echo "SSH timeout is not set to 600 seconds."
    exit 1
fi

timeout=$(sudo grep "^ClientAliveCountMax" /etc/ssh/sshd_config | awk '{print $2}')
if [ "$timeout" != "6" ]; then
    echo "SSH timeout count is not set to 6 seconds."
    exit 1
fi

if ! grep -q "APT::Periodic::Unattended-Upgrade" /etc/apt/apt.conf.d/20auto-upgrades; then
    echo "Auto-upgrades are not enabled."
    exit 1
fi

if [ ! -f /etc/update-motd.d/99-custom-welcome ]; then
    echo "Custom welcome message is not added."
    exit 1
fi


## Clean up
sudo apt autoremove -y
sudo apt clean
sudo rm -rf /var/lib/apt/lists/*

echo "Server configuration completed." > /var/log/cloud-init.log
