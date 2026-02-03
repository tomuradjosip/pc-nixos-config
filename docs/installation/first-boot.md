# First Boot Setup

Complete your system setup after the initial installation and first boot.

## Potential Issue with SSH Access

If you get `connection refused` when trying to connect to your machine, run nixos-rebuild with `rb` and reboot, then try to connect again.

## Initial System Verification

After your first boot, verify that all systems are working correctly:

### Check System Status
```bash
# Check Btrfs filesystem status
sudo btrfs filesystem show
sudo btrfs subvolume list /

# Verify system generation
nixos-rebuild list-generations

# Check system logs for any errors
journalctl --since "1 hour ago" --priority=err
```

### Verify Impermanence
```bash
# Create a test file in root (should disappear after reboot)
sudo touch /test-impermanence

# Check mounts
mount | grep btrfs

# After reboot, verify the file is gone:
ls /test-impermanence  # Should not exist
```

## System Configuration Verification

### Test System Rebuild
```bash
# Test rebuild without changing system
sudo nixos-rebuild test --flake ~/pc-nixos-config#$(hostname)
# Or use the alias:
rbt

# If test successful, switch to new configuration
sudo nixos-rebuild switch --flake ~/pc-nixos-config#$(hostname)
# Or use the alias:
rb
```

## Git and SSH Setup

Your system is already configured with Git and SSH settings from your `secrets.nix` file, but you need to generate and set up the actual SSH keys for GitHub access.

### Generate SSH Keys for GitHub

The SSH key filename should match what you configured in `secrets.nix` (`sshPrivateKeyFilename`):

```bash
# Generate SSH key pair (using the filename from your secrets.nix)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "your-email@example.com"

# When prompted, optionally set a passphrase for extra security

# Display your public key to copy to GitHub
cat ~/.ssh/id_ed25519.pub
```

### Add SSH Key to GitHub

1. Copy the output from the `cat ~/.ssh/id_ed25519.pub` command
2. Go to GitHub → Settings → SSH and GPG keys → New SSH key
3. Paste your public key and give it a descriptive title
4. Click "Add SSH key"

### Configure Your Repository

```bash
# Navigate to your configuration directory
cd ~/pc-nixos-config

# Change remote URL to use SSH instead of HTTPS
git remote set-url origin git@github.com:yourusername/pc-nixos-config.git

# Load your SSH key (or use the 'creds' alias for future sessions)
ssh-add ~/.ssh/id_ed25519

# Test your SSH connection to GitHub
ssh -T git@github.com

# You should see: "Hi username! You've successfully authenticated..."
```

**Note**: Your Git user configuration is already set system-wide from `secrets.nix`. The SSH agent is configured to start automatically and load your key. You can use the `creds` shell alias anytime to reload your SSH key.

## Install Additional Software

### Add System Packages
Edit `modules/packages.nix` and add desired packages:

```nix
environment.systemPackages = with pkgs; [
  # Add your packages here
  firefox
  vscode
];
```

Then rebuild using the `rb` command.

### Enable Additional Services
Edit appropriate module files to enable services:

```nix
# In modules/networking.nix for network services
# In configuration.nix for system services
services.docker.enable = true;  # Example
```

Then rebuild using the `rb` command.
