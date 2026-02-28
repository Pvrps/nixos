{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  inherit (config.lib.stylix) colors;
in {
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  programs.dank-material-shell = {
    enable = true;
    enableCalendarEvents = false; # Disabled due to khal build failure on unstable
    settings = {
      showDock = false;
      blurredWallpaperLayer = true;
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

      # colorscheme
      currentThemeName = lib.mkForce "Stylix";
      customThemeFile = lib.mkForce "${config.xdg.configHome}/DankMaterialShell/colorschemes/Stylix.json";
    };
  };

  xdg.configFile."DankMaterialShell/colorschemes/Stylix.json".text = builtins.toJSON {
    dark = {
      mPrimary = "#${colors.base0D}"; # Blue
      mOnPrimary = "#${colors.base00}"; # Background
      mSecondary = "#${colors.base0E}"; # Purple
      mOnSecondary = "#${colors.base00}";
      mTertiary = "#${colors.base0C}"; # Cyan
      mOnTertiary = "#${colors.base00}";
      mError = "#${colors.base08}"; # Red
      mOnError = "#${colors.base00}";
      mSurface = "#${colors.base00}"; # Background
      mOnSurface = "#${colors.base05}"; # Text
      mHover = "#${colors.base02}"; # Selection
      mOnHover = "#${colors.base05}";
      mSurfaceVariant = "#${colors.base01}"; # Darker/Lighter BG
      mOnSurfaceVariant = "#${colors.base05}";
      mOutline = "#${colors.base03}"; # Grey
      mShadow = "#${colors.base00}";
    };
    light = {
      mPrimary = "#${colors.base0D}";
      mOnPrimary = "#${colors.base00}";
      mSurface = "#${colors.base00}";
      mOnSurface = "#${colors.base05}";
    };
  };
}
