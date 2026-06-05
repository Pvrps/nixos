{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./_hardware.nix
    ./_disko.nix
    ./_persist.nix
    ./users.nix
    ./services/network.nix
    ./services/rustdesk.nix
    ./services/homepage.nix
    ./services/immich.nix
    ./services/audiobookshelf.nix
    ./services/cwa.nix
    ./services/suwayomi.nix
    ./services/asf.nix
    ./services/twitchpointminer.nix

    ../../../modules/nixos/core.nix
  ];

  programs.nh = {
    enable = true;
  };

  networking = {
    hostName = "windwaker";

    # Disable NetworkManager — use systemd-networkd for static VLAN sub-interfaces
    networkmanager.enable = lib.mkForce false;
    useNetworkd = true;
  };

  # Disable resolved from core.nix — networkd handles DNS directly
  services.resolved.enable = lib.mkForce false;

  systemd.network = {
    enable = true;

    netdevs = {
      # VLAN 120 — DMZ (tagged on the wire)
      "10-vlan120" = {
        netdevConfig = {
          Name = "eno1.120";
          Kind = "vlan";
        };
        vlanConfig.Id = 120;
      };
    };

    networks = {
      # Physical NIC: carries untagged VLAN 10 traffic directly + spawns VLAN 120
      "10-eno1" = {
        matchConfig.Name = "eno1";
        networkConfig = {
          Address = "10.0.10.16/24";
          Gateway = "10.0.10.1";
          DNS = [ "10.0.10.1" ];
          VLAN = [ "eno1.120" ];
          LinkLocalAddressing = "no";
        };
      };

      # VLAN 120 — DMZ: static 10.10.20.16/24, no gateway
      # Cloudflared tunnel routes outbound traffic; no default gateway needed here
      "20-vlan120" = {
        matchConfig.Name = "eno1.120";
        networkConfig = {
          Address = "10.10.20.16/24";
          LinkLocalAddressing = "no";
        };
      };
    };
  };

  # Firewall: SSH only on the internal LAN interface (eno1, native VLAN 10)
  networking.firewall = {
    enable = true;
    interfaces."eno1".allowedTCPPorts = [ 22 ];
    # Podman manages its own iptables rules for container port exposure
    trustedInterfaces = [ "podman0" ];
  };

  services.openssh = {
    enable = true;
    openFirewall = false; # Controlled manually above
    settings = {
      PermitRootLogin = "prohibit-password"; # SSH key only for root
      PasswordAuthentication = false; # Keys only for all users
    };
  };

  # Podman
  virtualisation.podman = {
    enable = true;
    # Expose a Docker-compatible socket so tools like homepage can use it
    dockerSocket.enable = true;
    # Clean up unused images/containers automatically
    autoPrune.enable = true;
  };

  # Podman needs both USB SSD partitions before containers with bind mounts can start
  systemd.services.podman.after = [
    "mnt-general.mount"
    "mnt-media.mount"
  ];
  systemd.services.podman.wants = [
    "mnt-general.mount"
    "mnt-media.mount"
  ];

  # Create Podman networks.
  # - lan_bridge: standard bridge; containers publish ports to the host IP (10.0.10.16)
  # - dmz_bridge: macvlan on eno1.120 so cloudflared-tunnel appears directly on VLAN 120
  # - immich_internal: isolated internal bridge for the Immich stack
  # All commands are idempotent via || true.
  systemd.services.podman-networks = {
    description = "Create persistent Podman networks";
    after = [
      "podman.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "create-podman-networks" ''
        ${pkgs.podman}/bin/podman network create \
          --driver bridge \
          lan_bridge || true

        ${pkgs.podman}/bin/podman network create \
          --driver macvlan \
          --opt parent=eno1.120 \
          --subnet 10.10.20.0/24 \
          --gateway 10.10.20.1 \
          dmz_bridge || true

        ${pkgs.podman}/bin/podman network create \
          --driver bridge \
          --internal \
          immich_internal || true
      '';
    };
  };

  # SSH-key-only host — passwords are random and unknown, so wheel must not need one for sudo
  security.sudo.wheelNeedsPassword = false;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  sops.defaultSopsFile = ./_secrets.yaml;
}
