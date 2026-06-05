{
  config,
  lib,
  ...
}: let
  dockerVolumeDir = "/mnt/general/docker";
  uploadVolumeDir = "/mnt/media/docker";
in {
  sops.secrets."immich-env".sopsFile = ./_secrets.yaml;

  virtualisation.oci-containers.containers = {
    immich-server = {
      image = "ghcr.io/immich-app/immich-server:release";
      autoStart = true;
      networks = [
        "immich_internal"
        "lan_bridge"
      ];
      dependsOn = [
        "redis"
        "database"
      ];
      ports = ["62283:2283"];
      environment = {
        IMMICH_HOST = "0.0.0.0";
      };
      volumes = [
        "${uploadVolumeDir}/immich/library:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];
    };

    immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:release";
      autoStart = true;
      networks = ["immich_internal"];
      volumes = ["model-cache:/cache"];
    };

    redis = {
      image = "docker.io/valkey/valkey:8-bookworm@sha256:fec42f399876eb6faf9e008570597741c87ff7662a54185593e74b09ce83d177";
      autoStart = true;
      networks = ["immich_internal"];
    };

    database = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
      autoStart = true;
      networks = ["immich_internal"];
      environmentFiles = [config.sops.secrets."immich-env".path];
      environment = {
        POSTGRES_INITDB_ARGS = "--data-checksums";
        DB_STORAGE_TYPE = "HDD";
      };
      volumes = [
        "${uploadVolumeDir}/immich/postgres:/var/lib/postgresql/data"
      ];
    };
  };

  systemd.services = {
    "podman-immich-server" = {
      after = ["podman-networks.service"];
      requires = ["podman-networks.service"];
    };
    "podman-immich-machine-learning" = {
      after = ["podman-networks.service"];
      requires = ["podman-networks.service"];
    };
    "podman-redis" = {
      after = ["podman-networks.service"];
      requires = ["podman-networks.service"];
    };
    "podman-database" = {
      after = ["podman-networks.service"];
      requires = ["podman-networks.service"];
    };
  };
}
