{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.java;
in {
  options.custom.programs.java.enable = lib.mkEnableOption "Java development environment";

  config = lib.mkIf cfg.enable {
    programs.java = {
      enable = true;
      package = pkgs.zulu21;
    };

    home.packages = with pkgs; [
      # Java 8 alias
      (writeShellScriptBin "java8" ''
        exec "${zulu8}/bin/java" "$@"
      '')
      # Java 11 alias
      (writeShellScriptBin "java11" ''
        exec "${zulu11}/bin/java" "$@"
      '')
      # Java 17 alias
      (writeShellScriptBin "java17" ''
        exec "${zulu17}/bin/java" "$@"
      '')
      # Java 21 alias (explicit)
      (writeShellScriptBin "java21" ''
        exec "${zulu21}/bin/java" "$@"
      '')
    ];
  };
}
