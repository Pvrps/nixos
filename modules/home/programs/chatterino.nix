{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.chatterino;
in {
  options.custom.programs.chatterino = {
    enable = lib.mkEnableOption "Chatterino2 Twitch chat client";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.chatterino2];
  };
}
