{
  config,
  pkgs,
  lib,
  secrets,
  inputs,
  ...
}:

{
  # Home Manager configuration for the main user
  home-manager.users.${secrets.username} = {
    home.stateVersion = "25.11";

    # KDE Plasma configuration via plasma-manager
    programs.plasma = {
      enable = true;

      # Workspace appearance
      workspace = {
        theme = "breeze-light";
        colorScheme = "BreezeLight";
        cursor.theme = "Adwaita"; # Clean, Windows-like cursor
        iconTheme = "Fluent"; # Light version of Fluent icons
        wallpaper = null; # Set your wallpaper path here if desired
      };

      # Panel configuration (Windows 11-style: centered taskbar at bottom)
      panels = [
        {
          location = "bottom";
          height = 44;
          floating = false;
          widgets = [
            # Start menu (left side)
            {
              name = "org.kde.plasma.kickoff";
              config.General.icon = "start-here-kde-symbolic";
            }
            # Spacer to push task manager to center
            "org.kde.plasma.marginsseparator"
            # Task manager (centered)
            {
              name = "org.kde.plasma.icontasks";
              config.General = {
                launchers = [
                  "applications:org.kde.dolphin.desktop"
                  "applications:brave-browser.desktop"
                  "applications:google-chrome.desktop"
                  "applications:firefox.desktop"
                ];
              };
            }
            # Spacer
            "org.kde.plasma.marginsseparator"
            # System tray (right side)
            "org.kde.plasma.systemtray"
            # Clock
            {
              name = "org.kde.plasma.digitalclock";
              config.Appearance = {
                showDate = true;
                dateFormat = "shortDate";
              };
            }
            # Show Desktop button (right edge, like Windows)
            "org.kde.plasma.showdesktop"
          ];
        }
      ];

      # Window behavior
      kwin = {
        borderlessMaximizedWindows = true;
        effects = {
          desktopSwitching.animation = "slide";
          minimization.animation = "magiclamp";
          windowOpenClose.animation = "glide";
        };
      };

      # Keyboard shortcuts (Windows-like)
      shortcuts = {
        kwin = {
          "Window Close" = "Alt+F4";
          "Window Maximize" = "Meta+Up";
          "Window Minimize" = "Meta+Down";
          "Window Quick Tile Left" = "Meta+Left";
          "Window Quick Tile Right" = "Meta+Right";
          "Switch to Desktop 1" = "Meta+1";
          "Switch to Desktop 2" = "Meta+2";
          "Switch to Desktop 3" = "Meta+3";
          "Switch to Desktop 4" = "Meta+4";
        };
        plasmashell = {
          "activate application launcher" = "Meta";
        };
      };

      # Disable KDE Wallet
      configFile."kwalletrc"."Wallet"."Enabled" = false;

      # Hot corners (optional - Windows 11 doesn't use them by default)
      hotkeys.commands = { };

      # Power management settings
      powerdevil = {
        AC = {
          dimDisplay = {
            enable = true;
            idleTimeout = 1200; # 20 minutes
          };
          turnOffDisplay = {
            idleTimeout = 3600; # 1 hour
          };
          autoSuspend = {
            action = "sleep";
            idleTimeout = 7200; # 2 hours
          };
          whenSleepingEnter = "standby";
        };
        battery = {
          dimDisplay = {
            enable = true;
            idleTimeout = 1200; # 20 minutes
          };
          turnOffDisplay = {
            idleTimeout = 3600; # 1 hour
          };
          autoSuspend = {
            action = "sleep";
            idleTimeout = 7200; # 2 hours
          };
          whenSleepingEnter = "standby";
        };
        lowBattery = {
          dimDisplay = {
            enable = true;
            idleTimeout = 1200; # 20 minutes
          };
          turnOffDisplay = {
            idleTimeout = 3600; # 1 hour
          };
          autoSuspend = {
            action = "sleep";
            idleTimeout = 7200; # 2 hours
          };
          whenSleepingEnter = "standby";
        };
      };

      # Disable screen locking entirely (via config file for reliability)
      configFile."kscreenlockerrc" = {
        "Daemon"."Autolock" = false;
        "Daemon"."LockOnResume" = false;
        "Daemon"."Timeout" = 0; # Never lock after idle
      };
    };

    # Konsole (KDE terminal) configuration
    programs.konsole = {
      enable = true;
      defaultProfile = "Default";
      profiles = {
        Default = {
          name = "Default";
          colorScheme = "Breeze";
          font = {
            name = "IntoneMono Nerd Font";
            size = 11;
          };
        };
      };
    };

    # User packages managed by home-manager
    home.packages = with pkgs; [
      # Themes
      fluent-icon-theme
      adwaita-icon-theme # Includes Adwaita cursor (Windows-like)

      # Fonts
      nerd-fonts.intone-mono
    ];
  };
}
