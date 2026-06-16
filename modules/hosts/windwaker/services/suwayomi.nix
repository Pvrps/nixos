{lib, ...}: let
  dockerVolumeDir = "/mnt/docker";
in {
  virtualisation.quadlet.containers.suwayomi = lib.custom.mkContainer {
    containerConfig = {
      image = "ghcr.io/suwayomi/suwayomi-server:stable";
      publishPorts = ["45126:4567"];
      volumes = [
        "${dockerVolumeDir}/suwayomi/downloads:/home/suwayomi/.local/share/Tachidesk/downloads"
        "${dockerVolumeDir}/suwayomi/data:/home/suwayomi/.local/share/Tachidesk"
      ];
    };
  };
}
