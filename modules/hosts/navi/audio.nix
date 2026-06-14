{pkgs, ...}: {
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

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
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 1024;
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
}
