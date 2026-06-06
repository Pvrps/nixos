{
  ...
}:
let
  dockerVolumeDir = "/mnt/general/docker";
in
{
  virtualisation.quadlet.containers = {
    twitch-points-miner-purps = {
      autoStart = true;
      containerConfig = {
        image = "rdavidoff/twitch-channel-points-miner-v2";
        networks = [ "lan_bridge" ];
        publishPorts = [ "55000:5000" ];
        environments = {
          TERM = "xterm-256color";
        };
        volumes = [
          "${dockerVolumeDir}/twitch-points-miner-purps/analytics:/usr/src/app/analytics"
          "${dockerVolumeDir}/twitch-points-miner-purps/cookies:/usr/src/app/cookies"
          "${dockerVolumeDir}/twitch-points-miner-purps/logs:/usr/src/app/logs"
          "${dockerVolumeDir}/twitch-points-miner-purps/run.py:/usr/src/app/run.py:ro"
        ];
      };
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };
    };

    twitch-points-miner-inori = {
      autoStart = true;
      containerConfig = {
        image = "rdavidoff/twitch-channel-points-miner-v2";
        networks = [ "lan_bridge" ];
        publishPorts = [ "55001:5000" ];
        environments = {
          TERM = "xterm-256color";
        };
        volumes = [
          "${dockerVolumeDir}/twitch-points-miner-inori/analytics:/usr/src/app/analytics"
          "${dockerVolumeDir}/twitch-points-miner-inori/cookies:/usr/src/app/cookies"
          "${dockerVolumeDir}/twitch-points-miner-inori/logs:/usr/src/app/logs"
          "${dockerVolumeDir}/twitch-points-miner-inori/run.py:/usr/src/app/run.py:ro"
        ];
      };
      serviceConfig = {
        Restart = "always";
        RestartSec = "10";
      };
    };
  };
}
