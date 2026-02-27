{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
      {
        name = "flathub-beta";
        location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      }
    ];

    update.auto.enable = false;
    uninstallUnmanaged = false;

    inherit (config.custom.flatpak) packages;
  };
}
