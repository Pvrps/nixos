_: let
  dockerVolumeDir = "/mnt/docker";
in {
  virtualisation.quadlet.containers.audiobookshelf = {
    autoStart = true;
    containerConfig = {
      image = "ghcr.io/advplyr/audiobookshelf:latest";
      networks = ["lan_bridge"];
      publishPorts = ["13378:80"];
      environments = {
        TZ = "America/Toronto";
      };
      volumes = [
        "${dockerVolumeDir}/audiobookshelf/audiobooks:/audiobooks"
        "${dockerVolumeDir}/audiobookshelf/podcasts:/podcasts"
        "${dockerVolumeDir}/audiobookshelf/config:/config"
        "${dockerVolumeDir}/audiobookshelf/metadata:/metadata"
      ];
    };
    # /mnt is nofail; without this, podman creates empty bind-source dirs
    # on the tmpfs root if the USB disk is absent at boot.
    unitConfig.RequiresMountsFor = ["/mnt/docker"];
    serviceConfig = {
      Restart = "always";
      RestartSec = "10";
    };
  };
}
