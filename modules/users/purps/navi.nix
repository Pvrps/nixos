{osConfig, ...}: {
  imports = [
    ./general.nix
    ./stylix.nix
  ];

  custom.profiles = {
    desktop = {
      enable = true;
      niri = true;
      extraPersistence = [".ssh"];
    };
    browsers.enable = true;
    dev = {
      enable = true;
      context7ApiKeyPath = osConfig.sops.secrets."context7-api-key".path;
    };
    gaming = {
      enable = true;
      discordRpcNoctalia = true;
      steamNiriLauncher = true;
    };
    media = {
      enable = true;
      extras = true;
      rustdeskServerFile = osConfig.sops.secrets."rustdesk-server".path;
      rustdeskKeyFile = osConfig.sops.secrets."rustdesk-key".path;
    };
    hardware = {
      enable = true;
      username = "purps";
      liquidctl = true;
      liquidctlLcdImage = ./assets/master-sword.gif;
    };
  };

  # navi-specific niri layout (outputs/inputs/binds). Machine-specific, so it
  # lives in the host entry rather than the shared desktop profile.
  custom.programs.noctalia.primaryMonitor = "DP-1";
  custom.programs.niri = {
    xwaylandDisplay = ":11";

    inputConfig = ''
      input {
          keyboard {
              xkb {

              }
          }
          mouse {
              accel-profile "flat"
              accel-speed 0
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

  home.persistence."/persist" = {
    directories = [
      ".putty"
      "Downloads"
      "Pictures"
      "Videos"
      "Development"
      "Documents"
    ];
  };

  custom.scripts.capture.ocr.enable = true;

  custom.programs.ssh = {
    extraHosts = {
      "windwaker" = {
        HostName = "10.0.10.16";
        User = "purps";
        IdentityFile = osConfig.sops.secrets."windwaker-purps-key".path;
      };
      "ciela" = {
        HostName = "10.0.0.232";
        User = "purps";
        IdentityFile = osConfig.sops.secrets."ciela-purps-key".path;
      };
    };
  };
}
