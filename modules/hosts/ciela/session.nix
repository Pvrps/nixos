# Ciela session: SDDM (astronaut theme) + Plasma 6 on Wayland.
{pkgs, ...}: let
  sddm-astronaut = pkgs.sddm-astronaut.override {
    # Available themes: astronaut, black_hole, cyberpunk, hyprland_kath,
    # jake_the_dog, japanese_aesthetic, pixel_sakura, pixel_sakura_static,
    # post-apocalyptic_hacker, purple_leaves
    embeddedTheme = "hyprland_kath";
  };
in {
  services = {
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      settings.Users.HideUsers = "purps";
      theme = "sddm-astronaut-theme";
      extraPackages = with pkgs.kdePackages; [
        qtmultimedia
        qtvirtualkeyboard
      ];
    };
    desktopManager.plasma6.enable = true;

    # Fix the "log out, then can't log back in for several tries" race.
    # On logout, plasma's `systemd --user` manager (user@1000) takes ~20s to
    # tear down (kwin, plasmashell, baloo...). logind keeps that manager alive
    # for UserStopDelaySec (default 10s) after the last session ends, so a
    # quick re-login lands in the *same* manager while its plasma targets still
    # have a queued `stop` job. startplasma-wayland's `start` then collides:
    # "Requested transaction contradicts existing jobs ... is destructive",
    # the session aborts, and SDDM bounces back to the greeter.
    # Setting this to 0 terminates user@1000 immediately on logout, so each
    # login gets a clean manager with no in-flight stop jobs to collide with.
    logind.settings.Login.UserStopDelaySec = 0;
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    discover
    elisa
    khelpcenter
    kinfocenter
    print-manager
    kmenuedit
    qrca
  ];

  documentation.nixos.enable = false;

  security.pam.services.sddm.enableGnomeKeyring = true;

  environment.systemPackages = [sddm-astronaut];
}
