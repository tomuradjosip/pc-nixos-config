{
  config,
  pkgs,
  lib,
  secrets,
  ...
}:

{
  # Systemd-boot EFI bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 5;

  # Btrfs support
  boot.initrd.availableKernelModules = [ "btrfs" ];
  boot.initrd.kernelModules = [ "btrfs" ];
  boot.supportedFilesystems = [ "btrfs" ];

  # Enable systemd in initrd for proper service ordering
  boot.initrd.systemd.enable = true;

  # Impermanence setup - rollback btrfs root subvolume on boot
  # Based on: https://notashelf.dev/posts/impermanence
  boot.initrd.systemd.services.rollback = {
    description = "Rollback BTRFS root subvolume to a pristine state";
    wantedBy = [ "initrd.target" ];
    after = [ "dev-disk-by\\x2did-${secrets.diskIds.osDisk}\\x2dpart2.device" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /mnt

      # Mount the BTRFS root to /mnt so we can manipulate subvolumes
      mount -o subvol=/ /dev/disk/by-id/${secrets.diskIds.osDisk}-part2 /mnt

      # Delete nested subvolumes first (NixOS creates /var/lib/portables, /var/lib/machines)
      btrfs subvolume list -o /mnt/@root |
        cut -f9 -d' ' |
        while read subvolume; do
          echo "Deleting /$subvolume subvolume..."
          btrfs subvolume delete "/mnt/$subvolume"
        done &&
        echo "Deleting @root subvolume..." &&
        btrfs subvolume delete /mnt/@root

      echo "Restoring blank @root subvolume..."
      btrfs subvolume snapshot /mnt/@root-blank /mnt/@root

      umount /mnt
    '';
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-id/${secrets.diskIds.osDisk}-part2";
      fsType = "btrfs";
      options = [
        "subvol=@root"
        "compress=zstd"
        "noatime"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-id/${secrets.diskIds.osDisk}-part2";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "compress=zstd"
        "noatime"
      ];
      neededForBoot = true;
    };

    "/persist" = {
      device = "/dev/disk/by-id/${secrets.diskIds.osDisk}-part2";
      fsType = "btrfs";
      options = [
        "subvol=@persist"
        "compress=zstd"
        "noatime"
      ];
      neededForBoot = true;
    };

    "/boot" = {
      device = "/dev/disk/by-id/${secrets.diskIds.osDisk}-part1";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };

  # Zram swap configuration (no swap partition needed)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryMax = 4294967296; # 4GB in bytes
  };

  # Btrfs maintenance services
  systemd.services = {
    # Btrfs scrub service
    "btrfs-scrub" = {
      description = "Btrfs scrub operation";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.btrfs-progs}/bin/btrfs scrub start -B /";
      };
    };

    # Btrfs balance service (for SSD optimization)
    "btrfs-balance" = {
      description = "Btrfs balance operation";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.btrfs-progs}/bin/btrfs balance start -dusage=50 -musage=50 /";
      };
    };

    # System generation cleanup service
    system-profile-cleanup = {
      description = "Intelligent system profile cleaner";
      startAt = "daily";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${
          pkgs.callPackage ../packages/system-generation-cleanup.nix { }
        }/bin/system-generation-cleanup";
      };
    };
  };

  # Systemd timers for maintenance
  systemd.timers = {
    system-profile-cleanup.timerConfig.Persistent = true;

    "btrfs-scrub" = {
      description = "Run btrfs scrub monthly";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "monthly";
        Persistent = true;
        RandomizedDelaySec = "6h";
      };
    };

    "btrfs-balance" = {
      description = "Run btrfs balance weekly";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "2h";
      };
    };
  };

  # Btrfs-specific packages
  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize # Show compression ratio
  ];

  # Enable fstrim for SSD optimization
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
}
