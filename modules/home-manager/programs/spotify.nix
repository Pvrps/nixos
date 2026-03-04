{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.custom.programs.spotify;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    inputs.spicetify-nix.homeManagerModules.default
  ];

  options.custom.programs.spotify.enable = lib.mkEnableOption "Spotify with Spicetify (Stylix theming + spoofed premium features)";

  config = lib.mkIf cfg.enable {
    programs.spicetify = {
      enable = true;

      enabledExtensions = with spicePkgs.extensions; [
        adblock
        shuffle
        volumePercentage
        hidePodcasts
      ];
    };

    xdg.configFile."pipewire/pipewire-pulse.conf.d/99-spotify-volume.conf".text = ''
      pulse.rules = [
        {
          matches = [
            { application.process.binary = "spotify" }
          ]
          actions = {
            quirks = [ "block-sink-volume" ]
          }
        }
      ]
    '';
  };
}
