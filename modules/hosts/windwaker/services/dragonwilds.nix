{
  config,
  ...
}:
let
  dockerVolumeDir = "/mnt/docker";
in
{
  sops.secrets."dragonwilds-env".sopsFile = ./_secrets.yaml;

  virtualisation.quadlet.containers.runescape-dragonwilds = {
    autoStart = true;
    containerConfig = {
      image = "indifferentbroccoli/runescape-dragonwilds-server-docker:latest";
      networks = [ "lan_bridge" ];
      publishPorts = [ "55180:55180/udp" ];
      environmentFiles = [ config.sops.secrets."dragonwilds-env".path ];
      environments = {
        PUID = "1000";
        PGID = "1000";
        OWNER_ID = "0002ae80ae5c49c684eb9fdd41395eb7";
        SERVER_NAME = "DragonWildsServer";
        DEFAULT_WORLD_NAME = "MyWorld";
        DEFAULT_PORT = "55180";
        MAX_PLAYERS = "6";
        UPDATE_ON_START = "true";
      };
      volumes = [
        "${dockerVolumeDir}/runescape-dragonwilds/server-files:/home/steam/server-files"
      ];
    };
    unitConfig.RequiresMountsFor = ["/mnt/docker"];
    serviceConfig = {
      Restart = "always";
      RestartSec = "10";
    };
  };
}
