{
  pkgs,
  config,
  ...
}: {
  hardware.bluetooth.enable = true;

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
    extraPortals = config.custom.desktop.extraPortals;
  };

  environment.systemPackages = with pkgs; [
    seahorse
  ];
}
