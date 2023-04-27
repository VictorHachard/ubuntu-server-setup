# Ubuntu Server Setup

## OCI Instance Configuration Script

This script automates the configuration of an OCI instance with common settings for security and convenience, including:

- Updating and upgrading the system
- Installing ufw
- Setting the timezone (Brussel)
- Installing and configuring Nginx
- Increasing SSH timeout
- Configuring unattended upgrades (activate distro update)
- Updating the welcome message

### Usage

1. Download the script:

   ```
   wget https://github.com/VictorHachard/ubuntu-server-setup/releases/latest/download/oci-setup.sh
   ```

2. Make the script executable:

   ```
   chmod +x oci-instance-configuration.sh
   ```

3. Run the script with elevated privileges:

   ```
   sudo ./oci-instance-configuration.sh
   ```

During the script execution, you will be prompted for confirmation before certain steps, and you will have the option to choose between a production or a test custom welcome message.

One line solution:

```sh
sudo su -c "bash <(wget -qO- https://github.com/VictorHachard/ubuntu-server-setup/releases/latest/download/oci-setup.sh) -y -w p" root
```

## Disclaimer

Use this script at your own risk. While it has been tested on Ubuntu and Oracle Linux, it may not work on other distributions or configurations. It is highly recommended to review and understand the script code before running it, and to take backups or snapshots of your instance before applying any changes.
