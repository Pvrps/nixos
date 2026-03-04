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
    home.packages = [pkgs.gnome-keyring];

    custom.niri.startupCommands = [
      ''"${pkgs.gnome-keyring}/bin/gnome-keyring-daemon" "--start" "--components=secrets"''
    ];
  };
}
