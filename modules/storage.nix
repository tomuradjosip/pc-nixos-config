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

  # Impermanence setup - rollback btrfs root subvolume on boot
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    # Wait for disk to be available
    DISK="/dev/disk/by-id/${secrets.diskIds.osDisk}"
    while [ ! -e "$DISK" ]; do
      echo "Waiting for disk $DISK..."
      sleep 1
    done

    # Mount the btrfs root temporarily
    mkdir -p /mnt-btrfs
    mount -t btrfs -o subvol=/ "$DISK-part2" /mnt-btrfs

    # Delete old root subvolume if exists and create fresh one
    if [ -d /mnt-btrfs/@root ]; then
      echo "Deleting old @root subvolume..."
      btrfs subvolume delete /mnt-btrfs/@root
    fi

    echo "Creating fresh @root subvolume..."
    btrfs subvolume create /mnt-btrfs/@root

    umount /mnt-btrfs
    rmdir /mnt-btrfs
  '';

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
