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

  fileSystems = {
    "/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "mode=755"
        "size=2G"
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

  # System generation cleanup service
  systemd.services.system-profile-cleanup = {
    description = "Intelligent system profile cleaner";
    startAt = "daily";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${
        pkgs.callPackage ../packages/system-generation-cleanup.nix { }
      }/bin/system-generation-cleanup";
    };
  };

  systemd.timers.system-profile-cleanup.timerConfig.Persistent = true;

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
