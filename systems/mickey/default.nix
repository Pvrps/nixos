{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./disko.nix
    ./persist.nix
    ./users.nix

    ../../modules/nixos/core.nix
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
      settings = {
        Users = {
          HideUsers = "purps";
        };
      };
    };

    desktopManager.plasma6.enable = true;
    displayManager.defaultSession = "plasma";

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  sops.defaultSopsFile = ./secrets.yaml;
}
