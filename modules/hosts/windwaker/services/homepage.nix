{lib, ...}: let
  dockerVolumeDir = "/mnt/docker";
in {
  virtualisation.quadlet.containers.homepage = lib.custom.mkContainer {
    tz = null;
    containerConfig = {
      image = "ghcr.io/gethomepage/homepage:latest";
      publishPorts = ["47576:3000"];
      # Disable the image's built-in HEALTHCHECK. podman spawns a transient
      # systemd healthcheck unit per probe; the first probe fires before the
      # app's HTTP server is listening and is recorded as a failed unit (even
      # though the container is within its start period), which makes
      # nixos-rebuild report a spurious activation failure. We don't act on
      # container health anywhere, so turn it off.
      healthCmd = "none";
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
