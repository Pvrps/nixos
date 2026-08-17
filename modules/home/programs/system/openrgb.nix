{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.openrgb;
in {
  options.custom.programs.openrgb = {
    enable = lib.mkEnableOption "OpenRGB RGB lighting control";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      (openrgb.withPlugins [
        openrgb-plugin-effects
      ])
    ];
  };
}
