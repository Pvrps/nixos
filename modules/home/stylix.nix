# Shared stylix home-manager module — imported once for all users via import-tree.
{inputs, ...}: {
  imports = [
    inputs.stylix.homeModules.stylix
  ];
}
