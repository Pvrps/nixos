{
  config,
  lib,
  ...
}: let
  dockerVolumeDir = "/mnt/docker";
in {
  sops.secrets."cwa-env".sopsFile = ./_secrets.yaml;

  virtualisation.quadlet.containers.calibre-web-automated = lib.custom.mkContainer {
    containerConfig = {
      image = "crocodilestick/calibre-web-automated:latest";
      publishPorts = ["28083:8083"];
      # Disable the image's built-in HEALTHCHECK; its transient per-probe
      # systemd unit fails spuriously during startup. See homepage.nix.
      healthCmd = "none";
      environmentFiles = [config.sops.secrets."cwa-env".path];
      environments = {
        PUID = "1000";
        PGID = "1000";
        NETWORK_SHARE_MODE = "false";
        CWA_PORT_OVERRIDE = "8083";
        TRUSTED_PROXY_COUNT = "2";
      };
      volumes = [
        "${dockerVolumeDir}/calibre_web_automated/config:/config"
        "${dockerVolumeDir}/calibre_web_automated/ingest:/cwa-book-ingest"
        "${dockerVolumeDir}/calibre_web_automated/library:/calibre-library"
        "${dockerVolumeDir}/calibre_web_automated/plugins:/config/.config/calibre/plugins"
      ];
    };
  };
}
