{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
  ];

  xdg.desktopEntries.steam = {
    name = "Steam";
    genericName = "Application Distribution Platform";
    #exec = "env MANGOHUD=1 steam %U";
    exec = "steam %U";
    icon = "steam";
    terminal = false;
    categories = ["Network" "FileTransfer" "Game"];
    mimeType = ["x-scheme-handler/steam" "x-scheme-handler/steamlink"];
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
      frametime = false;
      frame_timing = 1;

      histogram_height = 24;
    };
  };
}
