{
  config,
  pkgs,
  lib,
  secrets,
  ...
}:

{
  # Enable X11 windowing system
  services.xserver.enable = true;

  # Display manager - SDDM is KDE's native display manager
  services.displayManager.sddm.enable = true;

  # Auto-login (needed for remote desktop access via Sunshine)
  services.displayManager.autoLogin = {
    enable = true;
    user = secrets.username;
  };

  # KDE Plasma
  services.desktopManager.plasma6.enable = true;

  # Sunshine - remote desktop streaming (use with Moonlight client)
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # Needed for Wayland capture
    openFirewall = true;
  };

  # Load uinput module for Sunshine input injection
  boot.kernelModules = [ "uinput" ];

  # Allow input group to access uinput device
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
  '';
}
