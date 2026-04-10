{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.custom.programs.imv;
in {
  options.custom.programs.imv.enable = lib.mkEnableOption "imv image viewer";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      imv
    ];

    xdg.configFile."imv/config".text = ''
      [options]
      overlay = true
      overlay_font = ${config.stylix.fonts.monospace.name or "monospace"}:12
    '';

    xdg.mimeApps.defaultApplications = {
      "image/bmp" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/jpg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "image/svg+xml" = "imv.desktop";
      "image/tiff" = "imv.desktop";
      "image/webp" = "imv.desktop";
    };
  };
}
