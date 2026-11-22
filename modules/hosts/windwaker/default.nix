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
    ./services/network.nix
    ./services/rustdesk.nix
    ./services/homepage.nix
    ./services/immich.nix
    ./services/audiobookshelf.nix
    ./services/cwa.nix
    ./services/suwayomi.nix
    ./services/asf.nix
    ./services/twitchpointminer.nix
    #./services/dragonwilds.nix
    ./services/beszel-hub.nix
    ./services/qbittorrent.nix
    ./services/purps-ca.nix
    #./services/skyrim-together.nix
  ];

  custom.remoteAdmin = {
    enable = true;
    openFirewall = false; # SSH exposed only on the LAN interface below
  };

  networking = {
    # Disable NetworkManager — use systemd-networkd for static VLAN sub-interfaces
    networkmanager.enable = lib.mkForce false;
    useNetworkd = true;
  };

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
          DNS = ["10.0.10.1"];
          VLAN = ["eno1.120"];
          LinkLocalAddressing = "no";
        };
      };

      # VLAN 120 — DMZ: brought up with no address. It is only the parent of
      # the dmz_bridge macvlan (services/network.nix); the host itself has no
      # business in the DMZ. An address here also breaks the DMZ containers'
      # DNS: Pi-hole's replies would leave by this interface rather than back
      # through the router, and a macvlan parent cannot reach its children.
      "20-vlan120" = {
        matchConfig.Name = "eno1.120";
        linkConfig.RequiredForOnline = "no";
        networkConfig = {
          LinkLocalAddressing = "no";
        };
      };
    };
  };

  # Firewall: SSH + Cockpit are opened on eno1 (native VLAN 10) further down.
  networking.firewall = {
    enable = true;
    # Podman manages its own rules for published container ports, so those
    # bypass this firewall. podmanN are the bridge interfaces of the quadlet
    # networks (lan_bridge, immich_internal).
    trustedInterfaces = ["podman0" "podman1" "podman2" "tailscale0"];
  };

  # Podman — quadlet-nix enables virtualisation.podman automatically;
  # these options layer on top for the docker socket and auto-pruning.
  virtualisation.podman = {
    dockerSocket.enable = true; # keeps homepage's /var/run/docker.sock mount working
    autoPrune.enable = true;
  };

  # Auto-update containers: the podman-auto-update timer pulls newer images for
  # every container labelled io.containers.autoupdate=registry (mkContainer sets
  # this by default) and restarts the unit, rolling back on failure. Images
  # pinned by an exact version tag are left alone and must still be bumped
  # manually in their service .nix. Digest-pinned images (e.g. immich's valkey)
  # must set `autoUpdate = null`: a tag+digest reference makes the whole
  # podman-auto-update run fail.
  virtualisation.quadlet.autoUpdate = {
    enable = true;
    calendar = "*-*-* 04:00:00"; # daily at 04:00 America/Toronto
  };

  # Cockpit web UI with the Podman plugin.
  # NPM proxies to https://10.0.10.16:9090 (Cockpit keeps its own TLS).
  # In NPM: scheme=https, host=10.0.10.16, port=9090, websockets on.
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = false; # exposed only on the LAN interface below
    plugins = [pkgs.cockpit-podman];
    settings = {
      WebService.Origins = lib.mkForce "https://podman.windwaker.ca wss://podman.windwaker.ca";
      WebService.ProtocolHeader = "X-Forwarded-Proto";
      Session.Environment = "CONTAINER_HOST=unix:///run/podman/podman.sock";
    };
  };

  networking.firewall.interfaces."eno1".allowedTCPPorts = [
    22
    9090
  ];

  # Allow podman-admin to run cockpit-bridge --privileged as root without a password.
  # This is the minimum needed for Cockpit to show system services and containers.
  # The command path is pinned to the exact cockpit store path to prevent privilege escalation.
  security.sudo.extraRules = [
    {
      users = ["podman-admin"];
      commands = [
        {
          command = "${pkgs.cockpit}/bin/cockpit-bridge --privileged";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # Agent and hub are co-located: no hubUrl/tokenFile needed.
  custom.services.beszel-agent = {
    enable = true;
    extraFilesystems = ["sda" "sdb"];
    gpuPackages = [pkgs.intel-gpu-tools];
    capPerfmon = true;
    gpuMonitoring = true;
    intelGpuDevice = "drm:/dev/dri/card0";
  };
}
