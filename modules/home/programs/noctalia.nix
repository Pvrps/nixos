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
    plugins = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          enable = lib.mkEnableOption "Noctalia plugin ${name}";
          sourceUrl = lib.mkOption {
            type = lib.types.str;
            default = "https://github.com/noctalia-dev/noctalia-plugins";
            description = "Plugin registry source URL (composite key prefix).";
          };
          barWidget = lib.mkEnableOption "append this plugin's bar widget to the bar's right section";
          settings = lib.mkOption {
            type = lib.types.attrs;
            default = {};
            description = "Per-plugin settings written to plugins/<id>/settings.json.";
          };
        };
      }));
      default = {};
      description = "Noctalia registry plugins to install/enable declaratively per user.";
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
      plugins = lib.optionalAttrs (cfg.plugins != {}) {
        sources = [
          {
            enabled = true;
            name = "Official Noctalia Plugins";
            url = "https://github.com/noctalia-dev/noctalia-plugins";
          }
        ];
        states =
          lib.mapAttrs'
          (name: plugin:
            lib.nameValuePair name {
              enabled = true;
              inherit (plugin) sourceUrl;
            })
          (lib.filterAttrs (_: p: p.enable) cfg.plugins);
        version = 2;
      };
      pluginSettings =
        lib.mapAttrs'
        (name: plugin: lib.nameValuePair name plugin.settings)
        (lib.filterAttrs (_: p: p.enable && p.settings != {}) cfg.plugins);
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
          lockScreenMonitors = [cfg.primaryMonitor];
        };
        ui = {
          boxBorderEnabled = true;
        };
        systemMonitor = {
          enableDgpuMonitoring = true;
        };
        notifications = {
          location = "top_right";
          monitors = [cfg.primaryMonitor];
        };
        appLauncher = {
          sortByMostUsed = true;
          overviewLayer = true;
        };
        bar = {
          widgets = {
            left = [
              {id = "Launcher";}
              {id = "Clock";}
              {
                id = "SystemMonitor";
                showGpuTemp = true;
              }
              {id = "ActiveWindow";}
              {id = "MediaMini";}
            ];
            center = [
              {id = "Workspace";}
            ];
            right =
              [
                {id = "Tray";}
                {id = "NotificationHistory";}
                {id = "Battery";}
                {id = "Volume";}
                {id = "ControlCenter";}
              ]
              ++ (lib.concatLists (lib.mapAttrsToList
                (name: plugin:
                  lib.optional plugin.barWidget {id = "plugin:${name}";})
                (lib.filterAttrs (_: p: p.enable) cfg.plugins)));
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

    home.persistence."/persist".directories = [".cache/noctalia"];

    custom.programs.niri = lib.mkIf config.custom.programs.niri.enable {
      startupCommands = [
        ''"bash" "-c" "if command -v noctalia-shell >/dev/null; then noctalia-shell; else dms run --session; fi"''
        ''"blueman-applet"''
      ];

      keybinds = [
        ''Mod+D { spawn "noctalia-shell" "ipc" "call" "launcher" "toggle"; }''
        ''Mod+C { spawn "noctalia-shell" "ipc" "call" "controlCenter" "toggle"; }''
        ''Mod+Shift+L { spawn "noctalia-shell" "ipc" "call" "lockScreen" "lock"; }''
      ];

      layerRulesConfig = ''
        layer-rule {
            match namespace=r#"^noctalia-notifications"#
            block-out-from "screen-capture"
        }
      '';
    };
  };
}
