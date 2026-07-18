# Shared desktop-user baseline for the gaming workstations (purps@navi,
# inori@ciela). Only cross-cutting glue lives here — which *programs* a user
# runs stays in their own file. Everything here merges with per-user additions.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.profiles.desktop;
in {
  options.custom.profiles.desktop.enable =
    lib.mkEnableOption "desktop user baseline (persistence, gtk/dconf defaults, common tools)";

  config = lib.mkIf cfg.enable {
    home = {
      packages = [pkgs.trash-cli];

      persistence."/persist" = {
        hideMounts = true;
        directories = [
          ".local"
          ".config"
          ".var"
          ".gnupg"
          ".pki"
          "Downloads"
          "Pictures"
          "Videos"
          "Documents"
          # GPU shader caches — avoid recompiling shaders every boot.
          ".cache/nvidia"
          ".cache/mesa_shader_cache"
          ".cache/radv_builtin_shaders"
        ];
      };
    };

    dconf.settings = {
      "org/gtk/settings/file-chooser" = {
        show-hidden = true;
        sort-directories-first = true;
      };
      "org/gtk/gtk4/settings/file-chooser" = {
        show-hidden = true;
      };
    };

    gtk = {
      enable = true;
      gtk3.extraConfig.gtk-show-hidden = true;
      gtk4.extraConfig.gtk-show-hidden = true;
    };
  };
}
