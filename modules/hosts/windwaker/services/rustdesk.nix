{
  config,
  lib,
  ...
}:
let
  dockerVolumeDir = "/mnt/general/docker";
in
{
  sops.secrets."rustdesk-env".sopsFile = ./_secrets.yaml;

  virtualisation.oci-containers.containers = {
    tailscale-rustdesk = {
      image = "tailscale/tailscale:latest";
      autoStart = true;
      networks = [ "lan_bridge" ];
      capabilities = {
        NET_ADMIN = true;
        NET_RAW = true;
      };
      devices = [ "/dev/net/tun:/dev/net/tun" ];
      environmentFiles = [ config.sops.secrets."rustdesk-env".path ];
      environment = {
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_USERSPACE = "false";
        TS_HOSTNAME = "rustdesk";
      };
      ports = [
        "21115:21115/tcp"
        "21116:21116/tcp"
        "21116:21116/udp"
        "21117:21117/tcp"
        "21118:21118/tcp"
        "21119:21119/tcp"
      ];
      volumes = [
        "${dockerVolumeDir}/tailscale-rustdesk:/var/lib/tailscale"
      ];
    };

    hbbs = {
      image = "rustdesk/rustdesk-server:latest";
      autoStart = true;
      cmd = [ "hbbs" ];
      dependsOn = [ "tailscale-rustdesk" ];
      extraOptions = [ "--network=container:tailscale-rustdesk" ];
      environment.TZ = "America/Toronto";
      volumes = [
        "${dockerVolumeDir}/rustdesk:/root"
      ];
    };

    hbbr = {
      image = "rustdesk/rustdesk-server:latest";
      autoStart = true;
      cmd = [ "hbbr" ];
      dependsOn = [
        "tailscale-rustdesk"
        "hbbs"
      ];
      extraOptions = [ "--network=container:tailscale-rustdesk" ];
      environment.TZ = "America/Toronto";
      volumes = [
        "${dockerVolumeDir}/rustdesk:/root"
      ];
    };
  };

  systemd.services = {
    "docker-tailscale-rustdesk" = {
      after = [ "docker-networks.service" ];
      requires = [ "docker-networks.service" ];
      bindsTo = [ "docker.service" ];
    };
    "docker-hbbs" = {
      after = [ "docker-networks.service" ];
      requires = [ "docker-networks.service" ];
      bindsTo = [ "docker.service" ];
    };
    "docker-hbbr" = {
      after = [ "docker-networks.service" ];
      requires = [ "docker-networks.service" ];
      bindsTo = [ "docker.service" ];
    };
  };
}
