{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.rustdesk;
in {
  options.custom.programs.rustdesk.enable = lib.mkEnableOption "RustDesk remote desktop";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.rustdesk-flutter
    ];
  };
}
