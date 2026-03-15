{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  cfg = config.custom.programs.discord;
in {
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  options.custom.programs.discord.enable = lib.mkEnableOption "Discord via nixcord/equibop";

  config = lib.mkIf cfg.enable {
    programs.nixcord = {
      enable = true;
      equibop.enable = true;

      config = {
        useQuickCss = true;
        frameless = true;
        themeLinks = [
        ];
        plugins = config.custom.discord.plugins // {webRichPresence.enable = true;};
      };
    };

    custom.niri.startupCommands = [
      ''"bash" "-c" "nm-online -q --timeout=30 || true; equibop --start-minimized > /dev/null 2>&1"''
    ];

    custom.niri.windowRules = [
      ''        window-rule {
                  match app-id="equibop" title="Discord Updater"
                  match app-id="equibop" title="Checking for updates..."
                  open-floating true
                  open-maximized false
              }''
    ];
  };
}
