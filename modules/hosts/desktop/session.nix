{
  pkgs,
  config,
  ...
}: {
  # Geist must be a system-level font so Flatpak exposes it via /run/host/fonts.
  # Home-manager fonts live in the Nix store and aren't reachable inside the sandbox.
  fonts.packages = [pkgs.geist-font];

  programs = {
    niri = {
      enable = true;
      useNautilus = !config.home-manager.users.purps.custom.programs.termfilepickers.enable;
    };
    gpu-screen-recorder.enable = true;
  };

  security.pam.services.greetd.enableGnomeKeyring = true;

  services = {
    greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd niri-session";
        user = "greeter";
      };
    };
    upower.enable = true;
    gnome.gnome-keyring.enable = true;
  };

  environment.systemPackages = with pkgs; [
    seahorse
    nix-your-shell
  ];
}
