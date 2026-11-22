{
  config,
  lib,
  ...
}: let
  dockerVolumeDir = "/mnt/docker";
in {
  sops.secrets."cloudflared-env".sopsFile = ./_secrets.yaml;
  sops.secrets."pihole-env".sopsFile = ./_secrets.yaml;
  #sops.secrets."playit-env".sopsFile = ./_secrets.yaml;

  virtualisation.quadlet = {
    networks = {
      # Standard bridge — containers publish ports to the host IP (10.0.10.16).
      # Fixed subnet so the gateway (10.99.0.1) is stable across rebuilds.
      lan_bridge.networkConfig = {
        disableDns = true;
        subnets = ["10.99.0.0/24"];
      };

      # macvlan on eno1.120: containers here sit directly on VLAN 120 (DMZ) and
      # hold the whole public path (cloudflared-tunnel -> purps-ca). The UDM
      # lets the DMZ reach the internet and Pi-hole DNS and nothing else, and a
      # macvlan container cannot talk to the host either, so a break-in through
      # the public site stays in that VLAN.
      #
      # Addresses are fixed and kept below the UDM's DHCP range (.128-.250):
      #   10.10.20.10  cloudflared-tunnel
      #   10.10.20.11  purps-ca
      dmz_bridge = {
        networkConfig = {
          driver = "macvlan";
          options = {parent = "eno1.120";};
          subnets = ["10.10.20.0/24"];
          gateways = ["10.10.20.1"];
        };
      };

      # Isolated internal bridge for the Immich stack
      immich_internal = {};
    };

    containers = {
      # Public entry point. The tunnel's ingress (set in the Cloudflare
      # dashboard) points purps.ca and *.purps.ca at http://10.10.20.11:3000,
      # i.e. straight at purps-ca on the same macvlan.
      cloudflared-tunnel = lib.custom.mkContainer {
        tz = null;
        requiresMounts = false;
        network = "dmz_bridge";
        containerConfig = {
          image = "docker.io/cloudflare/cloudflared";
          exec = "tunnel run";
          ip = "10.10.20.10";
          dns = ["10.0.10.16"];
          environmentFiles = [config.sops.secrets."cloudflared-env".path];
        };
      };

      nginx-proxy-manager = lib.custom.mkContainer {
        tz = null;
        containerConfig = {
          image = "docker.io/jc21/nginx-proxy-manager:latest";
          publishPorts = [
            "80:80"
            "443:443"
            "181:81"
          ];
          volumes = [
            "${dockerVolumeDir}/nginx_proxy_manager/data:/data"
            "${dockerVolumeDir}/nginx_proxy_manager/letsencrypt:/etc/letsencrypt"
          ];
        };
      };

      pihole = lib.custom.mkContainer {
        containerConfig = {
          image = "docker.io/pihole/pihole:latest";
          publishPorts = [
            "10.0.10.16:53:53/tcp"
            "10.0.10.16:53:53/udp"
            "127.0.0.1:53:53/tcp"
            "127.0.0.1:53:53/udp"
            "14433:443/tcp"
            "1800:80"
          ];
          environmentFiles = [config.sops.secrets."pihole-env".path];
          environments = {
            FTLCONF_dns_upstreams = "1.1.1.2";
          };
          volumes = [
            "${dockerVolumeDir}/pihole/etc-pihole:/etc/pihole"
            "${dockerVolumeDir}/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
          ];
        };
      };

      # Disabled while no game server is running behind it (dragonwilds is
      # off): it is a public way in that leads nowhere. Re-enable together
      # with the server, and the sops secret at the top of this file.
      #playit-agent = lib.custom.mkContainer {
      #  tz = null;
      #  requiresMounts = false;
      #  containerConfig = {
      #    image = "ghcr.io/playit-cloud/playit-agent:0.17";
      #    environmentFiles = [config.sops.secrets."playit-env".path];
      #  };
      #};
    };
  };
}
