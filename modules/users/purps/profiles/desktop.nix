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
        ".ssh"
        ".gnupg"
        ".claude"
        ".steam"
        ".vscode"
        ".putty"
        ".pki"
        ".runelite"
        ".cache/nvidia"
        ".cache/noctalia"
        ".cache/mesa_shader_cache"
        ".cache/radv_builtin_shaders"
        "Downloads"
        "Pictures"
        "Videos"
        "Development"
        "Documents"
      ];
      files = [
        ".claude.json"
      ];
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
    gtk3.extraConfig = {
      gtk-show-hidden = true;
    };
    gtk4.extraConfig = {
      gtk-show-hidden = true;
    };
  };

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
      noctalia = {
        enable = true;
        primaryMonitor = "DP-1";
      };
      niri = {
        enable = true;
        xwaylandDisplay = ":11";
        cornerRadius = 0;
        outputs = [
          ''            output "DP-1" {
                            mode "2560x1440@144"
                            position x=0 y=0
                            scale 1.5
                            variable-refresh-rate on-demand=true
                            focus-at-startup
                        }''
          ''            output "DP-3" {
                            mode "2560x1440@144"
                            position x=1707 y=0
                            scale 1.5
                            variable-refresh-rate on-demand=true
                        }''
          ''            output "HDMI-A-3" {
                            off
                        }''
        ];
      };
      foot.enable = true;
      ghostty.enable = false;
      termfilepickers.enable = false;
      gnomeKeyring.enable = true;
    };
  };
}
