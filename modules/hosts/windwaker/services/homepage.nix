{
  config,
  lib,
  ...
}:
let
  dockerVolumeDir = "/mnt/general/docker";
in
{
  virtualisation.oci-containers.containers = {
    homepage = {
      image = "ghcr.io/gethomepage/homepage:latest";
      autoStart = true;
      networks = [ "lan_bridge" ];
      ports = [ "47576:3000" ];
      environment.HOMEPAGE_ALLOWED_HOSTS = "windwaker.ca:47576,10.0.10.16:47576,homepage.windwaker.ca";
      volumes = [
        "${dockerVolumeDir}/homepage/config:/app/config"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
    };
  };

  systemd.services."docker-homepage" = {
    after = [ "docker-networks.service" ];
    requires = [ "docker-networks.service" ];
    bindsTo = [ "docker.service" ];
  };
}
