{lib, ...}: let
  dockerVolumeDir = "/mnt/docker";
in {
  virtualisation.quadlet.containers.archi-steam-farm = lib.custom.mkContainer {
    tz = null;
    containerConfig = {
      image = "justarchi/archisteamfarm:latest";
      volumes = [
        "${dockerVolumeDir}/archi_steam_farm/config:/app/config"
        "${dockerVolumeDir}/archi_steam_farm/config:/app/logs"
      ];
    };
  };
}
