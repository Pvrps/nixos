# OpenTabletDriver — user-mode tablet driver with udev rules and daemon.
#
# NixOS's hardware.opentabletdriver blacklists the `wacom` kernel module, but
# `hid_generic` still claims Wacom tablets and creates competing input devices.
# This causes draggy/duplicated input because both the kernel's raw HID device
# and OTD's virtual tablet send pointer events to the compositor.
#
# The udev rule below marks Wacom HID input devices with LIBINPUT_IGNORE_DEVICE
# so libinput (and thus the compositor) only sees OTD's virtual tablet. OTD
# reads the tablet directly via hidraw, bypassing the kernel input layer.
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

    # Prevent libinput from creating a pointer device for the kernel's raw
    # Wacom HID interface. OTD reads via hidraw and outputs through its own
    # virtual tablet — the kernel input device only causes interference.
    services.udev.extraRules = ''
      SUBSYSTEM=="input", ATTRS{idVendor}=="056a", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    '';
  };
}
