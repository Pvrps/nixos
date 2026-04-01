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
    ../../modules/nixos/tailscale.nix
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

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
      };
    };
  };

  # krdp is required for Plasma 6 Remote Desktop Server
  environment.systemPackages = with pkgs.kdePackages; [
    krdp
  ];

  # Force RDP server to start automatically with Plasma
  systemd.user.services."app-org.kde.krdpserver" = {
    wantedBy = [ "plasma-workspace.target" ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.common = {
      default = [ "kde" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "kde" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "kde" ];
      "org.freedesktop.impl.portal.RemoteDesktop" = [ "kde" ];
    };
  };

  sops.defaultSopsFile = ./secrets.yaml;
}
