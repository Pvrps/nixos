{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.custom.programs.spotify;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  inherit (config.lib.stylix) colors;
in {
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  options.custom.programs.spotify.enable = lib.mkEnableOption "Spotify with Spicetify (Stylix theming + spoofed premium features)";

  config = lib.mkIf cfg.enable {
    programs.spicetify = {
      enable = true;

      theme = spicePkgs.themes.text;

      customColorScheme = {
        text = colors.base05;
        subtext = colors.base07;
        sidebar-text = colors.base05;
        main = colors.base00;
        sidebar = colors.base01;
        player = colors.base01;
        card = colors.base01;
        shadow = colors.base00;
        selected-row = colors.base02;
        button = colors.base0D;
        button-active = colors.base0B;
        button-disabled = colors.base03;
        tab-active = colors.base0D;
        notification = colors.base0C;
        notification-error = colors.base08;
        misc = colors.base0E;
      };

      enabledExtensions = with spicePkgs.extensions; [
        adblock
        shuffle
        volumePercentage
        hidePodcasts
      ];
    };
  };
}
