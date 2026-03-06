{
  pkgs,
  config,
  ...
}: {
  hardware.bluetooth.enable = true;

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

      extraConfig.pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 512;
          "default.clock.min-quantum" = 256;
          "default.clock.max-quantum" = 2048;
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
  ];
}
