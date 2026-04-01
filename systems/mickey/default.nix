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
      wayland.enable = false;
      settings = {
        Users = {
          HideUsers = "purps";
        };
      };
    };

    desktopManager.plasma6.enable = true;
    displayManager.defaultSession = "plasmax11";

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

  systemd.services.rustdesk = {
    description = "RustDesk Unattended Service";
    requires = [ "network.target" ];
    after = [ "systemd-user-sessions.service" "display-manager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk --service";
      ExecStop = "${pkgs.procps}/bin/pkill -f 'rustdesk --'";
      KillMode = "mixed";
      TimeoutStopSec = 30;
      User = "root";
      LimitNOFILE = 100000;
      Environment = [
        "PULSE_LATENCY_MSEC=60"
        "PIPEWIRE_LATENCY=1024/48000"
      ];
    };
  };

  sops.defaultSopsFile = ./secrets.yaml;
}
