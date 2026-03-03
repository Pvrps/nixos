{
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.niri;
  colors = config.lib.stylix.colors.withHashtag;

  startupLines = builtins.concatStringsSep "\n    " (map (cmd: ''spawn-at-startup ${cmd}'') config.custom.niri.startupCommands);
  extraKeybindLines = builtins.concatStringsSep "\n          " config.custom.niri.keybinds;
  extraWindowRules = builtins.concatStringsSep "\n\n" config.custom.niri.windowRules;
  extraLayerRules = builtins.concatStringsSep "\n\n" config.custom.niri.layerRules;
in {
  options.custom.programs.niri.enable = lib.mkEnableOption "Niri Wayland compositor";

  config = lib.mkIf cfg.enable {
    custom.system.wayland.enable = true;

    xdg.configFile."niri/config.kdl".text = ''
      environment {
          DISPLAY ":11"
      }

      hotkey-overlay {
          skip-at-startup
      }

      ${startupLines}

      window-rule {
          open-maximized true
      }

      ${extraWindowRules}

      ${extraLayerRules}

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

      output "DP-1" {
          mode "2560x1440@144"
          position x=0 y=0
          scale 1.5
          variable-refresh-rate on-demand=true
          focus-at-startup
      }

      output "DP-3" {
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
          ${extraKeybindLines}

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
  };
}
