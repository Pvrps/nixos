{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.celluloid;
in {
  options.custom.programs.celluloid.enable = lib.mkEnableOption "Celluloid media player";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      celluloid
    ];

    xdg.mimeApps.defaultApplications = {
      "video/mp4" = "io.github.celluloid_player.Celluloid.desktop";
      "video/webm" = "io.github.celluloid_player.Celluloid.desktop";
      "video/x-matroska" = "io.github.celluloid_player.Celluloid.desktop";
      "video/quicktime" = "io.github.celluloid_player.Celluloid.desktop";
    };
  };
}
