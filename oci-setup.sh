#!/bin/bash

if ((${EUID:-0} || "$(id -u)")); then
    echo Please run this script as root or using sudo. Script execution aborted.
    exit 1
fi

# Set default values for options and variables
force_confirm_needed=false
welcome_choice=""
confirm_needed=true
install_fail2ban=""
add_missing_shh_entry=""
quiet=false
ssh_port=""

# Parse command-line options
while getopts "yw:fs:mq" opt; do
  case "${opt}" in
    y)
      force_confirm_needed=true
      ;;
    w)
      if [[ "${OPTARG}" == "p" || "${OPTARG}" == "c" || "${OPTARG}" == "t" ]]; then
        welcome_choice="${OPTARG}"
      else
        echo "Invalid option argument for -w: ${OPTARG}" >&2
        exit 1
      fi
      ;;
    f)
      install_fail2ban="y"
      ;;
    s)
     if [[ "${OPTARG}"  =~ ^[0-9]+$ ]]; then
        ssh_port="${OPTARG}"
      else
        echo "Invalid option argument for -s: ${OPTARG}" >&2
        exit 1
      fi
      ;;
    m)
      add_missing_shh_entry="y"
      ;;
    q)
      quiet=true
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

sudo sed -i "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g" /etc/needrestart/needrestart.conf
sudo sed -i "s/\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/g" /etc/needrestart/needrestart.conf

## Update and upgrade
sudo apt update && sudo apt upgrade -q -y && sudo apt autoremove -y

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
if ! $quiet; then
    while [[ ! "$welcome_choice" =~ ^(p|c|d|)$ ]]; do
        read -p "Do you want to use the production or test custom welcome message? (p/c/t) " welcome_choice
        if [[ ! "$welcome_choice" =~ ^(p|c|d|)$ ]]; then
            echo "Invalid input. Please enter 'p', 'c', 't', or leave it blank."
        fi
    done
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

if ! $quiet; then
    while [[ ! "$add_missing_shh_entry" =~ ^(y|n)$ ]]; do
        read -p "Do you want to add missing ssh folders/files? (y/n): " add_missing_shh_entry
        if [[ ! "$add_missing_shh_entry" =~ ^(y|n)$ ]]; then
            echo "Invalid input. Please enter 'y' or 'n'."
        fi
    done
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

if ! $quiet; then
    while [[ ! "$ssh_port" =~ ^[0-9]+$ || -z "$ssh_port" ]]; do
        read -p "Enter the SSH port number: " ssh_port
        if [[ ! "$ssh_port" =~ ^[0-9]+$ ]]; then
            echo "Invalid input. Please enter a valid SSH port number."
        elif [[ -z "$ssh_port" ]]; then
            break
        fi
    done
fi
if [[ -z "$ssh_port" ]]; then
    echo "No port specified. Defaulting to port 2233."
    ssh_port="2233"
fi

## Install ufw
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow $ssh_port
sudo ufw allow http
sudo ufw allow https

sudo ufw --force enable

# Install and configure Fail2Ban
if ! $quiet; then
    while [[ ! "$install_fail2ban" =~ ^(y|n)$ ]]; do
        read -p "Do you want to install fail2ban? (y/n): " install_fail2ban
        if [[ ! "$install_fail2ban" =~ ^(y|n)$ ]]; then
            echo "Invalid input. Please enter 'y' or 'n'."
        fi
    done
fi

if [ "$install_fail2ban" == "y" ]; then
    sudo apt-get install fail2ban -y
    sudo systemctl enable fail2ban --now
fi

## Increase ssh timeout
sudo sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 600/g" /etc/ssh/sshd_config
sudo sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 6/g" /etc/ssh/sshd_config
sudo sed -i "s/#Port 22/Port $ssh_port/g" /etc/ssh/sshd_config

sudo systemctl reload sshd

sudo sed -i "s/\$nrconf{kernelhints} = -1;/#\$nrconf{kernelhints} = -1;/g" /etc/needrestart/needrestart.conf
sudo sed -i "s/\$nrconf{restart} = 'a';/\$nrconf{restart} = 'i';/g" /etc/needrestart/needrestart.conf

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

if grep -q "^TLSv1" /etc/nginx/nginx.conf; then
    echo "TLSv1 is not removed."
    error=true
fi

if grep -q "^TLSv1.1" /etc/nginx/nginx.conf; then
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
if [ "$timeout" != $ssh_port ]; then
    echo "SSH port is not set to $ssh_port."
    error=true
fi

if ! grep -q "APT::Periodic::Unattended-Upgrade" /etc/apt/apt.conf.d/20auto-upgrades; then
    echo "Auto-upgrades are not enabled."
    error=true
fi

if [ ! -f /etc/update-motd.d/99-custom-welcome ] && [[ "$welcome_choice" == [pcd] ]]; then
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
echo "Restarting server in 1 minutes" >> /var/log/restart_server.log
echo "Restarting server in 1 minutes"
sleep 60
sudo shutdown -r now