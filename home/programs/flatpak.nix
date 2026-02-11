{
  pkgs,
  lib,
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

    packages = [
      "com.obsproject.Studio"
      "com.github.tchx84.Flatseal"
      "org.freedesktop.Platform.Gstreamer.nvenc"
    ];
  };
}
