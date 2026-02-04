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
    opensc             # pkcs11-tool for PKCS#11 diagnostics
    p11-kit            # PKCS#11 module management
  ];

  # Need this for vscode-server and other tools
  programs.nix-ld.enable = true;

  # Smart card daemon - required for FINA eToken/smart card support
  services.pcscd.enable = true;

  # SafeNet/Gemalto eToken configuration files (required for IDPrime PKCS#11)
  environment.etc = {
    "eToken.conf".source = "${safenet-auth}/etc/eToken.conf";
    "eToken.common.conf".source = "${safenet-auth}/etc/eToken.common.conf";
    "eToken.policy.conf".source = "${safenet-auth}/etc/eToken.policy.conf";
  };

  # Polkit rules to allow users in wheel group to access smart card daemon
  # This is required for non-root users to use FINA eToken
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.debian.pcsc-lite.access_pcsc" ||
          action.id == "org.debian.pcsc-lite.access_card") {
        if (subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      }
    });
  '';

}
