# System-level home-manager options shared across all users.
# Declaring wayland.enable here (not in niri.nix) means any future
# compositor (Sway, Hyprland, etc.) can set it without conflict.
{lib, ...}: {
  options.custom.system = {
    wayland.enable = lib.mkEnableOption "Wayland compositor active";
  };
}
