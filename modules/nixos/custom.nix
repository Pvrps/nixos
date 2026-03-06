{
  lib,
  pkgs,
  ...
}: {
  options.custom = {
    desktop = {
      extraPortals = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [xdg-desktop-portal-gnome xdg-desktop-portal-gtk];
        description = "Extra XDG portals to install system-wide.";
      };
    };
  };
}
