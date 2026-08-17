{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.custom.programs.stremio;
in {
  options.custom.programs.stremio.enable = lib.mkEnableOption "Stremio media streaming app";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      stremio-linux-shell
    ];
  };
}
