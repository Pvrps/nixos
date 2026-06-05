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
    audiobookshelf = {
      image = "ghcr.io/advplyr/audiobookshelf:latest";
      autoStart = true;
      networks = [ "lan_bridge" ];
      ports = [ "13378:80" ];
      environment.TZ = "America/Toronto";
      volumes = [
        "${dockerVolumeDir}/audiobookshelf/audiobooks:/audiobooks"
        "${dockerVolumeDir}/audiobookshelf/podcasts:/podcasts"
        "${dockerVolumeDir}/audiobookshelf/config:/config"
        "${dockerVolumeDir}/audiobookshelf/metadata:/metadata"
      ];
    };
  };

  systemd.services."podman-audiobookshelf" = {
    after = [ "podman-networks.service" ];
    requires = [ "podman-networks.service" ];
  };
}
