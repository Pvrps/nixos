# OpenTabletDriver — user-mode tablet driver with udev rules and daemon.
{
  config,
  lib,
  ...
}: let
  cfg = config.custom.opentabletdriver;
in {
  options.custom.opentabletdriver.enable =
    lib.mkEnableOption "OpenTabletDriver (udev rules, daemon, kernel module blacklist)";

  config = lib.mkIf cfg.enable {
    hardware.opentabletdriver = {
      enable = true;
      daemon.enable = true;
    };
  };
}
