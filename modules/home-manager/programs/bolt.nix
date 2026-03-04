{
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.bolt;
in {
  options.custom.programs.bolt.enable = lib.mkEnableOption "Bolt launcher for RuneScape (Jagex Launcher + RuneLite) via Flatpak";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.flatpak.enable;
        message = "custom.programs.bolt requires custom.programs.flatpak.enable = true.";
      }
    ];

    custom.flatpak.packages = ["com.adamcake.Bolt"];

    # Prevent Java/AWT from applying its own DPI scaling on top of XWayland's.
    # Without this, RuneLite renders at a mismatched resolution which produces
    # black bars around the game viewport on HiDPI displays (e.g. 1.5× Niri scale).
    xdg.dataFile."flatpak/overrides/com.adamcake.Bolt".text = ''
      [Environment]
      JAVA_TOOL_OPTIONS=-Dsun.java2d.uiScale=1
    '';

    custom.niri.windowRules = [
      # Keep the small launcher window floating so it doesn't hijack a tile slot.
      ''window-rule {
          match app-id=r#"^com\.adamcake\.Bolt$"#
          open-floating true
          open-maximized false
      }''
      # RuneLite game window – maximise on open so it fills the logical workspace.
      ''window-rule {
          match app-id=r#"^RuneLite$"#
          open-maximized true
      }''
      # Jagex native client (launched by Bolt).
      ''window-rule {
          match app-id=r#"^jagex_launcher$"#
          open-maximized true
      }''
    ];
  };
}
