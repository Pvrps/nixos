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
    javaFormatterConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to an eclipse-formatter.xml file for the Java extension";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode.override {commandLineArgs = "--password-store=\"gnome-libsecret\"";};
      profiles.default = {
        inherit (cfg) extensions;
        userSettings = cfg.userSettings;
      };
    };

    home.file.".config/Code/User/eclipse-formatter.xml" = lib.mkIf (cfg.javaFormatterConfig != null) {
      source = cfg.javaFormatterConfig;
    };
  };
}
