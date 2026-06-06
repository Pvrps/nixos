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
    ./services/dragonwilds.nix

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

  # Firewall: SSH + Cockpit on the internal LAN interface (eno1, native VLAN 10)
  networking.firewall = {
    enable = true;
    # Podman manages its own iptables rules for container port exposure
    # podman1/podman2 are the bridge interfaces for quadlet networks (lan_bridge, immich_internal)
    trustedInterfaces = [ "podman0" "podman1" "podman2" ];
  };

  services.openssh = {
    enable = true;
    openFirewall = false; # Controlled manually above
    settings = {
      PermitRootLogin = "prohibit-password"; # SSH key only for root
      PasswordAuthentication = false; # Keys only for all users
    };
  };

  # Podman — quadlet-nix enables virtualisation.podman automatically;
  # these options layer on top for the docker socket and auto-pruning.
  virtualisation.podman = {
    dockerSocket.enable = true; # keeps homepage's /var/run/docker.sock mount working
    autoPrune.enable = true;
  };

  # Cockpit web UI with the Podman plugin.
  # NPM proxies to https://10.0.10.16:9090 (Cockpit keeps its own TLS).
  # In NPM: scheme=https, host=10.0.10.16, port=9090, websockets on.
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = false; # exposed only on the LAN interface below
    plugins = [ pkgs.cockpit-podman ];
    settings = {
      WebService.Origins = lib.mkForce "https://podman.windwaker.ca wss://podman.windwaker.ca";
      WebService.ProtocolHeader = "X-Forwarded-Proto";
      # Point cockpit-podman at the system (rootful) socket instead of the user socket
      Session.Environment = "CONTAINER_HOST=unix:///run/podman/podman.sock";
    };
  };

  networking.firewall.interfaces."eno1".allowedTCPPorts = [
    22
    9090
  ];

  # SSH-key-only host — passwords are random and unknown, so wheel must not need one for sudo
  security.sudo.wheelNeedsPassword = false;

  # Allow podman-admin to run cockpit-bridge --privileged as root without a password.
  # This is the minimum needed for Cockpit to show system services and containers.
  # The command path is pinned to the exact cockpit store path to prevent privilege escalation.
  security.sudo.extraRules = [
    {
      users = [ "podman-admin" ];
      commands = [
        {
          command = "${pkgs.cockpit}/libexec/cockpit-bridge --privileged";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  sops.defaultSopsFile = ./_secrets.yaml;
}
