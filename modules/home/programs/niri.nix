{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.niri;

  startupLines = lib.concatStringsSep "\n" (map (cmd: "spawn-at-startup ${cmd}") cfg.startupCommands);

  terminalKeybind = lib.optionalString (cfg.defaultTerminal != null)
    ''    Mod+Return { spawn "${cfg.defaultTerminal}"; }'';

  allBinds = lib.concatStringsSep "\n    "
    (lib.optional (terminalKeybind != "") terminalKeybind ++ cfg.keybinds)
    + lib.optionalString (cfg.bindsConfig != "") "\n    ${cfg.bindsConfig}";

  envBlock = lib.optionalString (cfg.xwaylandDisplay != null) ''
    environment {
        DISPLAY "${cfg.xwaylandDisplay}"
    }

  '';
in {
  options.custom.programs.niri = {
    enable = lib.mkEnableOption "Niri Wayland compositor";

    xwaylandDisplay = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Xwayland display socket (e.g. \":11\"). Automatically starts xwayland-satellite when set.";
    };

    defaultTerminal = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Default terminal command. Auto-binds Mod+Return. Use lib.mkDefault to catch conflicts.";
    };

    startupCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Commands to spawn at startup.";
    };

    keybinds = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Keybind lines appended into the auto-generated binds block alongside Mod+Return.";
    };

    inputConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Raw KDL input {} block.";
    };

    outputConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Raw KDL output {} blocks.";
    };

    layoutConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Raw KDL layout {} block.";
    };

    windowRulesConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Raw KDL window-rule {} blocks.";
    };

    layerRulesConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Raw KDL layer-rule {} blocks.";
    };

    bindsConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Keybind lines placed inside the binds {} block. Do not wrap in binds {}. Combined with Mod+Return and module keybinds.";
    };

    gesturesConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Raw KDL gestures {} block.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Raw KDL appended after all sections. For screenshot-path and anything else.";
    };
  };

  config = lib.mkIf cfg.enable {
    custom.system.wayland.enable = true;

    custom.programs.niri.startupCommands = lib.mkIf (cfg.xwaylandDisplay != null) [
      ''"${pkgs.xwayland-satellite}/bin/xwayland-satellite" "${cfg.xwaylandDisplay}"''
    ];

    xdg.configFile."niri/config.kdl".text = ''
      ${envBlock}hotkey-overlay {
          skip-at-startup
      }

      ${startupLines}

      ${cfg.inputConfig}

      prefer-no-csd

      ${cfg.outputConfig}

      ${cfg.layoutConfig}

      ${cfg.windowRulesConfig}

      ${cfg.layerRulesConfig}

      ${lib.optionalString (allBinds != "") ''
      binds {
          ${allBinds}
      }''}

      ${cfg.gesturesConfig}

      ${cfg.extraConfig}
    '';
  };
}
