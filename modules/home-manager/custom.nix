{lib, ...}: {
  options.custom = {
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
    context7 = {
      enable = lib.mkEnableOption "Context7 MCP Server";
      apiKeyPath = lib.mkOption {
        type = lib.types.str;
        description = "Path to the Context7 API key secret";
      };
    };
  };
}
