{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.linuxWallpaperengine;

  # WORKAROUND: wallpaperengine-gui is not in nixpkgs, see WORKAROUNDS.md
  wallpaperengine-gui = pkgs.stdenv.mkDerivation {
    pname = "wallpaperengine-gui";
    version = "1.2.0";
    src = pkgs.fetchFromGitHub {
      owner = "MikiDevLog";
      repo = "wallpaperengine-gui";
      rev = "c109483936c4b2b26b0cad145fa59bb9d4c2c673";
      hash = "sha256-ICS/NI+xS7U1POSG2yTWOw9DNU4CFFnitoHiKJNaEhM=";
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
  };
}
