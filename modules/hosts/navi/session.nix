# Navi session: greetd/tuigreet + niri.
{pkgs, ...}: {
  programs = {
    niri = {
      enable = true;
      # See niri-wrapped.nix: silences the import-environment deprecation
      # warning printed on the TTY at login.
      package = pkgs.callPackage ./niri-wrapped.nix {};
      useNautilus = false;
    };
    gpu-screen-recorder.enable = true;
  };

  security.pam.services.greetd.enableGnomeKeyring = true;

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd niri-session";
      user = "greeter";
    };
  };

  environment.systemPackages = [pkgs.seahorse];
}
