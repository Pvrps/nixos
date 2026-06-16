# Shared desktop profile. The base covers cross-DE scaffolding (GTK/dconf file
# chooser, trash-cli, Wayland session vars, gnome-keyring, common persistence).
# `niri` and `kde` sub-options select the compositor/DE-specific stack; the
# machine-specific niri layout (outputs/inputs/binds) stays in the user's host
# entry file via custom.programs.niri.*.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.profiles.desktop;
in {
  options.custom.profiles.desktop = {
    enable = lib.mkEnableOption "Desktop base (GTK/dconf, session vars, keyring)";
    niri = lib.mkEnableOption "niri compositor stack (niri, foot, noctalia, capture scripts)";
    kde = lib.mkEnableOption "KDE Plasma desktop adjustments";
    extraPersistence = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra home.persistence directories beyond the common set.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home = {
        packages = [pkgs.trash-cli];

        persistence."/persist" = {
          hideMounts = true;
          directories =
            [
              ".local"
              ".config"
              ".var"
              ".gnupg"
              ".pki"
            ]
            ++ cfg.extraPersistence;
        };

        sessionVariables = {
          NIXOS_OZONE_WL = "1";
          XDG_DATA_DIRS = "$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
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

      custom.programs.gnomeKeyring.enable = true;
    }

    # niri compositor stack. The detailed per-machine niri layout
    # (output/input/binds) is supplied by the user's host entry file.
    (lib.mkIf cfg.niri {
      custom = {
        scripts = {
          capture = {
            screenshot.enable = true;
            recording.enable = true;
            edit.enable = true;
          };
          hist-clean.enable = true;
        };

        programs = {
          noctalia.enable = true;
          niri.enable = true;
          foot = {
            enable = true;
            pad = "8x8";
          };
          ghostty.enable = false;
          termfilepickers.enable = false;
        };
      };
    })

    # KDE Plasma. Plasma runs on Wayland via SDDM, so the Wayland flag is set so
    # Wayland-only scripts pass their assertions.
    (lib.mkIf cfg.kde {
      custom.system.wayland.enable = true;
      home.sessionVariables.POWERDEVIL_NO_DDCUTIL = "1";
    })
  ]);
}
