{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.micStream;

  endpointArgs = host: ''-s rtp+rs8m://${host}:${toString cfg.ports.source} -r rs8m://${host}:${toString cfg.ports.repair} -c rtcp://${host}:${toString cfg.ports.control}'';
in {
  options.custom.programs.micStream = {
    enable = lib.mkEnableOption "roc-toolkit based network microphone stream (send or receive a mic over the LAN/Tailscale into PipeWire)";

    mode = lib.mkOption {
      type = lib.types.enum ["sender" "receiver"];
      description = ''
        "sender" captures a local PipeWire/PulseAudio source (see sourceNode) and
        streams it to remoteHost. "receiver" listens for an incoming stream and
        plays it into a dedicated null-sink (see sinkNode) that shows up as its
        own node in the PipeWire graph (e.g. for OBS's PipeWire Audio Capture).
      '';
    };

    sourceNode = lib.mkOption {
      type = lib.types.str;
      description = ''
        Sender-only. Name of the PulseAudio/PipeWire source node to capture,
        passed to roc-send as `pulse://<sourceNode>` (e.g. "easyeffects_source"
        to send EasyEffects' processed mic output).
      '';
    };

    remoteHost = lib.mkOption {
      type = lib.types.str;
      description = "Sender-only. Hostname (e.g. Tailscale MagicDNS name) or IP of the receiver.";
    };

    sinkNode = lib.mkOption {
      type = lib.types.str;
      description = ''
        Receiver-only. node.name of the null-sink created to receive the stream,
        and the name roc-recv plays into via `pulse://<sinkNode>`.
      '';
    };

    sinkDescription = lib.mkOption {
      type = lib.types.str;
      description = "Receiver-only. Human-readable node.description shown in audio pickers (e.g. OBS's source list).";
    };

    # Defaults are shared by sender and receiver ends; the receiving host must
    # allow these UDP ports on its firewall (see navi's host config).
    ports = {
      source = lib.mkOption {
        type = lib.types.port;
        default = 10001;
        description = "UDP port for the RTP source (audio) endpoint.";
      };
      repair = lib.mkOption {
        type = lib.types.port;
        default = 10002;
        description = "UDP port for the FEC repair endpoint.";
      };
      control = lib.mkOption {
        type = lib.types.port;
        default = 10003;
        description = "UDP port for the RTCP control endpoint.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [pkgs.roc-toolkit];
    }

    (lib.mkIf (cfg.mode == "sender") {
      systemd.user.services.roc-send = {
        Unit = {
          Description = "roc-send: stream ${cfg.sourceNode} to ${cfg.remoteHost}";
          After = ["pipewire-pulse.socket"];
          Wants = ["pipewire-pulse.socket"];
        };
        Service = {
          ExecStart = "${pkgs.roc-toolkit}/bin/roc-send -i pulse://${cfg.sourceNode} ${endpointArgs cfg.remoteHost}";
          Restart = "on-failure";
          RestartSec = "2s";
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };
    })

    (lib.mkIf (cfg.mode == "receiver") {
      xdg.configFile."pipewire/pipewire.conf.d/94-${cfg.sinkNode}.conf".text = ''
        context.objects = [
          {
            factory = adapter
            args = {
              factory.name    = support.null-audio-sink
              node.name       = "${cfg.sinkNode}"
              node.description = "${cfg.sinkDescription}"
              media.class     = "Audio/Sink"
              audio.position  = "FL,FR"
            }
          }
        ]
      '';

      systemd.user.services.roc-recv = {
        Unit = {
          Description = "roc-recv: receive mic stream into ${cfg.sinkNode}";
          After = ["pipewire-pulse.socket"];
          Wants = ["pipewire-pulse.socket"];
        };
        Service = {
          ExecStart = "${pkgs.roc-toolkit}/bin/roc-recv -o pulse://${cfg.sinkNode} -s rtp+rs8m://0.0.0.0:${toString cfg.ports.source} -r rs8m://0.0.0.0:${toString cfg.ports.repair} -c rtcp://0.0.0.0:${toString cfg.ports.control}";
          Restart = "on-failure";
          RestartSec = "2s";
        };
        Install = {
          WantedBy = ["default.target"];
        };
      };
    })
  ]);
}
