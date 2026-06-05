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
    archi-steam-farm = {
      image = "justarchi/archisteamfarm:latest";
      autoStart = true;
      networks = [ "lan_bridge" ];
      volumes = [
        "${dockerVolumeDir}/archi_steam_farm/config:/app/config"
        "${dockerVolumeDir}/archi_steam_farm/config:/app/logs"
      ];
    };
  };

  systemd.services."docker-archi-steam-farm" = {
    after = [ "docker-networks.service" ];
    requires = [ "docker-networks.service" ];
    bindsTo = [ "docker.service" ];
  };
}
