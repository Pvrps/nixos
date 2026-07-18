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
