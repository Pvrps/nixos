{ pkgs, ... }:
{
  stylix = {
    enable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";

    image = pkgs.fetchurl {
      url = "https://github.com/noctalia-dev/noctalia-shell/blob/main/Assets/Wallpaper/noctalia.png?raw=true";
      sha256 = "sha256-Qq6Qbcs8ngDCGZs9C4SWhI2P9/gDCirx11VGrbYmWb4=";
    };

    polarity = "dark";

    opacity = {
      terminal = 0.9;
      popups = 0.9;
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Ice";
      size = 24;
    };

    fonts = {
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      sansSerif = {
        package = pkgs.noto-fonts;
        name = "Noto Sans";
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}
