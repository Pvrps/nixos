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
  };
}
