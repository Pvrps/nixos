{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.clapper;
in {
  options.custom.programs.clapper.enable = lib.mkEnableOption "Clapper media player";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      clapper
    ];

    xdg.mimeApps.defaultApplications = {
      "video/mp4" = "com.github.rafostar.Clapper.desktop";
      "video/webm" = "com.github.rafostar.Clapper.desktop";
      "video/x-matroska" = "com.github.rafostar.Clapper.desktop";
      "video/quicktime" = "com.github.rafostar.Clapper.desktop";
    };
  };
}
