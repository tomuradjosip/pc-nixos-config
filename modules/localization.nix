{
  config,
  pkgs,
  lib,
  secrets,
  ...
}:

{
  # Time zone from secrets
  time.timeZone = secrets.timezone;

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "hr_HR.UTF-8";
    LC_NUMERIC = "hr_HR.UTF-8";
    LC_MONETARY = "hr_HR.UTF-8";
  };

  # Keyboard layout (GUI - X11/Wayland)
  services.xserver.xkb = {
    layout = "hr";
    variant = "";
  };

  # Keyboard layout (Console/TTY - non-GUI mode)
  console.useXkbConfig = true; # Use the same layout as X11
}
