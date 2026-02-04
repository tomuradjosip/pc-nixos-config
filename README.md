# pc-nixos-config

NixOS desktop configuration with tmpfs root and btrfs persistent storage.

## Features

- **Tmpfs root** - ephemeral RAM-based root (2GB, cleared on reboot)
- **Btrfs** subvolumes for `/nix` and `/persist`
- **Impermanence** - only explicitly persisted data survives reboot
- **Zram swap** - no swap partition needed
- **SSD trim** - weekly fstrim for SSD optimization

## Disk Layout

```
/dev/disk/by-id/<your-disk>
├── part1: 512MB  - EFI System Partition
└── part2: rest   - Btrfs
    ├── @nix        - Nix store
    └── @persist    - Persistent data

Runtime:
/              - tmpfs (RAM)
├── /nix       - Btrfs @nix
├── /persist   - Btrfs @persist
└── /boot      - EFI partition
```

## Installation

See [docs/installation/step-by-step.md](docs/installation/step-by-step.md) for complete instructions.

## Quick Start

```bash
# Build the system
sudo nixos-rebuild switch --flake .#opg-nixos

# Or during installation
sudo nixos-install --flake /path/to/opg-nixos#opg-nixos
```

## Configuration

1. Copy `secrets.nix.template` to `/etc/secrets/config/secrets.nix`
2. Update disk ID, username, SSH keys, etc.
3. Place `hardware-configuration.nix` in `/etc/secrets/config/`

## Maintenance

```bash
# Check tmpfs root usage
df -h /

# Check btrfs filesystems
sudo btrfs filesystem show
sudo btrfs filesystem df /nix

# Check compression ratio
sudo compsize /nix
sudo compsize /persist
```
