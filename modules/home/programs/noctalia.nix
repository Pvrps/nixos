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
    barDensity = lib.mkOption {
      type = lib.types.enum ["compact" "comfortable" "default" "spacious"];
      default = "default";
      description = "Bar density setting";
    };
    launcherShowCategories = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show categories in app launcher";
    };
    launcherShowAboveFullscreen = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Show launcher above fullscreen apps";
    };
    notificationsMonitor = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Show notifications only on specific monitor (e.g. DP-1)";
    };
    discreteGpuMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable discrete GPU monitoring in system monitor";
    };
    hideBrightnessFromBar = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Remove brightness widget from bar";
    };
    lockscreenMonitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Show lockscreen only on specific monitors (e.g. [\"DP-1\"])";
    };
    lockscreenAnimations = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable lockscreen animations";
    };
    lockscreenBlur = lib.mkOption {
      type = lib.types.float;
      default = 0.0;
      description = "Lockscreen blur amount (0.0-1.0)";
    };
    lockscreenTint = lib.mkOption {
      type = lib.types.float;
      default = 0.0;
      description = "Lockscreen tint amount (0.0-1.0)";
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
      settings = let
        defaults = {
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
          };
          ui = {
            boxBorderEnabled = true;
          };
          notifications = {
            location = "top_right";
          };
          appLauncher = {
            sortByMostUsed = true;
          };
          bar = {
            density = "default";
            widgets.right = [
              { id = "Tray"; }
              { id = "NotificationHistory"; }
              { id = "Battery"; }
              { id = "Volume"; }
              { id = "Brightness"; }
              { id = "ControlCenter"; }
            ];
          };
          systemMonitor = {
            enableDgpuMonitoring = false;
          };
        };
        userSettings = let
          barWithoutBrightness = {
            widgets = {
              right = [
                { id = "Tray"; }
                { id = "NotificationHistory"; }
                { id = "Battery"; }
                { id = "Volume"; }
                { id = "ControlCenter"; }
              ];
            };
          };
        in {
          bar = {
            density = cfg.barDensity;
          } // lib.mkIf (cfg.hideBrightnessFromBar) barWithoutBrightness;
          appLauncher = {
            showCategories = cfg.launcherShowCategories;
            overviewLayer = cfg.launcherShowAboveFullscreen;
          };
          notifications = lib.mkIf (cfg.notificationsMonitor != null) {
            monitors = [cfg.notificationsMonitor];
          };
          systemMonitor = {
            enableDgpuMonitoring = cfg.discreteGpuMonitoring;
          };
          general = let
            lockscreenSettings = {
              lockScreenMonitors = cfg.lockscreenMonitors;
              lockScreenAnimations = cfg.lockscreenAnimations;
              lockScreenBlur = cfg.lockscreenBlur;
              lockScreenTint = cfg.lockscreenTint;
            };
          in lib.mkIf (cfg.lockscreenMonitors != [] || cfg.lockscreenAnimations != true || cfg.lockscreenBlur != 0.0 || cfg.lockscreenTint != 0.0) lockscreenSettings;
        };
      in lib.recursiveUpdate defaults userSettings;
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
