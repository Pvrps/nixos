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

  options.custom.programs.discord.enable = lib.mkEnableOption "Discord via nixcord/vesktop";

  config = lib.mkIf cfg.enable {
    programs.nixcord = {
      enable = true;

      #discord.enable = true;
      #discord.vencord.enable = true;

      vesktop.enable = true;

      config = {
        useQuickCss = true;
        frameless = true;
        themeLinks = [
        ];
        inherit (config.custom.discord) plugins;
      };
    };

    custom.niri.windowRules = [
      ''window-rule {
    match app-id="vesktop" title="Discord Updater"
    match app-id="discord" title="Discord Updater"
    match app-id="vesktop" title="Checking for updates..."
    match app-id="discord" title="Checking for updates..."
    open-floating true
    open-maximized false
}''
    ];
  };
}
