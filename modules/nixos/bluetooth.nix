# Bluetooth with convenience-biased settings (8BitDo Pro 2 pairing reliability).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.bluetooth;
in {
  options.custom.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth with controller-friendly settings";
    guiTools = lib.mkEnableOption "Install gnome-bluetooth and blueman GUI tools";
  };

  config = lib.mkIf cfg.enable {
    # These settings are intentionally convenience-biased. Bluetooth pairing for
    # the 8BitDo Pro 2 controller was unreliable without them; revisit later.
    hardware.bluetooth = {
      enable = true;
      settings = {
        General = {
          Experimental = true;
          JustWorksRepairing = "always";
        };
        Policy = {
          AutoEnable = true;
          ReconnectAttempts = 7;
          ReconnectIntervals = "1,2,4,8,16,32,64";
        };
      };
    };

    environment.systemPackages = lib.mkIf cfg.guiTools (with pkgs; [
      gnome-bluetooth
      blueman
    ]);
  };
}
