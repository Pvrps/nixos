{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;
    enableCalendarEvents = false; # Disabled due to khal build failure on unstable

    # Stylix doesn't natively handle DMS wallpapers yet, so we bridge it here
    session = {
      wallpaperPath = "${config.stylix.image}";
    };

    settings = {
      showDock = false;
      blurredWallpaperLayer = false;
      blurWallpaperOnOverview = true;
      useAutoLocation = false;

      # "general" equivalent
      cornerRadius = 0;
      squareCorners = true;
      fontScale = 0.75;
      iconScale = 0.75;
      notificationPopupShadowEnabled = true;

      # "ui" equivalent
      borderEnabled = true;
      workspaceFocusedBorderEnabled = true;

      # "notifications" equivalent
      notificationPopupPosition = 2; # top_right

      # "appLauncher" equivalent
      sortAppsAlphabetically = false;

      # Let Stylix naturally handle the color themes, fonts, and opacity!
    };
  };
}
