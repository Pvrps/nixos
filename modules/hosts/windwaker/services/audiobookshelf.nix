{lib, ...}: let
  dockerVolumeDir = "/mnt/docker";
in {
  virtualisation.quadlet.containers.audiobookshelf = lib.custom.mkContainer {
    containerConfig = {
      image = "ghcr.io/advplyr/audiobookshelf:latest";
      publishPorts = ["13378:80"];
      volumes = [
        "${dockerVolumeDir}/audiobookshelf/audiobooks:/audiobooks"
        "${dockerVolumeDir}/audiobookshelf/podcasts:/podcasts"
        "${dockerVolumeDir}/audiobookshelf/config:/config"
        "${dockerVolumeDir}/audiobookshelf/metadata:/metadata"
      ];
    };
  };
}
