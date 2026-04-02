{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.vscode;
in {
  options.custom.programs.vscode = {
    enable = lib.mkEnableOption "VSCode editor";
    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "List of VSCode extensions to install.";
    };
    userSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "VSCode user settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode.override { commandLineArgs = "--password-store=\"gnome-libsecret\""; };
      extensions = cfg.extensions;
    };

    home.activation.vscodeMutableSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
      VSCODE_SETTINGS_DIR="''${HOME}/.config/Code/User"
      VSCODE_SETTINGS_FILE="''${VSCODE_SETTINGS_DIR}/settings.json"
      
      mkdir -p "''${VSCODE_SETTINGS_DIR}"
      
      # If the file exists and is a symlink (from old config), remove it
      if [ -L "''${VSCODE_SETTINGS_FILE}" ]; then
        rm "''${VSCODE_SETTINGS_FILE}"
      fi
      
      if [ ! -f "''${VSCODE_SETTINGS_FILE}" ]; then
        echo "{}" > "''${VSCODE_SETTINGS_FILE}"
      fi
      
      # Use jq to merge new settings with existing ones, prioritizing our managed ones
      # Note: We write to a temp file first since jq can't read and write to the same file simultaneously
      TEMP_SETTINGS=$(mktemp)
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "''${VSCODE_SETTINGS_FILE}" <(echo '${builtins.toJSON cfg.userSettings}') > "''${TEMP_SETTINGS}"
      mv "''${TEMP_SETTINGS}" "''${VSCODE_SETTINGS_FILE}"
      chmod 644 "''${VSCODE_SETTINGS_FILE}"
    '';
  };
}
