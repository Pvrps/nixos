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

  options.custom.programs.flatpak = {
      enable = lib.mkEnableOption "Flatpak via nix-flatpak";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of Flatpak packages to install";
      };
  };

  config = lib.mkIf cfg.enable {
    # Make Flatpak-exported apps and icons visible to the session.
    home.sessionVariables.XDG_DATA_DIRS = "$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";

    services.flatpak = {
      enable = true;

      remotes = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
      ];

      update.auto.enable = false;
      uninstallUnmanaged = false;

      inherit (cfg) packages;
    };
  };
}
