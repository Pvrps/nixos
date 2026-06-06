{
  config,
  lib,
  ...
}:
let
  dockerVolumeDir = "/mnt/general/docker";
in
{
  sops.secrets."network-env".sopsFile = ./_secrets.yaml;
  sops.secrets."playit-env".sopsFile = ./_secrets.yaml;
  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers = {
    cloudflared-tunnel = {
      image = "cloudflare/cloudflared";
      cmd = [
        "tunnel"
        "run"
      ];
      autoStart = true;
      networks = [
        "lan_bridge"
        "dmz_bridge"
      ];
      environmentFiles = [ config.sops.secrets."network-env".path ];
      environment = {
        TUNNEL_DNS_UPSTREAM = "1.1.1.2";
        TUNNEL_DNS_PORT = "53";
        TUNNEL_DNS_ADDRESS = "0.0.0.0";
      };
      volumes = [
        "${dockerVolumeDir}/cloudflared:/etc/cloudflared"
      ];
    };

    nginx-proxy-manager = {
      image = "jc21/nginx-proxy-manager:latest";
      autoStart = true;
      networks = [ "lan_bridge" ];
      dependsOn = [ "cloudflared-tunnel" ];
      ports = [
        "80:80"
        "443:443"
        "181:81"
      ];
      volumes = [
        "${dockerVolumeDir}/nginx_proxy_manager/data:/data"
        "${dockerVolumeDir}/nginx_proxy_manager/letsencrypt:/etc/letsencrypt"
      ];
    };

    pihole = {
      image = "pihole/pihole:latest";
      autoStart = true;
      networks = [ "lan_bridge" ];
      ports = [
        "10.0.10.16:53:53/tcp"
        "10.0.10.16:53:53/udp"
        "127.0.0.1:53:53/tcp"
        "127.0.0.1:53:53/udp"
        "14433:443/tcp"
        "1800:80"
      ];
      environment = {
        TZ = "America/Toronto";
        FTLCONF_dns_upstreams = "1.1.1.2";
      };
      environmentFiles = [ config.sops.secrets."network-env".path ];
      volumes = [
        "${dockerVolumeDir}/pihole/etc-pihole:/etc/pihole"
        "${dockerVolumeDir}/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
      ];
    };

    playit-agent = {
      image = "ghcr.io/playit-cloud/playit-agent:0.17";
      autoStart = true;
      networks = [ "dmz_bridge" ];
      extraOptions = [ "--network-alias=playit-agent" ];
      environmentFiles = [ config.sops.secrets."playit-env".path ];
    };
  };

  systemd.services = {
    "podman-cloudflared-tunnel" = {
      after = [ "podman-networks.service" ];
      requires = [ "podman-networks.service" ];
    };
    "podman-nginx-proxy-manager" = {
      after = [ "podman-networks.service" ];
      requires = [ "podman-networks.service" ];
    };
    "podman-pihole" = {
      after = [ "podman-networks.service" ];
      requires = [ "podman-networks.service" ];
    };
    "podman-playit-agent" = {
      after = [ "podman-networks.service" ];
      requires = [ "podman-networks.service" ];
    };
  };
}
