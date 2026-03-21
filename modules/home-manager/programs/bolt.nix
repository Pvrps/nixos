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

    custom.programs.flatpak.packages = ["com.adamcake.Bolt"];

    # Java AWT/Swing fixes for Wayland compositors:
    #
    # _JAVA_AWT_WM_NONREPARENTING=1 — tells AWT that the compositor does not
    #   reparent windows (Wayland never does), so Java correctly tracks its own
    #   window bounds and responds to resize events.  Without this the game
    #   viewport stays at its initial small size and the rest of the window fills
    #   with black bars regardless of the Niri window rule.
    #
    # sun.java2d.uiScale=1 — prevents Java from applying a second DPI-scaling
    #   pass on top of XWayland's, which would otherwise produce an additional
    #   resolution mismatch on HiDPI outputs.
    #
    # sun.java2d.opengl=false — disables the Java2D OpenGL pipeline.  When
    #   XWayland resizes a window the OpenGL context retains its old dimensions
    #   and tiles/repeats the stale framebuffer, producing a "split" or
    #   duplicated view of the RuneLite UI after any resize event.
    #
    # sun.java2d.xrender=false — disables the Java2D XRender (hardware)
    #   pipeline.  After disabling OpenGL, Java2D falls back to XRender, which
    #   has the same stale-surface problem when RuneLite's Swing layout changes
    #   size (e.g. opening/closing the sidebar panel).  Disabling XRender forces
    #   fully software-rendered Java2D painting, which correctly repaints after
    #   every layout change.  RuneLite's in-game rendering uses LWJGL directly
    #   and is unaffected by either flag.
    xdg.dataFile."flatpak/overrides/com.adamcake.Bolt".text = ''
      [Environment]
      _JAVA_AWT_WM_NONREPARENTING=1
      JAVA_TOOL_OPTIONS=-Dsun.java2d.uiScale=2 -Dsun.java2d.opengl=false -Dsun.java2d.xrender=false
    '';

    custom.programs.niri.windowRules = [
      # Keep the small launcher window floating so it doesn't hijack a tile slot.
      ''        window-rule {
                  match app-id=r#"^com\.adamcake\.Bolt$"#
                  open-floating true
                  open-maximized false
              }''
      # RuneLite game window – maximise on open so it fills the logical workspace.
      ''        window-rule {
                  match app-id=r#"^RuneLite$"#
                  open-maximized true
              }''
      # Jagex native client (launched by Bolt).
      ''        window-rule {
                  match app-id=r#"^jagex_launcher$"#
                  open-maximized true
              }''
    ];
  };
}
