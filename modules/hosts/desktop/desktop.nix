{
  pkgs,
  lib,
  config,
  ...
}: {
  options.custom.desktop = {
    extraPortals = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = with pkgs; [xdg-desktop-portal-gnome xdg-desktop-portal-gtk];
      description = "Extra XDG portals to install system-wide.";
    };
  };

  config = {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.settings.main.experimental = true;

    # Geist must be a system-level font so Flatpak exposes it via /run/host/fonts.
    # Home-manager fonts live in the Nix store and aren't reachable inside the sandbox.
    fonts.packages = [pkgs.geist-font];

    programs = {
      niri.enable = true;
    };

    security = {
      pam.services.greetd.enableGnomeKeyring = true;
      rtkit.enable = true;
    };

    services = {
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;

        wireplumber = {
          enable = true;
          extraConfig = {
            "10-disable-suspension" = {
              "monitor.alsa.rules" = [
                {
                  matches = [
                    {"node.name" = "~alsa_input.*";}
                    {"node.name" = "~alsa_output.*";}
                  ];
                  actions = {
                    update-props = {
                      "session.suspend-timeout-seconds" = 0;
                    };
                  };
                }
              ];
            };
          };
        };

        extraConfig.pipewire = {
          "92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = 1024;
              "default.clock.min-quantum" = 1024;
              "default.clock.max-quantum" = 2048;
            };
          };
          "93-virtual-cable" = {
            "context.objects" = [
              {
                factory = "adapter";
                args = {
                  "factory.name" = "support.null-audio-sink";
                  "node.name" = "virtual-audio-sink-1";
                  "node.description" = "Virtual Cable 1";
                  "media.class" = "Audio/Sink";
                  "audio.position" = "FL,FR";
                };
              }
            ];
          };
        };
      };
      greetd = {
        enable = true;
        settings.default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd niri-session";
          user = "greeter";
        };
      };
      upower.enable = true;
      gnome.gnome-keyring.enable = true;
      flatpak.enable = true;
    };

    xdg.portal = {
      enable = true;
      inherit (config.custom.desktop) extraPortals;
      config = {
        common = {
          default = ["gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
          "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
          "org.freedesktop.impl.portal.RemoteDesktop" = ["gnome"];
        };
      };
    };

    environment.systemPackages = with pkgs; [
      seahorse
      pkgs.gnome-bluetooth
      pkgs.blueman
      pkgs.nix-your-shell
    ];
  };
}
