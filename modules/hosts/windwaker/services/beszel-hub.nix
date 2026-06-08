{
  config,
  ...
}:
let
  dockerVolumeDir = "/mnt/general/docker";
in
{
  sops.secrets."beszel-hub-env".sopsFile = ./_secrets.yaml;

  virtualisation.quadlet.containers.beszel-hub = {
    autoStart = true;
    containerConfig = {
      image = "docker.io/henrygd/beszel:latest";
      networks = [ "lan_bridge" ];
      publishPorts = [ "8090:8090" ];
      environmentFiles = [ config.sops.secrets."beszel-hub-env".path ];
      volumes = [
        "${dockerVolumeDir}/beszel/data:/beszel_data"
      ];
    };
    serviceConfig = {
      Restart = "always";
      RestartSec = "10";
    };
  };
}
