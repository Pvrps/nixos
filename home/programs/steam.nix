{ pkgs, ... }:
{
  home.packages = with pkgs; [
    
  ];

  programs.mangohud = {
    enable = true;
    settings = {
      full = false;
      no_display = true;
      #cpu_temp = true;
      #gpu_temp = true;
      #ram = true;
      #vram = true;
      fps = true;
      #frametime = true;

      position = "top-right";
      width = 280;
      alpha = 0.8;
      background_alpha = 0.8;
      font_size = 18;
    };
  };
}
