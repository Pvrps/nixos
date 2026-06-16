{pkgs, ...}: {
  fonts.packages = [pkgs.geist-font];

  services = {
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      settings.Users.HideUsers = "purps";
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
  ];
}
