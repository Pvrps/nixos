{
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.micStream;
in {
  options.custom.programs.micStream = {
    enable = lib.mkEnableOption "network microphone stream over PipeWire's native ROC modules (send or receive a mic over the LAN/Tailscale)";

    mode = lib.mkOption {
      type = lib.types.enum ["sender" "receiver"];
      description = ''
        "sender" loads module-roc-sink plus a loopback that captures sourceNode
        into it, streaming to remoteHost. "receiver" loads module-roc-source,
        which shows up as a real Audio/Source node (see nodeName) in the
        PipeWire graph (e.g. for OBS's PipeWire Audio Capture).

        Both ends run inside the PipeWire daemon itself (realtime-scheduled via
        rtkit), unlike external roc-send/roc-recv clients which can be starved
        by CPU-heavy games and glitch the whole audio graph.
      '';
    };

    sourceNode = lib.mkOption {
      type = lib.types.str;
      description = ''
        Sender-only. node.name of the PipeWire source to capture, used as the
        loopback's target.object (e.g. "easyeffects_source" to send
        EasyEffects' processed mic output).
      '';
    };

    remoteHost = lib.mkOption {
      type = lib.types.str;
      description = "Sender-only. Hostname (e.g. Tailscale MagicDNS name) or IP of the receiver.";
    };

    nodeName = lib.mkOption {
      type = lib.types.str;
      description = "Receiver-only. node.name of the Audio/Source node created by module-roc-source.";
    };

    nodeDescription = lib.mkOption {
      type = lib.types.str;
      description = "Receiver-only. Human-readable node.description shown in audio pickers (e.g. OBS's source list).";
    };

    latencyMsec = lib.mkOption {
      type = lib.types.ints.positive;
      default = 100;
      description = "Receiver-only. Target network latency in ms (jitter buffer). Higher is more robust, lower is snappier.";
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
    (lib.mkIf (cfg.mode == "sender") {
      # module-roc-sink creates a sink node that streams whatever is played
      # into it; the loopback pins the mic (sourceNode) to that sink. Both run
      # in-daemon, so game load can't starve the stream and xrun the graph.
      xdg.configFile."pipewire/pipewire.conf.d/94-mic-stream-send.conf".text = ''
        context.modules = [
          {
            name = libpipewire-module-roc-sink
            args = {
              fec.code = rs8m
              remote.ip = "${cfg.remoteHost}"
              remote.source.port = ${toString cfg.ports.source}
              remote.repair.port = ${toString cfg.ports.repair}
              remote.control.port = ${toString cfg.ports.control}
              sink.props = {
                node.name = "mic-stream-roc-sink"
                node.description = "Mic Stream (ROC send to ${cfg.remoteHost})"
                audio.position = [ FL FR ]
              }
            }
          }
          {
            name = libpipewire-module-loopback
            args = {
              node.description = "Mic Stream loopback"
              capture.props = {
                node.name = "mic-stream-loopback-capture"
                node.passive = true
                target.object = "${cfg.sourceNode}"
                stream.dont-remix = true
              }
              playback.props = {
                node.name = "mic-stream-loopback-playback"
                target.object = "mic-stream-roc-sink"
                node.dont-reconnect = true
              }
            }
          }
        ]
      '';
    })

    (lib.mkIf (cfg.mode == "receiver") {
      # module-roc-source creates a real Audio/Source node, directly usable as
      # a mic-like input in OBS -- no null-sink + roc-recv pair needed.
      xdg.configFile."pipewire/pipewire.conf.d/94-mic-stream-recv.conf".text = ''
        context.modules = [
          {
            name = libpipewire-module-roc-source
            args = {
              fec.code = rs8m
              local.ip = 0.0.0.0
              local.source.port = ${toString cfg.ports.source}
              local.repair.port = ${toString cfg.ports.repair}
              local.control.port = ${toString cfg.ports.control}
              sess.latency.msec = ${toString cfg.latencyMsec}
              source.props = {
                node.name = "${cfg.nodeName}"
                node.description = "${cfg.nodeDescription}"
                audio.position = [ FL FR ]
              }
            }
          }
        ]
      '';
    })
  ]);
}
