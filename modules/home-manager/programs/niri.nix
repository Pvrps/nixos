{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.niri;
  colors = config.lib.stylix.colors.withHashtag;
  niriCfg = config.custom.niri;

  # Each list is joined so all entries render at the correct column in the KDL.
  # Startup commands are top-level nodes separated by a single newline.
  startupLines = lib.concatStringsSep "\n" (map (cmd: "spawn-at-startup ${cmd}") niriCfg.startupCommands);
  # Generate the Mod+Return terminal keybind only when a default terminal is configured.
  terminalKeybind =
    lib.optionalString (niriCfg.defaultTerminal != null)
    ''Mod+Return { spawn "${niriCfg.defaultTerminal}"; }'';
  # Keybinds live inside binds {}; after template stripping they sit at col 4,
  # so subsequent entries use "\n    " to maintain the 4-space indentation.
  # terminalKeybind is prepended (with separator) only when non-empty.
  allKeybinds =
    lib.optional (terminalKeybind != "") terminalKeybind
    ++ niriCfg.keybinds;
  keybindLines = lib.concatStringsSep "\n    " allKeybinds;
  # Blocks are top-level KDL nodes separated by blank lines.
  windowRuleBlocks = lib.concatStringsSep "\n\n" niriCfg.windowRules;
  layerRuleBlocks = lib.concatStringsSep "\n\n" niriCfg.layerRules;
  outputBlocks = lib.concatStringsSep "\n\n" niriCfg.outputs;

  # Include the DISPLAY environment block only when xwaylandDisplay is set.
  # xwayland-satellite is automatically added to startupCommands when xwaylandDisplay is set.
  # The trailing newline provides spacing before the next top-level block.
  envBlock = lib.optionalString (niriCfg.xwaylandDisplay != null) ''
    environment {
        DISPLAY "${niriCfg.xwaylandDisplay}"
    }

  '';
in {
  options.custom.programs.niri.enable = lib.mkEnableOption "Niri Wayland compositor";

  config = lib.mkIf cfg.enable {
    custom.system.wayland.enable = true;

    custom.niri.startupCommands = lib.mkIf (niriCfg.xwaylandDisplay != null) [
      ''"${pkgs.xwayland-satellite}/bin/xwayland-satellite" "${niriCfg.xwaylandDisplay}"''
    ];

    xdg.configFile."niri/config.kdl".text = ''
      ${envBlock}hotkey-overlay {
          skip-at-startup
      }

      ${startupLines}

      window-rule {
          open-maximized true
      }

      ${windowRuleBlocks}

      ${layerRuleBlocks}

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

      ${outputBlocks}

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
          ${keybindLines}

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
