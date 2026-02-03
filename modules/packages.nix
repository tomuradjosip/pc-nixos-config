{
  config,
  pkgs,
  lib,
  secrets,
  ...
}:

{
  # Allow unfree packages (e.g., Google Chrome)
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    # Core utilities
    vim
    wget
    git
    rsync
    htop
    jq
    fzf

    # Development
    nixfmt
    pre-commit

    # Shell
    oh-my-posh

    # Disk utilities
    parted
    smartmontools

    # Browsers
    brave
    google-chrome
    firefox

    # Custom packages
    (pkgs.callPackage ../packages/system-generation-cleanup.nix { })
  ];

  # Need this for vscode-server and other tools
  programs.nix-ld.enable = true;
}
