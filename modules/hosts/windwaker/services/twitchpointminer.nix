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
    twitch-points-miner-purps = {
      image = "rdavidoff/twitch-channel-points-miner-v2";
      autoStart = true;
      networks = [ "lan_bridge" ];
      ports = [ "55000:5000" ];
      environment.TERM = "xterm-256color";
      volumes = [
        "${dockerVolumeDir}/twitch-points-miner-purps/analytics:/usr/src/app/analytics"
        "${dockerVolumeDir}/twitch-points-miner-purps/cookies:/usr/src/app/cookies"
        "${dockerVolumeDir}/twitch-points-miner-purps/logs:/usr/src/app/logs"
        "${dockerVolumeDir}/twitch-points-miner-purps/run.py:/usr/src/app/run.py:ro"
      ];
    };

    twitch-points-miner-inori = {
      image = "rdavidoff/twitch-channel-points-miner-v2";
      autoStart = true;
      networks = [ "lan_bridge" ];
      ports = [ "55001:5000" ];
      environment.TERM = "xterm-256color";
      volumes = [
        "${dockerVolumeDir}/twitch-points-miner-inori/analytics:/usr/src/app/analytics"
        "${dockerVolumeDir}/twitch-points-miner-inori/cookies:/usr/src/app/cookies"
        "${dockerVolumeDir}/twitch-points-miner-inori/logs:/usr/src/app/logs"
        "${dockerVolumeDir}/twitch-points-miner-inori/run.py:/usr/src/app/run.py:ro"
      ];
    };
  };

  systemd.services = {
    "podman-twitch-points-miner-purps" = {
      after = [ "podman-networks.service" ];
      requires = [ "podman-networks.service" ];
      bindsTo = [ "podman.service" ];
    };
    "podman-twitch-points-miner-inori" = {
      after = [ "podman-networks.service" ];
      requires = [ "podman-networks.service" ];
      bindsTo = [ "podman.service" ];
    };
  };
}
