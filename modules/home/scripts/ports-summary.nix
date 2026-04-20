{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.scripts.ports-summary;

  ports-summary = pkgs.writeShellScriptBin "ports-summary" ''
    echo "TODO"
  '';
in {
  options.custom.scripts.ports-summary.enable = lib.mkEnableOption "ports-summary open port viewer";

  config = lib.mkIf cfg.enable {
    home.packages = [ports-summary];
  };
}
