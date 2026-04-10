{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.gnomeKeyring;
in {
  options.custom.programs.gnomeKeyring.enable =
    lib.mkEnableOption "GNOME Keyring secrets daemon";

  config = lib.mkIf cfg.enable {
    custom.programs.niri.startupCommands = [
      ''"${pkgs.gnome-keyring}/bin/gnome-keyring-daemon" "--start" "--components=secrets"''
    ];
  };
}
