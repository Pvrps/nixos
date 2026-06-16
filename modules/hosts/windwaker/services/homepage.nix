{lib, ...}: let
  dockerVolumeDir = "/mnt/docker";
in {
  virtualisation.quadlet.containers.homepage = lib.custom.mkContainer {
    tz = null;
    containerConfig = {
      image = "ghcr.io/gethomepage/homepage:latest";
      publishPorts = ["47576:3000"];
      environments = {
        HOMEPAGE_ALLOWED_HOSTS = "windwaker.ca:47576,10.0.10.16:47576,homepage.windwaker.ca";
      };
      volumes = [
        "${dockerVolumeDir}/homepage/config:/app/config"
        "/run/podman/podman.sock:/var/run/docker.sock:ro"
      ];
    };
  };
}
