# System-level home-manager options shared across all users.
# Declaring wayland.enable here (not in niri.nix) means any future
# compositor (Sway, Hyprland, etc.) can set it without conflict.
{
  lib,
  config,
  ...
}: {
  options.custom.system = {
    wayland.enable = lib.mkEnableOption "Wayland compositor active";
  };

  config = {
    xdg.mimeApps.enable = true;

    # Tell Chromium/Electron apps to use the native Wayland backend.
    home.sessionVariables = lib.mkIf config.custom.system.wayland.enable {
      NIXOS_OZONE_WL = "1";
    };
  };
}
