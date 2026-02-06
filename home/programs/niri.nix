{
  pkgs,
  config,
  ...
}: let
  colors = config.lib.stylix.colors.withHashtag;
in {
  xdg.configFile."niri/config.kdl".text = ''
    environment {
        DISPLAY ":0"
    }

    hotkey-overlay {
        skip-at-startup
    }

    spawn-at-startup "xwayland-satellite" ":0"
    spawn-at-startup "noctalia-shell"

    window-rule {
        open-maximized true
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
        variable-refresh-rate
        focus-at-startup
    }

    output "DP-4" {
        mode "2560x1440@144"
        position x=1707 y=0
        variable-refresh-rate
        scale 1.5
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

    binds {
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
        Mod+Ctrl+Left  { focus-monitor-left; }
        Mod+Ctrl+Right { focus-monitor-right; }

        Mod+Shift+Left  { move-column-left-or-to-monitor-left; }
        Mod+Shift+Right { move-column-right-or-to-monitor-right; }
        Mod+Shift+Up    { move-column-to-workspace-up; }
        Mod+Shift+Down  { move-column-to-workspace-down; }

        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
    }
  '';
}
