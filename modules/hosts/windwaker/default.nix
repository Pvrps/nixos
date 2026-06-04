{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./_hardware.nix
    ./_disko.nix
    ./_persist.nix
    ./users.nix

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

  # systemd-networkd: VLAN sub-interface configuration
  # Physical port must be configured as a VLAN trunk on your UDM/SE:
  #   - Tagged: VLAN 10 (internal LAN, 10.0.10.0/24)
  #   - Tagged: VLAN 120 (DMZ, 10.10.20.0/24)
  systemd.network = {
    enable = true;

    netdevs = {
      # VLAN 10 — internal LAN
      "10-vlan10" = {
        netdevConfig = {
          Name = "eno1.10";
          Kind = "vlan";
        };
        vlanConfig.Id = 10;
      };

      # VLAN 120 — DMZ
      "20-vlan120" = {
        netdevConfig = {
          Name = "eno1.120";
          Kind = "vlan";
        };
        vlanConfig.Id = 120;
      };
    };

    networks = {
      # Physical NIC: carrier only, spawns VLANs
      "10-eno1" = {
        matchConfig.Name = "eno1";
        networkConfig = {
          VLAN = ["eno1.10" "eno1.120"];
          LinkLocalAddressing = "no";
        };
      };

      # VLAN 10 — internal LAN: static 10.0.10.16/24
      "20-vlan10" = {
        matchConfig.Name = "eno1.10";
        networkConfig = {
          Address = "10.0.10.16/24";
          Gateway = "10.0.10.1";
          DNS = ["10.0.10.1"];
          LinkLocalAddressing = "no";
        };
      };

      # VLAN 120 — DMZ: static 10.10.20.16/24, no gateway
      # Cloudflared tunnel routes outbound traffic; no default gateway needed here
      "30-vlan120" = {
        matchConfig.Name = "eno1.120";
        networkConfig = {
          Address = "10.10.20.16/24";
          LinkLocalAddressing = "no";
        };
      };
    };
  };

  # Firewall: SSH only on the internal LAN interface
  networking.firewall = {
    enable = true;
    interfaces."eno1.10".allowedTCPPorts = [22];
    # Docker manages its own iptables rules for container port exposure
    trustedInterfaces = ["docker0"];
  };

  services.openssh = {
    enable = true;
    openFirewall = false; # Controlled manually above
    settings = {
      PermitRootLogin = "prohibit-password"; # SSH key only for root
      PasswordAuthentication = false; # Keys only for all users
    };
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    # Docker daemon settings
    daemon.settings = {
      # Disable userland proxy for better performance
      userland-proxy = false;
      # Use iptables for port forwarding
      iptables = true;
    };
  };

  # Create docker bridge networks bound to the VLAN sub-interfaces.
  # lan_bridge  → replaces internal_bridge (was eth0 in LXC)
  # dmz_bridge  → replaces external_bridge (was eth1 in LXC)
  # These are idempotent: the || true prevents failure if the network already exists.
  systemd.services.docker-networks = {
    description = "Create persistent Docker bridge networks";
    after = ["docker.service" "network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "create-docker-networks" ''
        ${pkgs.docker}/bin/docker network create \
          --driver bridge \
          --opt "com.docker.network.bridge.bind_iface=eno1.10" \
          lan_bridge || true

        ${pkgs.docker}/bin/docker network create \
          --driver bridge \
          --opt "com.docker.network.bridge.bind_iface=eno1.120" \
          dmz_bridge || true
      '';
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  sops.defaultSopsFile = ./_secrets.yaml;
}
