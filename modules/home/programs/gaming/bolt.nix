{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}: let
  cfg = config.custom.programs.bolt;

  # Bolt's own settings file. It lives inside the Flatpak per-app tree, which
  # is persisted wholesale via the ".var" entry in modules/home/profiles/
  # desktop.nix, so nothing extra is needed to survive a reboot.
  launcherJson = "$HOME/.var/app/com.adamcake.Bolt/config/bolt-launcher/launcher.json";

  nvidiaWayland =
    (osConfig.custom.nvidia.enable or false)
    && config.custom.system.wayland.enable;

  # Force the RS3 client's OpenGL onto zink (GL-on-Vulkan) instead of NVIDIA's
  # native GL driver.  Under XWayland the NVIDIA GLX/EGL path mishandles the
  # client's context, and zink — layered on top of the same NVIDIA Vulkan
  # driver — renders correctly with no measurable loss.
  #
  #   MESA_LOADER_DRIVER_OVERRIDE=zink   pick the zink gallium driver
  #   GALLIUM_DRIVER=zink                ...and again for the gallium loader
  #   __GLX_VENDOR_LIBRARY_NAME=mesa     override the system-wide "nvidia"
  #                                      value set in modules/nixos/nvidia.nix
  #                                      so GLVND dispatches to Mesa, not to
  #                                      NVIDIA's own GLX vendor library
  #   LIBGL_KOPPER_DRI2=1                use the DRI2 path in kopper (zink's
  #                                      window-system integration); DRI3 under
  #                                      XWayland produces a black viewport
  # Only correct on NVIDIA: on AMD/Intel the native Mesa driver is already in
  # use and forcing zink would be a pure regression.  Hence the nvidiaWayland
  # gate on the option default below.
  zinkLaunchCommand =
    "/usr/bin/env MESA_LOADER_DRIVER_OVERRIDE=zink "
    + "__GLX_VENDOR_LIBRARY_NAME=mesa GALLIUM_DRIVER=zink LIBGL_KOPPER_DRI2=1 %command%";
