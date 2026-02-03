# pc-nixos-config Installation Guide

Single-disk Btrfs setup with impermanence for a desktop PC.

## Overview

This setup uses:
- **Single disk** (SSD or NVMe recommended)
- **Btrfs** with subvolumes for `/nix` and `/persist`
- **Impermanence** - root filesystem is reset on every boot
- **Zram** for swap (no swap partition needed)

## Disk Layout

```
Disk: /dev/disk/by-id/<your-disk-id>
├── part1: 512MB  - EFI System Partition (FAT32)
└── part2: rest   - Btrfs partition
    ├── @root       - Root subvolume (wiped on boot)
    ├── @nix        - Nix store (persistent)
    └── @persist    - Persistent data (persistent)
```

## Installation Steps

### Step 1: Boot NixOS Installation ISO

1. **Flash the NixOS ISO to a USB drive**
2. **Boot from the USB drive**
3. **Connect to the internet**:

#### Ethernet Connection
```bash
# Ethernet should connect automatically
# Verify connection:
ping -c 3 google.com
```

#### WiFi Connection
```bash
# Start WiFi services
sudo systemctl start wpa_supplicant

# Configure WiFi
sudo wpa_cli
> add_network
> set_network 0 ssid "Your-WiFi-Name"
> set_network 0 psk "Your-WiFi-Password"
> enable_network 0
> quit

# Verify connection
ping -c 3 google.com
```

### Step 2: Enable SSH Access (Optional but Recommended)

For easier installation (copy/paste commands from another machine):

```bash
# Set password for the nixos user
sudo passwd nixos

# Start SSH service
sudo systemctl start sshd

# Find your IP address
ip addr show | grep "inet " | grep -v 127.0.0.1

# Now you can SSH from another machine:
# ssh nixos@<ip-address>
```

### Step 3: Identify Your Disk

Find your disk using stable identifiers that won't change:

```bash
# List all disks with stable identifiers
ls -la /dev/disk/by-id/

# Note your disk ID (without -partN suffix)
# Example: nvme-Samsung_SSD_970_EVO_Plus_1TB_XXXXXXXX
# Example: ata-Samsung_SSD_860_EVO_500GB_XXXXXXXX
```

**Important**: Write down the exact ID - you'll need it throughout the installation.

### Step 4: Set Environment Variables

```bash
USERNAME="your-username"    # Your desired username
HOSTNAME="your-hostname"    # Your system hostname (e.g., opg-office-pc)
DISK="/dev/disk/by-id/your-disk-id-here"
```

### Step 5: Partition the Disk

```bash
# Create GPT partition table
sudo parted $DISK -- mklabel gpt

# Create EFI partition (512MB)
sudo parted $DISK -- mkpart ESP fat32 1MiB 513MiB
sudo parted $DISK -- set 1 esp on

# Create Btrfs partition (rest of disk)
sudo parted $DISK -- mkpart primary 513MiB 100%

# Verify partitions
sudo parted $DISK -- print
```

### Step 6: Format Partitions

```bash
# Format EFI partition
sudo mkfs.fat -F32 -n ESP ${DISK}-part1

# Format Btrfs partition
sudo mkfs.btrfs -L nixos ${DISK}-part2
```

### Step 7: Create Btrfs Subvolumes

```bash
# Mount Btrfs partition
sudo mount ${DISK}-part2 /mnt

# Create subvolumes
sudo btrfs subvolume create /mnt/@root
sudo btrfs subvolume create /mnt/@nix
sudo btrfs subvolume create /mnt/@persist

# Unmount
sudo umount /mnt
```

### Step 8: Mount Filesystems for Installation

```bash
# Mount root subvolume
sudo mount -o subvol=@root,compress=zstd,noatime ${DISK}-part2 /mnt

# Create mount points
sudo mkdir -p /mnt/{nix,persist,boot}

# Mount other subvolumes
sudo mount -o subvol=@nix,compress=zstd,noatime ${DISK}-part2 /mnt/nix
sudo mount -o subvol=@persist,compress=zstd,noatime ${DISK}-part2 /mnt/persist

# Do not mount ESP (/boot) here - we don't want it in hardware-configuration.nix
```

