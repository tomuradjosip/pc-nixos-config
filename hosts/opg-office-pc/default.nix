{ ... }:

let
  secrets = import /etc/secrets/config/secrets.nix;
in
{
  imports = [
    /etc/secrets/config/hardware-configuration.nix
    ../../modules/storage.nix
    ../../modules/networking.nix
    ../../modules/users.nix
    ../../modules/packages.nix
    ../../modules/shell.nix
    ../../modules/persistence.nix
    ../../modules/localization.nix
    ../../modules/desktop.nix
    ../../modules/home.nix
  ];

  # Pass secrets to modules
  _module.args.secrets = secrets;

  # Host-specific packages (add packages only for this machine here)
  # environment.systemPackages = with pkgs; [
  #   firefox
  # ];

  # Very dangerous to change, read docs before touching this variable
  system.stateVersion = "25.11";
}
