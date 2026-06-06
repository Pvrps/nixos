{
  config,
  ...
}:
let
  dockerVolumeDir = "/mnt/general/docker";
in
{
  sops.secrets."dragonwilds-env".sopsFile = ./_secrets.yaml;

  virtualisation.oci-containers.containers = {
    runescape-dragonwilds = {
      image = "indifferentbroccoli/runescape-dragonwilds-server-docker:latest";
      autoStart = true;
      networks = [ "lan_bridge" ];
      ports = [ "55180:55180/udp" ];
      environmentFiles = [ config.sops.secrets."dragonwilds-env".path ];
      environment = {
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
  };

  systemd.services = {
    "podman-runescape-dragonwilds" = {
      after = [ "podman-networks.service" ];
      requires = [ "podman-networks.service" ];
    };
  };
}
