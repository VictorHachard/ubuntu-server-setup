# Ubuntu Server Setup

## General Usage

1. Download the script:

   - Latest release:
      ```sh
      wget https://github.com/VictorHachard/ubuntu-server-setup/releases/latest/download/<script>.sh
      ```
   - Latest version:
      ```sh
      wget https://raw.githubusercontent.com/VictorHachard/ubuntu-server-setup/main/<script>.sh
      ```

2. Make the script executable:
   ```sh
   chmod +x <script>.sh
   ```

3. Run the script with elevated privileges:
   ```sh
   sudo ./<script>.sh
   ```

During the script execution, you will be prompted for confirmation before proceeding. Additionally, you will have the option to choose from different options or decide whether to install additional features.

One-line solution for the latest release:

```sh
sudo su -c "bash <(wget -qO- https://github.com/VictorHachard/ubuntu-server-setup/releases/latest/download/<script>.sh) -y -w p" root
```

One-line solution for the latest version:

```sh
sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/VictorHachard/ubuntu-server-setup/main/<script>.sh) -y -w p" root
```

## OCI Instance Configuration Script

This script automates the configuration of an OCI instance with common settings for security and convenience, including:

- Updating and upgrading the system
- Installing and configuring ufw (allow SSH, HTTP, HTTPS)
- Setting the timezone (Brussel)
- Installing and configuring Nginx (default name of the host and remove old TLS version)
- Increasing SSH timeout and update (default port to 2233)
- Installing and activate unattended upgrades (activate: Distro-Update, Remove-Unused-Kernel-Packages, Remove-New-Unused-Dependencies, Remove-Unused-Dependencies, Automatic-Reboot, Automatic-Reboot-Time)
- Updating the welcome message (production, certification, test)
- Create missing .ssh folder and authorized_keys file for system user (between 1000 and 1100, excluding nobody)

### Usage:

```sh
./oci-setup.sh [OPTIONS]
```

Options:

| Command | Description |
| --- | --- |
| -y | Automatically run the script without confirmation. |
| -w ENVIRONMENT | Specify the environment (p - Production, c - Certification, t - Test). |
| -s SSH_PORT | Specify the SSH port. |
| -f | Install Fail2Ban. |
| -q | Run the script quietly without prompting for choices. |

Example Usage:


```sh
./oci-setup.sh -y -w p -f -q
```

In this example, the script will automatically run without confirmation, set the environment to Production, install Fail2Ban, and run quietly without prompting for choices.

### One-line Commands

One-line command for the latest release:

```sh
sudo su -c "bash <(wget -qO- https://github.com/VictorHachard/ubuntu-server-setup/releases/latest/download/oci-setup.sh) -y -w p -q" root
```

One-line command for the latest version:

```sh
sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/VictorHachard/ubuntu-server-setup/main/oci-setup.sh) -y -w p -q" root
```

## Simple Configuration Script

This script automates the configuration of an instance with common settings for security and convenience, including:

- Updating and upgrading the system
- Setting the timezone (Brussel)
- Installing Nginx (remove old TLS version)
- Increasing SSH timeout and update (default port to 2233)
- Installing and activate unattended upgrades
- Updating the welcome message (production, certification, test)
- Create missing .ssh folder and authorized_keys file for system user (between 1000 and 1100, excluding nobody)

### Usage:

```sh
./simple-setup.sh [OPTIONS]
```

Options:

| Command | Description |
| --- | --- |
| -y | Automatically run the script without confirmation. |
| -w ENVIRONMENT| Specify the environment (p - Production, c - Certification, t - Test). |
| -s SSH_PORT | Specify the SSH port. |
| -f | Install Fail2Ban. |
| -q | Run the script quietly without prompting for choices. |

Example Usage:


```sh
./simple-setup.sh -y -w p -f -q
```

In this example, the script will automatically run without confirmation, set the environment to Production, install Fail2Ban, and run quietly without prompting for choices.

### One-line Commands

One-line command for the latest release:

```sh
sudo su -c "bash <(wget -qO- https://github.com/VictorHachard/ubuntu-server-setup/releases/latest/download/simple-setup.sh) -y -w p -q" root
```

One-line command for the latest version:

```sh
sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/VictorHachard/ubuntu-server-setup/main/simple-setup.sh) -y -w p -q" root
```

## Disclaimer

Use this script at your own risk. While it has been tested on Ubuntu 22.04 and Ubuntu 22.04 on an Oracle Instance (OCI), it may not work on other distributions or configurations. It is highly recommended to review and understand the script code before running it, and to take backups or snapshots of your instance before applying any changes.
