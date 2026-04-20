{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.steam;
in {
  options.custom.programs.steam.enable = lib.mkEnableOption "Steam gaming with MangoHud";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
    ];

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

    custom.programs.niri.startupCommands = [
      ''"bash" "-c" "nm-online -q --timeout=30 || true; steam -system-composer -silent > /dev/null 2>&1"''
    ];

    custom.programs.niri.windowRules = [
      ''        window-rule {
                  match app-id=r#"^steam$"# title=r#"^notificationtoasts_\d+_desktop$"#
                  open-floating true
                  open-maximized false
                  open-focused false
                  default-floating-position x=10 y=10 relative-to="bottom-right"
                  focus-ring { width 0; }
                  block-out-from "screencast"
              }''
      ''        window-rule {
                  match app-id=r#"^steam$"# title=r#"^Friends List$"#
                  open-floating true
              }''
    ];
  };
}
