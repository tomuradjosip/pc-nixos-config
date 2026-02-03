# opg-nixos

NixOS desktop configuration with single-disk btrfs and impermanence.

## Features

- **Single-disk btrfs** with subvolumes
- **Impermanence** - root filesystem resets on every boot
- **Zram swap** - no swap partition needed
- **Automated maintenance** - btrfs scrub, balance, trim

## Disk Layout

```
/dev/disk/by-id/<your-disk>
├── part1: 512MB  - EFI System Partition
└── part2: rest   - Btrfs
    ├── @root       - Root (wiped on boot)
    ├── @nix        - Nix store
    └── @persist    - Persistent data
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
# Check filesystem
sudo btrfs filesystem show
sudo btrfs filesystem df /

# Check compression
sudo compsize /nix

# Manual scrub
sudo btrfs scrub start /
```
