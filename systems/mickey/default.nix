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

    displayManager.defaultSession = "lxqt-wayland";
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      settings = {
        Users = {
          HideUsers = "purps";
        };
      };
    };
    xserver.desktopManager.lxqt.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  services.displayManager.sessionPackages = [pkgs.lxqt.lxqt-wayland-session];

  programs.labwc.enable = true;

  sops.defaultSopsFile = ./secrets.yaml;
}
