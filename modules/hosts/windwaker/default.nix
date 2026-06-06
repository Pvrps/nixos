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

  # Podman — quadlet-nix enables virtualisation.podman automatically;
  # these options layer on top for the docker socket and auto-pruning.
  virtualisation.podman = {
    dockerSocket.enable = true; # keeps homepage's /var/run/docker.sock mount working
    autoPrune.enable = true;
  };

  # Cockpit web UI with the Podman plugin.
  # Reverse-proxy podman.windwaker.ca → 10.0.10.16:9090 via nginx-proxy-manager.
  # NPM handles TLS; Cockpit is configured to serve plain HTTP only.
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = false; # exposed only on the LAN interface below
    plugins = [ pkgs.cockpit-podman ];
    settings = {
      # Origins: allow the reverse-proxy domain (wss for websockets, https for login)
      WebService.Origins = lib.mkForce "https://podman.windwaker.ca wss://podman.windwaker.ca https://localhost:9090";
      # AllowedHosts: accept Host headers from the reverse proxy; fixes CSP generation
      WebService.AllowedHosts = "podman.windwaker.ca localhost";
    };
  };

  # Pass --no-tls to cockpit-ws so it serves plain HTTP without redirecting.
  # NPM handles TLS termination externally.
  # Also pass --for-tls-proxy so Cockpit accepts https:// Origins correctly.
  systemd.services.cockpit = {
    serviceConfig.ExecStart = lib.mkForce [
      ""
      "${pkgs.cockpit}/libexec/cockpit-ws --no-tls --port=9090"
    ];
  };

  networking.firewall.interfaces."eno1".allowedTCPPorts = [
    22
    9090
  ];

  # SSH-key-only host — passwords are random and unknown, so wheel must not need one for sudo
  security.sudo.wheelNeedsPassword = false;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  sops.defaultSopsFile = ./_secrets.yaml;
}
