# PipeWire audio. `enable` is the plain stack; `lowLatency.enable` layers
# rtkit, low-latency quantum settings, and a virtual cable sink on top.
{
  config,
  lib,
  ...
}: let
  cfg = config.custom.audio;
in {
  options.custom.audio = {
    enable = lib.mkEnableOption "PipeWire audio stack";
    lowLatency.enable =
      lib.mkEnableOption "Low-latency PipeWire settings with a virtual cable sink";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.lowLatency.enable {
      custom.audio.enable = true;
    })

    (lib.mkIf cfg.enable {
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };
    })

    (lib.mkIf cfg.lowLatency.enable {
      security.rtkit.enable = true;

      # Allow user services (EasyEffects) to raise their scheduling
      # priority to Nice=-11 so DSP worker threads (DeepFilterNet) keep
      # up when a game saturates the CPU. Without this, systemd --user
      # cannot apply a negative Nice= (RLIMIT_NICE defaults to 0).
      security.pam.loginLimits = [
        {
          domain = "@users";
          item = "nice";
          type = "-";
          value = "-11";
        }
      ];

      services.pipewire = {
        wireplumber = {
          enable = true;
          extraConfig = {
            "10-disable-suspension" = {
              "monitor.alsa.rules" = [
                {
                  matches = [
                    {"node.name" = "~alsa_input.*";}
                    {"node.name" = "~alsa_output.*";}
                  ];
                  actions = {
                    update-props = {
                      "session.suspend-timeout-seconds" = 0;
                    };
                  };
                }
              ];
            };
          };
        };

        extraConfig.pipewire = {
          "92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.quantum" = 512;
              "default.clock.min-quantum" = 512;
              "default.clock.max-quantum" = 2048;
              # Run two RT data loops so a heavy filter chain (e.g.
              # DeepFilterNet on the mic path, kept hot 24/7 by roc-send)
              # cannot stall the output driver's cycle and crackle all
              # audio system-wide. Zero latency cost.
              "context.num-data-loops" = 2;
            };
          };
          "93-virtual-cable" = {
            "context.objects" = [
              {
                factory = "adapter";
                args = {
                  "factory.name" = "support.null-audio-sink";
                  "node.name" = "virtual-audio-sink-1";
                  "node.description" = "Virtual Cable 1";
                  "media.class" = "Audio/Sink";
                  "audio.position" = "FL,FR";
                };
              }
            ];
          };
        };
      };
    })
  ];
}
