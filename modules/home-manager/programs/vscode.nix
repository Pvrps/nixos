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
      package = pkgs.vscode;
      extensions = cfg.extensions;
      userSettings = cfg.userSettings;
    };
  };
}
