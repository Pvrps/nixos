{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.osu-lazer;
in {
  options.custom.programs.osu-lazer = {
    enable = lib.mkEnableOption "osu!lazer rhythm game";
  };

  config = lib.mkIf cfg.enable {
    # Just the native package, no wrappers needed
    home.packages = [pkgs.osu-lazer-bin];

    custom.programs.niri.windowRules = lib.mkIf config.custom.programs.niri.enable [
      ''
        window-rule {
          match app-id="^osu!$"
          open-maximized true
          allow-tearing true
        }
      ''
    ];
  };
}
