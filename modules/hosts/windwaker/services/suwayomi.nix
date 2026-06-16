_: let
  dockerVolumeDir = "/mnt/docker";
in {
  virtualisation.quadlet.containers.suwayomi = {
    autoStart = true;
    containerConfig = {
      image = "ghcr.io/suwayomi/suwayomi-server:stable";
      networks = ["lan_bridge"];
      publishPorts = ["45126:4567"];
      environments = {
        TZ = "America/Toronto";
      };
      volumes = [
        "${dockerVolumeDir}/suwayomi/downloads:/home/suwayomi/.local/share/Tachidesk/downloads"
        "${dockerVolumeDir}/suwayomi/data:/home/suwayomi/.local/share/Tachidesk"
      ];
    };
    unitConfig.RequiresMountsFor = ["/mnt/docker"];
    serviceConfig = {
      Restart = "always";
      RestartSec = "10";
    };
  };
}
