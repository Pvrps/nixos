{
  pkgs,
  config,
  ...
}: let
  colors = config.lib.stylix.colors.withHashtag;

  pactl = "${pkgs.pulseaudio}/bin/pactl";
  xwayland_satellite = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";

  wait_net = "nm-online -q --timeout=30 || true";
in {
  xdg.configFile."niri/config.kdl".text = ''
    environment {
        DISPLAY ":11"
    }

    hotkey-overlay {
        skip-at-startup
    }

    spawn-at-startup "${xwayland_satellite}" ":11"
    spawn-at-startup "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon" "--start" "--components=secrets"
    spawn-at-startup "noctalia-shell"

    spawn-at-startup "bash" "-c" "for i in {1..20}; do ${pactl} list short sources | grep -q 'rnnoise_source' && { ${pactl} set-default-source rnnoise_source; break; }; sleep 0.5; done"

    spawn-at-startup "bash" "-c" "${wait_net}; steam -system-composer -silent > /dev/null 2>&1"
    spawn-at-startup "bash" "-c" "${wait_net}; discord --start-minimized > /dev/null 2>&1"

    window-rule {
        open-maximized true
    }

    window-rule {
        match app-id=r#"^steam$"# title=r#"^notificationtoasts_\d+_desktop$"#
        open-floating true
        open-maximized false
        open-focused false
        default-floating-position x=10 y=10 relative-to="bottom-right"
        focus-ring { width 0; }
    }

    window-rule {
        match app-id="discord" title="Discord Updater"
        match app-id="discord" title="Checking for updates..."
        open-floating true
        open-maximized false
    }

    input {
        keyboard {
            xkb {

            }
        }
        mouse {
            accel-profile "flat"
            accel-speed 0.15
        }
        touchpad {
            tap
            natural-scroll
        }
    }

    output "DP-2" {
        mode "2560x1440@144"
        position x=0 y=0
        scale 1.5
        variable-refresh-rate on-demand=true
        focus-at-startup
    }

    output "DP-4" {
        mode "2560x1440@144"
        position x=1707 y=0
        scale 1.5
        variable-refresh-rate on-demand=true
    }

    layout {
        gaps 8
        default-column-width { proportion 0.5; }
        focus-ring {
            width 2
            active-color "${colors.base0D}"
            inactive-color "${colors.base03}"
        }
    }

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/%Y-%m-%d-%H-%M-%S.png"
    binds {
        Mod+Shift+S { spawn "screenshot-tool"; }
        Mod+Shift+C { spawn "recording-tool"; }

        Mod+Return { spawn "foot"; }
        Mod+D { spawn "noctalia-shell" "ipc" "call" "launcher" "toggle"; }
        Mod+C { spawn "noctalia-shell" "ipc" "call" "controlCenter" "toggle"; }

        Mod+Q { close-window; }
        Mod+Shift+Grave { quit; }
        Mod+Tab { toggle-overview; }

        Mod+Left  { focus-column-or-monitor-left; }
        Mod+Right { focus-column-or-monitor-right; }
        Mod+Up    { focus-workspace-up; }
        Mod+Down  { focus-workspace-down; }
        Mod+Z     { toggle-window-floating; }
        Mod+Ctrl+Left  { focus-monitor-left; }
        Mod+Ctrl+Right { focus-monitor-right; }

        Mod+Shift+Left  { move-column-left-or-to-monitor-left; }
        Mod+Shift+Right { move-column-right-or-to-monitor-right; }
        Mod+Shift+Up    { move-column-to-workspace-up; }
        Mod+Shift+Down  { move-column-to-workspace-down; }

        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
    }

    gestures {
        hot-corners {
            off
        }
    }

  '';
}
