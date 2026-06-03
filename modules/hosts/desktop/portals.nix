{
  pkgs,
  lib,
  config,
  ...
}: {
  options.custom.desktop.extraPortals = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = with pkgs; [xdg-desktop-portal-gnome xdg-desktop-portal-gtk];
    description = "Extra XDG portals to install system-wide.";
  };

  config.xdg.portal = {
    enable = true;
    inherit (config.custom.desktop) extraPortals;
    config = {
      common = {
        default = ["gtk"];
        "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
        "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
        "org.freedesktop.impl.portal.RemoteDesktop" = ["gnome"];
      };
    };
  };
}
