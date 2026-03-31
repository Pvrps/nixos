{config, ...}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./persist.nix
    ./users.nix

    ../../modules/nixos/core.nix
    ../../modules/nixos/services/waydroid-init.nix
  ];

  networking.hostName = "mickey";

  # Enable Services
  services = {
    xserver = {
      enable = true;
    };

    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    desktopManager.plasma6.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    teamviewer.enable = true;
  };

  virtualisation.waydroid.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
}
