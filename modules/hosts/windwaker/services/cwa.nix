{
  config,
  lib,
  ...
}:
let
  dockerVolumeDir = "/mnt/general/docker";
in
{
  sops.secrets."cwa-env".sopsFile = ./_secrets.yaml;

  virtualisation.oci-containers.containers = {
    calibre-web-automated = {
      image = "crocodilestick/calibre-web-automated:latest";
      autoStart = true;
      networks = [ "lan_bridge" ];
      ports = [ "28083:8083" ];
      environmentFiles = [ config.sops.secrets."cwa-env".path ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Toronto";
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

  systemd.services."podman-calibre-web-automated" = {
    after = [ "podman-networks.service" ];
    requires = [ "podman-networks.service" ];
    bindsTo = [ "podman.service" ];
  };
}
