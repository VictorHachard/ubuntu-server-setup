# Ubuntu Server Setup

## OCI Instance Configuration Script

This script automates the configuration of an OCI instance with common settings for security and convenience, including:

- Updating and upgrading the system
- Installing and configuring ufw (allow SSH (2233), HTTP, HTTPS)
- Setting the timezone (Brussel)
- Installing and configuring Nginx (default name of the host)
- Increasing SSH timeout and update the port to 2233
- Configuring unattended upgrades (activate distro update)
- Updating the welcome message (production, certification, test)
- Create missing .ssh folder and authorized_keys file for system user (between 1000 and 1100, excluding nobody)

### Usage

1. Download the script:

   - Latest release:
      ```
      wget https://github.com/VictorHachard/ubuntu-server-setup/releases/latest/download/oci-setup.sh
      ```
   - Latest version:
      ```
      wget https://raw.githubusercontent.com/VictorHachard/ubuntu-server-setup/main/oci-setup.sh
      ```

2. Make the script executable:

   ```
   chmod +x oci-instance-configuration.sh
   ```

3. Run the script with elevated privileges:

   ```
   sudo ./oci-instance-configuration.sh
   ```

   ```
   sudo ./oci-instance-configuration.sh -y -p <p/c/t>
   ```

During the script execution, you will be prompted for confirmation before certain steps, and you will have the option to choose between a production, a certification or a test custom welcome message.

One-line solution for the latest release:

```sh
sudo su -c "bash <(wget -qO- https://github.com/VictorHachard/ubuntu-server-setup/releases/latest/download/oci-setup.sh) -y -w p" root
```

One-line solution for the latest version:

```sh
sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/VictorHachard/ubuntu-server-setup/main/oci-setup.sh) -y -w p" root
```

## Disclaimer

Use this script at your own risk. While it has been tested on Ubuntu and Oracle Linux, it may not work on other distributions or configurations. It is highly recommended to review and understand the script code before running it, and to take backups or snapshots of your instance before applying any changes.
