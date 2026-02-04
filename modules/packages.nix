{
  config,
  pkgs,
  lib,
  secrets,
  ...
}:

let
  # FINA digital signature packages
  signergy-fina = pkgs.callPackage ../packages/signergy-fina.nix { };
  safenet-auth = pkgs.callPackage ../packages/safenet-authentication-client.nix { };
in
{
  # Allow unfree packages (e.g., Google Chrome, FINA packages)
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

    # FINA digital signature tools
    signergy-fina      # Digital document signing application
    safenet-auth       # Smart card/eToken authentication client

    # Smart card diagnostic tools
    nssTools           # modutil and certutil for PKCS#11 management
    pcsc-tools         # pcsc_scan and other PC/SC diagnostic tools
  ];

  # Need this for vscode-server and other tools
  programs.nix-ld.enable = true;

  # Smart card daemon - required for FINA eToken/smart card support
  services.pcscd.enable = true;

}
