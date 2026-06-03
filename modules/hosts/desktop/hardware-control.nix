{pkgs, ...}: {
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };

  users.groups.hardware-control = {};

  services.udev.packages = [pkgs.liquidctl];

  # liquidctl's uaccess tag requires logind ACL at plug-in time which doesn't
  # fire for always-connected devices. Grant access only to trusted hardware
  # control users rather than every normal user.
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="1e71", ATTRS{idProduct}=="300c", GROUP="hardware-control", MODE="0660"
  '';
}
