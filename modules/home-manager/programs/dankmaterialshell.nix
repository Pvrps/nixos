{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.dankmaterialshell;
in {
  imports = [
    inputs.dms.homeModules.dank-material-shell
  ];

  options.custom.programs.dankmaterialshell.enable = lib.mkEnableOption "DankMaterialShell";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !config.custom.programs.noctalia.enable;
        message = "dankmaterialshell and noctalia cannot both be enabled — they share Mod+D and Mod+C keybinds.";
      }
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

    custom.niri.keybinds = [
      ''Mod+D { spawn "dms" "ipc" "call" "spotlight" "toggle"; }''
      ''Mod+C { spawn "dms" "ipc" "call" "control-center" "toggle"; }''
    ];

    custom.niri.layerRules = [
      ''        layer-rule {
                  match namespace=r#"^dms-notifications"#
                  block-out-from "screen-capture"
              }''
    ];
  };
}
