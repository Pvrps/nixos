{
  config,
  lib,
  ...
}: let
  dockerVolumeDir = "/mnt/docker";
in {
  sops.secrets."immich-env".sopsFile = ./_secrets.yaml;

  virtualisation.quadlet = {
    containers = {
      immich-server = lib.custom.mkContainer {
        tz = null;
        networks = ["immich_internal" "lan_bridge"];
        containerConfig = {
          image = "ghcr.io/immich-app/immich-server:release";
          publishPorts = ["62283:2283"];
          environments = {
            IMMICH_HOST = "0.0.0.0";
          };
          volumes = [
            "${dockerVolumeDir}/immich/library:/usr/src/app/upload"
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
      };

      immich-machine-learning = lib.custom.mkContainer {
        tz = null;
        requiresMounts = false;
        networks = ["immich_internal"];
        containerConfig = {
          image = "ghcr.io/immich-app/immich-machine-learning:release";
          volumes = ["model-cache:/cache"];
        };
      };

      redis = lib.custom.mkContainer {
        tz = null;
        requiresMounts = false;
        networks = ["immich_internal"];
        containerConfig = {
          # MAINTENANCE: image pinned by digest; bump manually.
          image = "docker.io/valkey/valkey:8-bookworm@sha256:fec42f399876eb6faf9e008570597741c87ff7662a54185593e74b09ce83d177";
        };
      };

      database = lib.custom.mkContainer {
        tz = null;
        networks = ["immich_internal"];
        containerConfig = {
          image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
          environmentFiles = [config.sops.secrets."immich-env".path];
          environments = {
            POSTGRES_INITDB_ARGS = "--data-checksums";
            DB_STORAGE_TYPE = "HDD";
          };
          volumes = [
            "${dockerVolumeDir}/immich/postgres:/var/lib/postgresql/data"
          ];
        };
      };
    };

    volumes.model-cache = {};
  };
}
