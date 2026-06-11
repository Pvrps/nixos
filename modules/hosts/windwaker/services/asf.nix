{
  ...
}:
let
  dockerVolumeDir = "/mnt/docker";
in
{
  virtualisation.quadlet.containers.archi-steam-farm = {
    autoStart = true;
    containerConfig = {
      image = "justarchi/archisteamfarm:latest";
      networks = [ "lan_bridge" ];
      volumes = [
        "${dockerVolumeDir}/archi_steam_farm/config:/app/config"
        "${dockerVolumeDir}/archi_steam_farm/config:/app/logs"
      ];
    };
    serviceConfig = {
      Restart = "always";
      RestartSec = "10";
    };
  };
}