### Step 9: Clone Configuration and Prepare Secrets

#### Clone the Configuration
```bash
# Create the user's home directory
sudo mkdir -p /mnt/persist/home/$USERNAME

# Clone directly to the final location
sudo git clone https://github.com/yourusername/pc-nixos-config.git /mnt/persist/home/$USERNAME/pc-nixos-config

# Or copy from USB
# sudo cp -r /path/to/pc-nixos-config /mnt/persist/home/$USERNAME/

# Set proper ownership
sudo chown -R 1000:1000 /mnt/persist/home/$USERNAME
```

#### Create Secrets Configuration
```bash
# Create the secrets directory
sudo mkdir -p /mnt/persist/etc/secrets/config

# Copy template to the proper location
sudo cp /mnt/persist/home/$USERNAME/pc-nixos-config/secrets.nix.template \
        /mnt/persist/etc/secrets/config/secrets.nix

# Set secure permissions
sudo chmod 600 /mnt/persist/etc/secrets/config/secrets.nix
sudo chown root:root /mnt/persist/etc/secrets/config/secrets.nix
```

#### Edit Secrets File
```bash
sudo nano /mnt/persist/etc/secrets/config/secrets.nix
```

**Required changes**:
- Replace `your-username` with your chosen username
- Replace `your-hostname` with your chosen hostname
- Set your timezone (find yours: `timedatectl list-timezones | grep your-region`)
- Add your SSH public keys (for remote access to this machine)
- Set your disk ID in `diskIds.osDisk`

#### Create Password Hash Files
```bash
# Create password directory
sudo mkdir -p /mnt/persist/etc/secrets/passwords

# Generate password hash for root
echo "Enter root password:"
sudo mkpasswd -m sha-512 | sudo tee /mnt/persist/etc/secrets/passwords/root

# Generate password hash for your user
echo "Enter $USERNAME password:"
sudo mkpasswd -m sha-512 | sudo tee /mnt/persist/etc/secrets/passwords/$USERNAME

# Secure the files
sudo chmod 600 /mnt/persist/etc/secrets/passwords/*
```

### Step 10: Generate Hardware Configuration

```bash
# Generate hardware configuration
sudo nixos-generate-config --root /mnt

# Copy the generated hardware configuration to the secrets directory
sudo cp /mnt/etc/nixos/hardware-configuration.nix \
        /mnt/persist/etc/secrets/config/hardware-configuration.nix

# Set secure permissions
sudo chmod 600 /mnt/persist/etc/secrets/config/hardware-configuration.nix
sudo chown root:root /mnt/persist/etc/secrets/config/hardware-configuration.nix
```

#### Edit Hardware Configuration

**Important**: The `storage.nix` module defines all filesystems. You must remove conflicting definitions from hardware-configuration.nix:

```bash
sudo nano /mnt/persist/etc/secrets/config/hardware-configuration.nix
```

**Delete these sections** (storage.nix handles them):
- `fileSystems` - entire section
- `swapDevices` - entire section (zram is used instead)

**Keep these settings** (hardware-specific):
- `boot.initrd.availableKernelModules`
- `boot.initrd.kernelModules`
- `boot.kernelModules`
- `boot.extraModulePackages`
- `hardware.cpu.intel.updateMicrocode` (or amd)
- `nixpkgs.hostPlatform`

### Step 11: Install NixOS

```bash
# Create a temporary symlink in the host environment for flake evaluation
sudo ln -sf /mnt/persist/etc/secrets /etc/secrets

# Mount ESP
sudo mount ${DISK}-part1 /mnt/boot

# Install using your flake configuration
sudo nixos-install --no-root-passwd --impure --flake /mnt/persist/home/$USERNAME/pc-nixos-config#$HOSTNAME --root /mnt
```

**Note**: This step may take 15-30 minutes depending on your internet connection.

### Step 12: Reboot and Verify

#### Clean Unmount and Reboot
```bash
sudo umount /mnt/boot
sudo umount /mnt/nix
sudo umount /mnt/persist
sudo umount /mnt
sudo reboot
```

## Next Steps

- **[First Boot Setup](first-boot.md)** - Complete post-installation configuration, Git/SSH setup
