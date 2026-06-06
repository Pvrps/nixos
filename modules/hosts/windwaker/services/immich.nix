{
  config,
  ...
}:
let
  dockerVolumeDir = "/mnt/general/docker";
  uploadVolumeDir = "/mnt/media/docker";
in
{
  sops.secrets."immich-env".sopsFile = ./_secrets.yaml;

  virtualisation.quadlet = {
    containers = {
      immich-server = {
        autoStart = true;
        containerConfig = {
          image = "ghcr.io/immich-app/immich-server:release";
          networks = [
            "immich_internal"
            "lan_bridge"
          ];
          publishPorts = [ "62283:2283" ];
          environments = {
            IMMICH_HOST = "0.0.0.0";
          };
          volumes = [
            "${uploadVolumeDir}/immich/library:/usr/src/app/upload"
            "/etc/localtime:/etc/localtime:ro"
          ];
        };
        unitConfig = {
          After = [
            "redis.service"
            "database.service"
          ];
          Requires = [
            "redis.service"
            "database.service"
          ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };

      immich-machine-learning = {
        autoStart = true;
        containerConfig = {
          image = "ghcr.io/immich-app/immich-machine-learning:release";
          networks = [ "immich_internal" ];
          volumes = [ "model-cache:/cache" ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };

      redis = {
        autoStart = true;
        containerConfig = {
          image = "docker.io/valkey/valkey:8-bookworm@sha256:fec42f399876eb6faf9e008570597741c87ff7662a54185593e74b09ce83d177";
          networks = [ "immich_internal" ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };

      database = {
        autoStart = true;
        containerConfig = {
          image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
          networks = [ "immich_internal" ];
          environmentFiles = [ config.sops.secrets."immich-env".path ];
          environments = {
            POSTGRES_INITDB_ARGS = "--data-checksums";
            DB_STORAGE_TYPE = "HDD";
          };
          volumes = [
            "${uploadVolumeDir}/immich/postgres:/var/lib/postgresql/data"
          ];
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = "10";
        };
      };
    };

    volumes.model-cache = { };
  };
}