in {
  options.custom.programs.bolt = {
    enable = lib.mkEnableOption "Bolt launcher for RuneScape (Jagex Launcher + RuneLite) via Flatpak";

    rs3LaunchCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default =
        if nvidiaWayland
        then zinkLaunchCommand
        else null;
      description = ''
        Value enforced for `rs_launch_command` in Bolt's launcher.json, with
        `%command%` standing in for the real client invocation.

        This is the only launch hook Bolt scopes to RS3 specifically; RuneLite,
        OSRS and HDOS have their own keys, which this module leaves alone.  A
        Flatpak `[Environment]` override would apply to the whole sandbox (and
        so to the launcher UI and every other client), which is why the value
        is written into Bolt's config instead.

        `null` disables management entirely and leaves the key untouched.
      '';
    };

    requireResizableBar = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Only apply {option}`rs3LaunchCommand` when Resizable BAR is actually
        active, probed at activation time from the GPU's PCI BAR1 size.

        Resizable BAR cannot be detected during evaluation — it is firmware and
        runtime state — so this is a runtime gate rather than part of the
        option's default.

        Set to false to apply the command regardless of the probe.
      '';
    };
  };

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
    # sun.java2d.uiScale=2 — prevents Java from applying a second DPI-scaling
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
    #
    # Xcursor theme env vars + filesystem access inside the Flatpak sandbox:
    #
    # Java AWT's Cursor.getPredefinedCursor(CROSSHAIR_CURSOR) calls
    # XCreateFontCursor() which returns an ugly core-font bitmap on its own.
    # However, XWayland intercepts the resulting XDefineCursor(), maps the
    # shape (XC_crosshair) back to the cursor name "crosshair", and loads
    # the themed cursor via libXcursor — *if* the theme files are reachable.
    #
    # Without these overrides the sandbox can't follow the symlinks that
    # home-manager puts in ~/.icons/Bibata-Modern-Classic → /nix/store/…,
    # so XWayland falls back to the un-themed core font cursor.
    xdg.dataFile."flatpak/overrides/com.adamcake.Bolt".text = ''
      [Environment]
      JAVA_TOOL_OPTIONS=-Dsun.java2d.uiScale=2 -D_JAVA_AWT_WM_NONREPARENTING=1 -Dsun.java2d.opengl=false -Dsun.java2d.xrender=false
      XCURSOR_THEME=${config.stylix.cursor.name}
      XCURSOR_SIZE=${toString config.stylix.cursor.size}
      XCURSOR_PATH=${config.stylix.cursor.package}/share/icons

      [Context]
      filesystems=${config.stylix.cursor.package}/share/icons/${config.stylix.cursor.name}:ro
    '';

    # launcher.json cannot be a home-manager-managed file: it is a store
    # symlink (read-only) while Bolt rewrites it on every settings change, and
    # it also carries state Bolt owns — selected game/client, account ids, UI
    # toggles.  So we merge the single key we care about into the live file,
    # the same way modules/nixos/services/rustdesk.nix handles RustDesk.toml.
    home.activation.boltRs3LaunchCommand = lib.mkIf (cfg.rs3LaunchCommand != null) (lib.hm.dag.entryAfter ["writeBoundary"] ''
      cfg_file="${launcherJson}"
      want=${lib.escapeShellArg (builtins.toJSON cfg.rs3LaunchCommand)}

      # Write $1 (a JSON value) to .rs_launch_command, leaving every other key
      # alone. Creating the file with only this key is fine: Bolt fills in
      # defaults for absent keys, so RS3 is correct on the very first launch.
      boltSetRsLaunchCommand() {
        mkdir -p "$(dirname "$cfg_file")"
        local tmp="$cfg_file.tmp"
        if [ -f "$cfg_file" ]; then
          ${pkgs.jq}/bin/jq --argjson v "$1" '.rs_launch_command = $v' "$cfg_file" > "$tmp"
        else
          ${pkgs.jq}/bin/jq -n --argjson v "$1" '{rs_launch_command: $v}' > "$tmp"
        fi
        mv "$tmp" "$cfg_file"
      }

      boltRsLaunchCommandIs() {
        [ -f "$cfg_file" ] \
          && ${pkgs.jq}/bin/jq -e --argjson v "$1" '.rs_launch_command == $v' "$cfg_file" > /dev/null
      }

      # Without Resizable BAR the NVIDIA driver exposes only a 256 MiB
      # DEVICE_LOCAL|HOST_VISIBLE heap, and that heap is exactly what zink
      # streams its buffer uploads through; once it is exhausted zink spills to
      # non-device-local memory and the RS3 client runs far worse than it would
      # on NVIDIA's native GL driver.  So the override is worth applying only
      # when ReBAR is actually on — which is runtime state, hence a probe here
      # rather than a condition on the option default.
      ${lib.custom.mkResizableBarCheck {}}

      if [[ -v DRY_RUN ]]; then
        echo "would ensure rs_launch_command in $cfg_file"
      elif ${lib.boolToString cfg.requireResizableBar} && ! hasResizableBar; then
        # Never apply without ReBAR, and revert the value if we are the ones
        # who wrote it (e.g. ReBAR was since turned off in firmware).  A
        # command set by hand in Bolt's UI is not ours to touch.
        if boltRsLaunchCommandIs "$want"; then
          boltSetRsLaunchCommand null
          echo "Bolt: Resizable BAR is off — reverted the zink rs_launch_command for RS3"
        else
          echo "Bolt: Resizable BAR is off — not applying the zink rs_launch_command for RS3"
        fi
      elif boltRsLaunchCommandIs "$want"; then
        : # already correct — leave Bolt's file alone so rebuilds are a no-op
      else
        boltSetRsLaunchCommand "$want"
        echo "Bolt: set rs_launch_command in $cfg_file"
      fi

      unset -f boltSetRsLaunchCommand boltRsLaunchCommandIs hasResizableBar
    '');

    home.persistence."/persist".directories = [".runelite"];

    custom.programs.niri.windowRulesConfig = lib.mkIf config.custom.programs.niri.enable ''
      window-rule {
          match app-id=r#"^com\.adamcake\.Bolt$"#
          open-floating true
          open-maximized false
      }

      window-rule {
          match app-id=r#"^RuneLite$"#
          open-maximized true
      }

      window-rule {
          match app-id=r#"^jagex_launcher$"#
          open-maximized true
      }
    '';
  };
}
