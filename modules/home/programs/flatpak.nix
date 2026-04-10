{
  lib,
  config,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.custom.programs.flatpak;
in {
  imports = [
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  options.custom = {
    programs.flatpak = {
      enable = lib.mkEnableOption "Flatpak via nix-flatpak";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of Flatpak packages to install";
      };
    };
  };

  config = lib.mkIf cfg.enable {
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

      inherit (cfg) packages;
    };
  };
}
