{
  pkgs,
  lib,
  ...
}: {
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
}
