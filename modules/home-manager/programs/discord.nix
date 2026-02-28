{
  pkgs,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  programs.nixcord = {
    enable = true;

    #discord.enable = true;
    discord.vencord.enable = true;

    #vesktop.enable = true;

    config = {
      useQuickCss = true;
      frameless = true;
      themeLinks = [
      ];
      inherit (config.custom.discord) plugins;
    };
  };
}
