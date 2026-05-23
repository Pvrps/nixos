{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.custom.programs.stremio;
in {
  options.custom.programs.stremio.enable = lib.mkEnableOption "Torrent Entertainment";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      stremio-linux-shell
    ];
  };
}
