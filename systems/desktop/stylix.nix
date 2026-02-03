{ pkgs, ... }:
{
  stylix = {
    enable = true;

    #base16Scheme = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml";

    base16Scheme = {
      base00 = "14171d"; # inkBg0     (Background)
      base01 = "1f1f26"; # inkBg1     (Lighter BG / Status)
      base02 = "393B44"; # inkBg3     (Selection)
      base03 = "5C6066"; # gray5      (Comments)
      base04 = "75797f"; # gray4      (Dark FG)
    
      # Foreground: Switched to 'fg2' (brighter) for high contrast
      base05 = "f2f1ef"; # fg2        (Main Text - Bright White)
      base06 = "ffffff"; # pearlWhite (Lightest Text)
      base07 = "c5c9c7"; # fg         (Alternate Text)

      # The Saturated Palette (Vibrant / Poppy)
      base08 = "C93134"; # redSaturated    (Variables / Errors)
      base09 = "BC8A6C"; # orangeSaturated (Integers)
      base0A = "E59F49"; # yellowSaturated (Classes / Search)
      base0B = "8FC055"; # greenSaturated  (Strings - Lime Green Pop)
      base0C = "6BAE97"; # green5Saturated (Cyan/Teal - Vibrant Aqua)
      base0D = "6EBBD4"; # blueSaturated   (Functions - Sky Blue)
      base0E = "8A88B0"; # violetSaturated (Keywords)
      base0F = "A08AA2"; # pinkSaturated   (Misc / Numbers)
    };

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
      name = "phinger-cursors-dark";
      package = pkgs.phinger-cursors;
      size = 32;
    };

    fonts = {
      serif = {
        package = pkgs.eb-garamond;
        name = "EB Garamond";
      };

      sansSerif = {
        package = pkgs.geist-font;
        name = "Geist";
      };

      monospace = {
        package = pkgs.nerd-fonts.geist-mono;
        name = "GeistMono Nerd Font";
      };

      emoji = {
        package = pkgs.twitter-color-emoji;
        name = "Twitter Color Emoji";
      };
    };

    # cursor = {
    #   package = pkgs.bibata-cursors;
    #   name = "Bibata-Modern-Ice";
    #   size = 24;
    # };

    # fonts = {
    #   serif = {
    #     package = pkgs.noto-fonts;
    #     name = "Noto Serif";
    #   };
    #   sansSerif = {
    #     package = pkgs.noto-fonts;
    #     name = "Noto Sans";
    #   };
    #   monospace = {
    #     package = pkgs.nerd-fonts.jetbrains-mono;
    #     name = "JetBrainsMono Nerd Font";
    #   };
    #   emoji = {
    #     package = pkgs.noto-fonts-color-emoji;
    #     name = "Noto Color Emoji";
    #   };
    # };
  };
}
