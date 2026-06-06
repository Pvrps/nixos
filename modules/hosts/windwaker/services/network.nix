{
  config,
  ...
}:
let
  dockerVolumeDir = "/mnt/general/docker";
in
{
  sops.secrets."network-env".sopsFile = ./_secrets.yaml;
  sops.secrets."playit-env".sopsFile = ./_secrets.yaml;

  virtualisation.quadlet = {
    networks = {
      # Standard bridge — containers publish ports to the host IP (10.0.10.16).
      # Fixed subnet so the gateway (10.88.0.1) is stable across rebuilds.
      lan_bridge.networkConfig = {
        disableDns = true;
        subnets = [ "10.99.0.0/24" ];
      };

      # macvlan on eno1.120 so cloudflared-tunnel appears directly on VLAN 120
      dmz_bridge = {
        networkConfig = {
          driver = "macvlan";
          options = { parent = "eno1.120"; };
          subnets = [ "10.10.20.0/24" ];
          gateways = [ "10.10.20.1" ];
        };
      };

      # Isolated internal bridge for the Immich stack
      immich_internal = { };
    };

    containers = {
      cloudflared-tunnel = {
        autoStart = true;
        containerConfig = {
          image = "cloudflare/cloudflared";
          exec = "tunnel run";
          networks = [ "lan_bridge" ];
          environmentFiles = [ config.sops.secrets."network-env".path ];
          environments = {
            TUNNEL_DNS_UPSTREAM = "1.1.1.2";
            TUNNEL_DNS_PORT = "53";
            TUNNEL_DNS_ADDRESS = "0.0.0.0";
          };
          volumes = [ "${dockerVolumeDir}/cloudflared:/etc/cloudflared" ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };

      nginx-proxy-manager = {
        autoStart = true;
        containerConfig = {
          image = "jc21/nginx-proxy-manager:latest";
          networks = [ "lan_bridge" ];
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
        unitConfig = {
          After = [ "cloudflared-tunnel.service" ];
          Requires = [ "cloudflared-tunnel.service" ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };

      pihole = {
        autoStart = true;
        containerConfig = {
          image = "pihole/pihole:latest";
          networks = [ "lan_bridge" ];
          publishPorts = [
            "10.0.10.16:53:53/tcp"
            "10.0.10.16:53:53/udp"
            "127.0.0.1:53:53/tcp"
            "127.0.0.1:53:53/udp"
            "14433:443/tcp"
            "1800:80"
          ];
          environmentFiles = [ config.sops.secrets."network-env".path ];
          environments = {
            TZ = "America/Toronto";
            FTLCONF_dns_upstreams = "1.1.1.2";
          };
          volumes = [
            "${dockerVolumeDir}/pihole/etc-pihole:/etc/pihole"
            "${dockerVolumeDir}/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
          ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };

      playit-agent = {
        autoStart = true;
        containerConfig = {
          image = "ghcr.io/playit-cloud/playit-agent:0.17";
          networks = [ "lan_bridge" ];
          environmentFiles = [ config.sops.secrets."playit-env".path ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };
    };
  };
}
