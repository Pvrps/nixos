{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.noctalia;
  inherit (config.lib.stylix) colors;
in {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  options.custom.programs.noctalia = {
    enable = lib.mkEnableOption "Noctalia shell";
    primaryMonitor = lib.mkOption {
      type = lib.types.str;
      description = "Wayland output name used for lock screen and notifications. Required when noctalia is enabled.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.system.wayland.enable;
        message = "noctalia module requires a Wayland compositor to be enabled (e.g. custom.programs.niri.enable = true).";
      }
    ];

    programs.noctalia-shell = {
      enable = true;
      settings = {
        dock = {
          enabled = false;
        };
        wallpaper = {
          enabled = true;
        };
        location = {
          name = "Ontario";
        };
        general = {
          radiusRatio = 0;
          iRadiusRatio = 0;
          boxRadiusRatio = 0;
          screenRadiusRatio = 0;
          scaleRatio = 0.75;
          enableShadows = true;
          lockScreenMonitors = [ cfg.primaryMonitor ];
        };
        ui = {
          boxBorderEnabled = true;
        };
        systemMonitor = {
          enableDgpuMonitoring = true;
        };
        notifications = {
          location = "top_right";
          monitors = [ cfg.primaryMonitor ];
        };
        appLauncher = {
          sortByMostUsed = true;
          overviewLayer = true;
        };
        bar = {
          widgets = {
            left = [
              { id = "Launcher"; }
              { id = "Clock"; }
              {
                id = "SystemMonitor";
                showGpuTemp = true;
              }
              { id = "ActiveWindow"; }
              { id = "MediaMini"; }
            ];
            center = [
              { id = "Workspace"; }
            ];
            right = [
              { id = "Tray"; }
              { id = "NotificationHistory"; }
              { id = "Battery"; }
              { id = "Volume"; }
              { id = "ControlCenter"; }
            ];
          };
        };
      };
    };

    xdg.configFile."noctalia/colorschemes/Stylix.json".text = builtins.toJSON {
      dark = {
        mPrimary = "#${colors.base0D}"; # Blue
        mOnPrimary = "#${colors.base00}"; # Background
        mSecondary = "#${colors.base0E}"; # Purple
        mOnSecondary = "#${colors.base00}";
        mTertiary = "#${colors.base0C}"; # Cyan
        mOnTertiary = "#${colors.base00}";
        mError = "#${colors.base08}"; # Red
        mOnError = "#${colors.base00}";
        mSurface = "#${colors.base00}"; # Background
        mOnSurface = "#${colors.base05}"; # Text
        mHover = "#${colors.base02}"; # Selection
        mOnHover = "#${colors.base05}";
        mSurfaceVariant = "#${colors.base01}"; # Darker/Lighter BG
        mOnSurfaceVariant = "#${colors.base05}";
        mOutline = "#${colors.base03}"; # Grey
        mShadow = "#${colors.base00}";
      };
      light = {
        mPrimary = "#${colors.base0D}";
        mOnPrimary = "#${colors.base00}";
        mSurface = "#${colors.base00}";
        mOnSurface = "#${colors.base05}";
      };
    };

    custom.programs.niri = {
      startupCommands = [
        ''"bash" "-c" "if command -v noctalia-shell >/dev/null; then noctalia-shell; else dms run --session; fi"''
        ''"blueman-applet"''
      ];

      keybinds = [
        ''Mod+D { spawn "noctalia-shell" "ipc" "call" "launcher" "toggle"; }''
        ''Mod+C { spawn "noctalia-shell" "ipc" "call" "controlCenter" "toggle"; }''
        ''Mod+Shift+L { spawn "noctalia-shell" "ipc" "call" "lockScreen" "lock"; }''
      ];

      layerRules = [
        ''          layer-rule {
                      match namespace=r#"^noctalia-notifications"#
                      block-out-from "screen-capture"
                  }''
      ];
    };
  };
}
