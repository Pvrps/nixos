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

    # Override the stock .desktop entry to launch via gamemoderun (applies CPU EPP + niceness)
    # Force XWayland via SDL_VIDEODRIVER=x11 to bypass the Wayland input-routing layer:
    # native Wayland tablet input goes Compositor -> XDG portal -> game, adding ~1 frame of
    # latency. XWayland uses the direct evdev path (same as Windows), eliminating that hop.
    xdg.desktopEntries."osu!" = {
      name = "osu!";
      comment = "A free-to-win rhythm game. Rhythm is just a *click* away!";
      exec = "env SDL_VIDEODRIVER=x11 OZONE_PLATFORM=x11 gamemoderun osu! %u";
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
