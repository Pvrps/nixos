{
  config,
  lib,
  ...
}:
let
  dockerVolumeDir = "/mnt/general/docker";
in
{
  virtualisation.oci-containers.containers = {
    suwayomi = {
      image = "ghcr.io/suwayomi/suwayomi-server:stable";
      autoStart = true;
      networks = [ "lan_bridge" ];
      ports = [ "45126:4567" ];
      environment.TZ = "America/Toronto";
      volumes = [
        "${dockerVolumeDir}/suwayomi/downloads:/home/suwayomi/.local/share/Tachidesk/downloads"
        "${dockerVolumeDir}/suwayomi/data:/home/suwayomi/.local/share/Tachidesk"
      ];
    };
  };

  systemd.services."podman-suwayomi" = {
    after = [ "podman-networks.service" ];
    requires = [ "podman-networks.service" ];
    bindsTo = [ "podman.service" ];
  };
}
