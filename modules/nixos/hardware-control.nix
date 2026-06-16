# OpenRGB + a hardware-control group, with optional liquidctl udev access.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.hardwareControl;
in {
  options.custom.hardwareControl = {
    enable = lib.mkEnableOption "OpenRGB and the hardware-control group";
    motherboard = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["amd" "intel"]);
      default = "amd";
      description = "OpenRGB SMBus motherboard vendor.";
    };
    liquidctl = lib.mkEnableOption "liquidctl udev rules (NZXT Kraken via hardware-control group)";
  };

  config = lib.mkIf cfg.enable {
    services.hardware.openrgb = {
      enable = true;
      inherit (cfg) motherboard;
    };

    users.groups.hardware-control = {};

    services.udev.packages = lib.mkIf cfg.liquidctl [pkgs.liquidctl];

    # liquidctl's uaccess tag requires logind ACL at plug-in time which doesn't
    # fire for always-connected devices. Grant access only to trusted hardware
    # control users rather than every normal user.
    services.udev.extraRules = lib.mkIf cfg.liquidctl ''
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="1e71", ATTRS{idProduct}=="300c", GROUP="hardware-control", MODE="0660"
    '';
  };
}
