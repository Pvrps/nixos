{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.rnnoise-plugin
  ];

  systemd.user.services.rnnoise = {
    description = "Noise Canceling Source";
    wantedBy = ["default.target"];
    after = ["pipewire.service"];
    bindsTo = ["pipewire.service"];
    serviceConfig = {
      ExecStart = "${pkgs.pipewire}/bin/pipewire -c ${pkgs.writeText "rnnoise.conf" ''
        context.properties = {
          log.level = 0
        }

        context.spa-libs = {
          audio.convert.* = audioconvert/libspa-audioconvert
          support.* = support/libspa-support
        }

        context.modules = [
          { name = libpipewire-module-protocol-native }
          { name = libpipewire-module-client-node }
          { name = libpipewire-module-adapter }

          { name = libpipewire-module-filter-chain
            args = {
              node.description = "Filtered"
              media.name = "Filtered"
              filter.graph = {
                nodes = [
                  {
                    type = ladspa
                    name = rnnoise
                    plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so"
                    label = noise_suppressor_mono
                    control = {
                      "VAD Threshold (%)" = 50.0
                      "VAD Grace Period (ms)" = 200
                      "Retroactive VAD Grace (ms)" = 0
                    }
                  }
                ]
              }
              capture.props = {
                node.passive = true
                node.target = "alsa_input.usb-Generic_Blue_Microphones_201701110001-00.analog-stereo"
              }
              playback.props = {
                media.class = Audio/Source
              }
            }
          }
        ]
      ''}";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
