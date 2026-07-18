{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.custom.programs.steam;

  steamBin =
    if cfg.slsSteam.enable
    then "SLSsteam"
    else "steam";
in {
  options.custom.programs.steam = {
    enable = lib.mkEnableOption "Steam gaming with MangoHud";
    slsSteam = {
      enable = lib.mkEnableOption "SLSsteam Steam Family Share bypass";
    };
    millenniumPlugins = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          url = lib.mkOption {
            type = lib.types.str;
            description = "URL of the plugin release zip.";
          };
          sha256 = lib.mkOption {
            type = lib.types.str;
            description = "Hash of the fetched zip (fetchzip).";
          };
        };
      });
      # Shared household plugin set. Setting this option in a user file
      # replaces the whole set — per-user divergence is one override away.
      # MAINTENANCE: version-pinned release zips; bump url+sha256 together.
      default = {
        extendium = {
          url = "https://github.com/BossSloth/Extendium/releases/download/v1.1.1/Extendium-plugin-1.1.1.zip";
          sha256 = "0dg7q27ppzri6vqk24s1v6d6q8d0iicw3igdqc55pc8g050v1pfx";
        };
        achievement-groups = {
          url = "https://github.com/BossSloth/SteamHunter-plugin/releases/download/v2.0.2/Achievement-Groups-plugin-2.0.2.zip";
          sha256 = "18g921w6idswwvbha9dyszki60pv1pvhlzsi817ddps8pifhwpwj";
        };
      };
      description = "Millennium plugins to install, keyed by plugin directory name under ~/.local/share/millennium/plugins. Defaults to the shared household set.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      lib.optionals cfg.slsSteam.enable [
        inputs.sls-steam.packages.${pkgs.system}.wrapped
      ];

    xdg.desktopEntries = lib.mkIf cfg.slsSteam.enable {
      steam = {
        name = "Steam";
        exec = "SLSsteam %U";
        icon = "steam";
        terminal = false;
        type = "Application";
        categories = ["Network" "FileTransfer" "Game"];
        mimeType = ["x-scheme-handler/steam" "x-scheme-handler/steamlink"];
        settings = {
          PrefersNonDefaultGPU = "true";
          "X-KDE-RunOnDiscreteGpu" = "true";
        };
      };
    };

    services.sls-steam.config = lib.mkIf cfg.slsSteam.enable {
      DisableFamilyShareLock = true;
      UseWhitelist = false;
      AutoFilterList = true;
      PlayNotOwnedGames = false;
      SafeMode = false;
    };

    programs.mangohud = {
      enable = true;
      settings = {
        round_corners = 20;
        text_outline = false;
        font_size = lib.mkForce 24;

        position = "top-right";
        table_columns = 3;
        cell_padding_vertical = 8;

        gpu_stats = true;
        gpu_temp = true;

        cpu_stats = true;
        cpu_temp = true;

        ram = true;
        vram = true;

        fps = true;
        frametime = true;
        frame_timing = 1;

        histogram_height = 24;
      };
    };

    home.persistence."/persist".directories = [".steam"];

    xdg.dataFile = lib.mapAttrs' (name: plugin:
      lib.nameValuePair "millennium/plugins/${name}" {
        source = pkgs.fetchzip {
          inherit (plugin) url sha256;
        };
      })
    cfg.millenniumPlugins;

    custom.programs.niri.startupCommands = lib.mkIf config.custom.programs.niri.enable [
      ''"bash" "-c" "nm-online -q --timeout=30 || true; STEAM_DISABLE_BROWSER_COMPOSITOR_STEAM_HEADER=1 ${steamBin} -system-composer -silent > /dev/null 2>&1"''
    ];

    xdg.configFile."autostart/steam.desktop" = lib.mkIf config.custom.programs.kde.enable {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Steam
        Exec=bash -c 'nm-online -q --timeout=30 || true; STEAM_DISABLE_BROWSER_COMPOSITOR_STEAM_HEADER=1 ${steamBin} -system-composer -silent > /dev/null 2>&1'
        Icon=steam
        Terminal=false
        X-KDE-autostart-after=panel
      '';
    };

    custom.programs.niri.windowRulesConfig = lib.mkIf config.custom.programs.niri.enable ''
      window-rule {
          match app-id=r#"^steam$"# title=r#"^notificationtoasts_\d+_desktop$"#
          open-floating true
          open-maximized false
          open-focused false
          default-floating-position x=10 y=10 relative-to="bottom-right"
          focus-ring { width 0; }
          block-out-from "screencast"
      }

      window-rule {
          match app-id=r#"^steam$"# title=r#"^Friends List$"#
          open-floating true
      }
    '';
  };
}
