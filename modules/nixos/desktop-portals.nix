# XDG desktop portals, selected by backend:
#   kde   - Plasma hosts (ciela)
#   gnome - wlroots/niri hosts (navi): GTK portal default, GNOME portal for
#           ScreenCast/Screenshot/RemoteDesktop
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.desktop.portals;
in {
  options.custom.desktop.portals.backend = lib.mkOption {
    type = lib.types.nullOr (lib.types.enum ["kde" "gnome"]);
    default = null;
    description = "XDG desktop portal backend set. Null leaves portals to the desktop environment.";
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.backend == "kde") {
      xdg.portal = {
        enable = true;
        extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
        config.common.default = ["kde"];
      };
    })

    (lib.mkIf (cfg.backend == "gnome") {
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [xdg-desktop-portal-gnome xdg-desktop-portal-gtk];
        config.common = {
          default = ["gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
          "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
          "org.freedesktop.impl.portal.RemoteDesktop" = ["gnome"];
        };
      };
    })
  ];
}
