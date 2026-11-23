{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.custom.programs.nuvio;
in {
  options.custom.programs.nuvio.enable = lib.mkEnableOption "Nuvio media streaming app";

  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.callPackage ./nuvio/_package.nix {})
    ];
  };
}
