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
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      []
      ++ lib.optionals cfg.slsSteam.enable [
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

    custom.programs.niri.startupCommands = [
      ''"bash" "-c" "nm-online -q --timeout=30 || true; STEAM_DISABLE_BROWSER_COMPOSITOR_STEAM_HEADER=1 ${steamBin} -system-composer -silent > /dev/null 2>&1"''
    ];

    custom.programs.niri.windowRulesConfig = ''
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
