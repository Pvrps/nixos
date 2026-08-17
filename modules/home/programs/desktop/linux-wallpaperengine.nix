{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.linuxWallpaperengine;

  wallpaperengine-gui = pkgs.stdenv.mkDerivation {
    pname = "wallpaperengine-gui";
    version = "1.2.0";
    src = pkgs.fetchFromGitHub {
      owner = "MikiDevLog";
      repo = "wallpaperengine-gui";
      rev = "c22671ad24fcf754f461fd7ac969497ee3964cc3";
      hash = "sha256-F/wjdfKTRprOmQ3Ad4dXWfdCx6BNfZpc9Ud4EVeewig=";
    };
    nativeBuildInputs = [pkgs.cmake pkgs.qt6.wrapQtAppsHook];
    buildInputs = [pkgs.qt6.qtbase];
    qtWrapperArgs = [
      "--prefix PATH : ${lib.makeBinPath [pkgs.linux-wallpaperengine]}"
    ];
  };
in {
  options.custom.programs.linuxWallpaperengine.enable =
    lib.mkEnableOption "linux-wallpaperengine (Wallpaper Engine renderer)";

  config = lib.mkIf cfg.enable {
    assertions = let
      noctaliaPath = config.custom.programs.noctalia.enable;
      kdePath = config.custom.programs.kde.enable;
    in [
      {
        assertion = config.custom.programs.steam.enable;
        message = "custom.programs.linuxWallpaperengine requires custom.programs.steam.enable = true (Wallpaper Engine workshop assets are provided via Steam).";
      }
      {
        assertion = noctaliaPath || kdePath;
        message = "custom.programs.linuxWallpaperengine requires either custom.programs.noctalia.enable (Noctalia plugin) or custom.programs.kde.enable (GUI app).";
      }
    ];

    home.packages =
      [pkgs.linux-wallpaperengine]
      ++ lib.optional config.custom.programs.kde.enable wallpaperengine-gui;

    custom.programs.noctalia.plugins."linux-wallpaperengine-controller" =
      lib.mkIf config.custom.programs.noctalia.enable
      {
        enable = true;
        barWidget = true;
        settings = {
          wallpapersFolder = "${config.home.homeDirectory}/.local/share/Steam/steamapps/workshop/content/431960";
        };
      };
  };
}
