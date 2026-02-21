{
  lib,
  pkgs,
  ...
}: {
  options.custom = {
    desktop = {
      extraPortals = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [pkgs.xdg-desktop-portal-gnome];
        description = "Extra XDG portals to install system-wide.";
      };
    };
  };
}
