{
  config,
  lib,
  ...
}: let
  dockerVolumeDir = "/mnt/docker";
in {
  sops.secrets."beszel-hub-env".sopsFile = ./_secrets.yaml;

  virtualisation.quadlet.containers.beszel-hub = lib.custom.mkContainer {
    tz = null;
    containerConfig = {
      image = "docker.io/henrygd/beszel:latest";
      publishPorts = ["8090:8090"];
      environmentFiles = [config.sops.secrets."beszel-hub-env".path];
      volumes = [
        "${dockerVolumeDir}/beszel/data:/beszel_data"
      ];
    };
  };
}
