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
    home.packages = [pkgs.osu-lazer-bin];

    xdg.desktopEntries."osu!" = {
      name = "osu!";
      comment = "A free-to-win rhythm game. Rhythm is just a *click* away!";
      exec = "env SDL_VIDEODRIVER=x11 OZONE_PLATFORM=x11 PIPEWIRE_LATENCY=64/48000 gamemoderun osu! %u";
      icon = "osu";
      terminal = false;
      categories = ["Game"];
      mimeType = [
        "application/x-osu-beatmap-archive"
        "application/x-osu-skin-archive"
        "application/x-osu-beatmap"
        "application/x-osu-storyboard"
        "application/x-osu-replay"
        "x-scheme-handler/osu"
      ];
    };

    custom.programs.niri.windowRules = lib.mkIf config.custom.programs.niri.enable [
      ''
        window-rule {
          match app-id="^osu!$"
          open-maximized true
        }
      ''
    ];
  };
}
