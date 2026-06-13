{
  config,
  ...
}:
let
  dockerVolumeDir = "/mnt/docker";
in
{
  sops.secrets."cwa-env".sopsFile = ./_secrets.yaml;

  virtualisation.quadlet.containers.calibre-web-automated = {
    autoStart = true;
    containerConfig = {
      image = "crocodilestick/calibre-web-automated:latest";
      networks = [ "lan_bridge" ];
      publishPorts = [ "28083:8083" ];
      environmentFiles = [ config.sops.secrets."cwa-env".path ];
      environments = {
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
    unitConfig.RequiresMountsFor = ["/mnt/docker"];
    serviceConfig = {
      Restart = "always";
      RestartSec = "10";
    };
  };
}
