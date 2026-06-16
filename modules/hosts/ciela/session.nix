{pkgs, ...}: let
  sddm-astronaut = pkgs.sddm-astronaut.override {
    # Available themes: astronaut, black_hole, cyberpunk, hyprland_kath,
    # jake_the_dog, japanese_aesthetic, pixel_sakura, pixel_sakura_static,
    # post-apocalyptic_hacker, purple_leaves
    embeddedTheme = "hyprland_kath";
  };
in {
  fonts.packages = [pkgs.geist-font];

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
    upower.enable = true;
    gnome.gnome-keyring.enable = true;
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

  environment.systemPackages = with pkgs; [
    nix-your-shell
    sddm-astronaut
  ];
}
