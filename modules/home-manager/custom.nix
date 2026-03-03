{lib, ...}: {
  options.custom = {
    system = {
      wayland = {
        enable = lib.mkEnableOption "Wayland compositor active";
      };
    };
    git = {
      userName = lib.mkOption {
        type = lib.types.str;
        default = "Anonymous";
        description = "Git user name";
      };
      userEmail = lib.mkOption {
        type = lib.types.str;
        default = "anonymous@localhost";
        description = "Git user email";
      };
    };
    easyeffects = {
      preset = lib.mkOption {
        type = lib.types.str;
        default = "blue_yeti";
        description = "EasyEffects preset name";
      };
      presetSource = lib.mkOption {
        type = lib.types.path;
        description = "Path to the EasyEffects preset JSON file";
      };
    };
    niri = {
      startupCommands = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of full shell commands to run on Niri startup";
      };
      xwaylandDisplay = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Xwayland display socket (e.g. \":11\"). Requires xwayland-satellite in startupCommands. When set, adds DISPLAY to niri's environment block.";
      };
      outputs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of niri output {} KDL blocks (one string per monitor)";
      };
      defaultTerminal = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Command for the default terminal emulator.
          When set, niri binds Mod+Return to spawn this command.
          Only one terminal module should set this at a time (use lib.mkDefault
          to get a conflict error if two modules both claim the default terminal).
        '';
      };
      keybinds = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Extra keybind lines to include in the niri binds block";
      };
      windowRules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Extra window-rule blocks to include in the niri config";
      };
      layerRules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Extra layer-rule blocks to include in the niri config";
      };
    };
    ssh = {
      githubKeyPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path to the SSH key for github.com";
      };
    };
    zen = {
      profiles = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Zen browser profiles configuration";
      };
      extensionSettings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Zen browser extension settings";
      };
    };
    flatpak = {
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of Flatpak packages to install";
      };
    };
    discord = {
      plugins = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Nixcord plugins configuration";
      };
    };
    opencode = {
      context7 = {
        enable = lib.mkEnableOption "Context7 MCP Server";
        apiKeyPath = lib.mkOption {
          type = lib.types.str;
          description = "Path to the Context7 API key secret";
        };
      };
    };
  };
}
