{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    imv
  ];

  xdg.configFile."imv/config".text = ''
    [options]
    overlay = true
    overlay_font = ${config.stylix.fonts.monospace.name}:12
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
}
