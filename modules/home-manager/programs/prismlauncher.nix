{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.prismlauncher;
in {
  options.custom.programs.prismlauncher.enable = lib.mkEnableOption "Prism Launcher for Minecraft";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.prismlauncher
    ];
  };
}
