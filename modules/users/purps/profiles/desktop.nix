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

        inputConfig = ''
          input {
              keyboard {
                  xkb {

                  }
              }
              mouse {
                  accel-profile "flat"
                  accel-speed 0.15
              }
              touchpad {
                  tap
                  natural-scroll
              }
          }
        '';

        outputConfig = ''
          output "DP-1" {
              mode "2560x1440@144"
              position x=0 y=0
              scale 1.5
              variable-refresh-rate on-demand=true
              focus-at-startup
          }

          output "DP-3" {
              mode "2560x1440@144"
              position x=1707 y=0
              scale 1.5
              variable-refresh-rate on-demand=true
          }

          output "HDMI-A-3" {
              off
          }
        '';

        layoutConfig = ''
          layout {
              gaps 6
              default-column-width { proportion 0.5; }
              focus-ring {
                  off
              }
              border {
                  off
              }
              struts {
                  left -6
                  right -6
              }
          }
        '';

        windowRulesConfig = ''
          window-rule {
              open-maximized true
          }

          window-rule {
              geometry-corner-radius 0
              clip-to-geometry true
          }
        '';

        bindsConfig = ''
          Mod+Q { close-window; }
          Mod+Shift+Grave { quit; }
          Mod+Tab { toggle-overview; }

          Mod+Left  { focus-column-or-monitor-left; }
          Mod+Right { focus-column-or-monitor-right; }
          Mod+Up    { focus-window-or-workspace-up; }
          Mod+Down  { focus-window-or-workspace-down; }
          Mod+Z     { toggle-window-floating; }
          Mod+Ctrl+Left  { focus-monitor-left; }
          Mod+Ctrl+Right { focus-monitor-right; }

          Mod+Shift+Left  { move-column-left-or-to-monitor-left; }
          Mod+Shift+Right { move-column-right-or-to-monitor-right; }
          Mod+Shift+Up    { move-window-up-or-to-workspace-up; }
          Mod+Shift+Down  { move-window-down-or-to-workspace-down; }
          Mod+Ctrl+Shift+Left  { set-column-width "-5%"; }
          Mod+Ctrl+Shift+Right { set-column-width "+5%"; }
          Mod+Ctrl+Shift+Up    { set-window-height "-5%"; }
          Mod+Ctrl+Shift+Down  { set-window-height "+5%"; }
          Mod+Shift+Z { switch-focus-between-floating-and-tiling; }
          Mod+F { maximize-column; }
          Mod+Shift+F { fullscreen-window; }
        '';

        gesturesConfig = ''
          gestures {
              hot-corners {
                  off
              }
          }
        '';

        extraConfig = ''
          screenshot-path "~/Pictures/Screenshots/%Y-%m-%d-%H-%M-%S.png"
        '';
      };
      foot = {
        enable = true;
        pad = "8x8";
      };
      ghostty.enable = false;
      termfilepickers.enable = false;
      gnomeKeyring.enable = true;
    };
  };
}
