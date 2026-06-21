{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.osu;
in {
  options.custom.programs.osu.enable = lib.mkEnableOption "osu!lazer (AppImage build with score submission and multiplayer)";

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.osu-lazer-bin];
  };
}
