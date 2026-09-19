# Shared stylix home-manager module — imported once for all users via import-tree.
{inputs, ...}: {
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  stylix = {
    # home-manager.useGlobalPkgs = true reuses the system nixpkgs, so any
    # nixpkgs.overlays set from a home-manager module are ignored (and will
    # soon be an error). Stylix's NixOS module disables this automatically,
    # but stylix is only imported on the home-manager side here, so do it
    # explicitly. Only the recolored NixOS logo and the gtksourceview syntax
    # theme are affected; all other stylix theming is file-based.
    overlays.enable = false;

    # Auto-enabled target that still sets the renamed `programs.rofi.font`
    # option; rofi is not used (noctalia is the launcher).
    targets.rofi.enable = false;
  };
}
