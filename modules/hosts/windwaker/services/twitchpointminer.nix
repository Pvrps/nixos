{lib, ...}: let
  dockerVolumeDir = "/mnt/docker";

  mkMiner = user: port:
    lib.custom.mkContainer {
      tz = null;
      containerConfig = {
        image = "rdavidoff/twitch-channel-points-miner-v2";
        publishPorts = ["${toString port}:5000"];
        environments = {
          TERM = "xterm-256color";
        };
        volumes = [
          "${dockerVolumeDir}/twitch-points-miner-${user}/analytics:/usr/src/app/analytics"
          "${dockerVolumeDir}/twitch-points-miner-${user}/cookies:/usr/src/app/cookies"
          "${dockerVolumeDir}/twitch-points-miner-${user}/logs:/usr/src/app/logs"
          "${dockerVolumeDir}/twitch-points-miner-${user}/run.py:/usr/src/app/run.py:ro"
        ];
      };
    };
in {
  virtualisation.quadlet.containers = {
    twitch-points-miner-purps = mkMiner "purps" 55000;
    twitch-points-miner-inori = mkMiner "inori" 55001;
  };
}
