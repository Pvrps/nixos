{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.thunar;
in {
  options.custom.programs.thunar = {
    enable = lib.mkEnableOption "Thunar graphical file manager as the default file picker";

    archiveBackend = lib.mkOption {
      type = lib.types.enum ["file-roller" "engrampa"];
      default = "file-roller";
      description = "Archive manager wired into thunar-archive-plugin for create/extract actions.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [
        pkgs.thunar
        pkgs.thunar-volman
        pkgs.thunar-archive-plugin
        pkgs.tumbler
      ]
      ++ lib.optional (cfg.archiveBackend == "file-roller") pkgs.file-roller
      ++ lib.optional (cfg.archiveBackend == "engrampa") pkgs.mate.engrampa;

    xdg.mimeApps.defaultApplications = {
      "inode/directory" = "thunar.desktop";
      "x-scheme-handler/file" = "thunar.desktop";
    };
  };
}
