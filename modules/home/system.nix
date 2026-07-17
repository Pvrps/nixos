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
    # Declarative default applications (collected from all modules'
    # xdg.mimeApps.defaultApplications) act as a *baseline* placed at the
    # lower-precedence XDG data location. ~/.config/mimeapps.list is left
    # unmanaged and writable so GUI tools / Steam / xdg-mime can set
    # per-mimetype overrides that persist across rebuilds.
    xdg.mimeApps.enable = true;

    # Stop home-manager from owning ~/.config/mimeapps.list...
    xdg.configFile."mimeapps.list".enable = lib.mkForce false;
    # ...and mirror the generated content to the fallback location instead.
    xdg.dataFile."applications/mimeapps.list".source =
      config.xdg.configFile."mimeapps.list".source;

    gtk.gtk2.force = true;

    # Tell Chromium/Electron apps to use the native Wayland backend.
    home.sessionVariables = lib.mkIf config.custom.system.wayland.enable {
      NIXOS_OZONE_WL = "1";
    };
  };
}
