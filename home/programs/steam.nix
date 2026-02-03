{ pkgs, ... }:
{
  home.packages = with pkgs; [
    
  ];

  programs.mangohud = {
    enable = true;
    settings = {
      full = true;
      no_display = true;
      #cpu_temp = true;
      #gpu_temp = true;
      #ram = true;
      #vram = true;
      fps = true;
      #frametime = true;

      position = "top-right";
      width = 280;
    };
  };
}
