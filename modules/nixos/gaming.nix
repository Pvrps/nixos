{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.gaming;
in {
  options.custom.gaming = {
    enable = lib.mkEnableOption "gaming support";
    steamRemotePlay.openFirewall = lib.mkEnableOption "Steam Remote Play firewall ports";
    steamDedicatedServer.openFirewall = lib.mkEnableOption "Steam dedicated server firewall ports";
  };

  config = lib.mkIf cfg.enable {
    # uinput is required for Steam Input to create virtual controller devices.
    # The input group is powerful; keep this only for trusted local users.
    boot.kernelModules = ["uinput"];

    # uinput must be writable by the input group for Steam Input to create virtual devices.
    services.udev.extraRules = ''
      KERNEL=="uinput", GROUP="input", MODE="0660"
    '';

    # xpadneo: advanced Xbox/8BitDo BT driver, fixes GET_REPORT timeouts and ERTM issues.
    hardware.xpadneo.enable = true;

    programs = {
      steam = {
        enable = true;
        gamescopeSession.enable = true;
        remotePlay.openFirewall = cfg.steamRemotePlay.openFirewall;
        dedicatedServer.openFirewall = cfg.steamDedicatedServer.openFirewall;
      };
      gamemode.enable = true;
      gamescope.enable = true;
    };
  };
}
