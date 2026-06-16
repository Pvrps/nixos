{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      trash-cli
    ];

    persistence."/persist" = {
      hideMounts = true;
      directories = [
        ".local"
        ".config"
        ".var"
        ".gnupg"
        ".pki"
      ];
    };

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      POWERDEVIL_NO_DDCUTIL = "1";
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
    gtk3.extraConfig = {
      gtk-show-hidden = true;
    };
    gtk4.extraConfig = {
      gtk-show-hidden = true;
    };
  };

  # Required so that Wayland-only scripts (screenshot, recording, ocr, edit)
  # pass their assertions. KDE Plasma runs on Wayland via SDDM.
  custom.system.wayland.enable = true;

  custom = {
    programs = {
      gnomeKeyring.enable = true;
    };
  };
}
