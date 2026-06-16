{pkgs, ...}: let
  sddm-astronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "pixel_sakura_static";
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
