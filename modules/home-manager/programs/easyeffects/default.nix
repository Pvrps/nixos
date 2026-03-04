{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.custom.programs.easyeffects;
in {
  options.custom.programs.easyeffects.enable = lib.mkEnableOption "EasyEffects audio processor";

  config = lib.mkIf cfg.enable {
    services.easyeffects = {
      enable = true;
      inherit (config.custom.easyeffects) preset;
    };

    home.packages = [pkgs.easyeffects];

    custom.niri.startupCommands = [
      ''"bash" "-c" "for i in {1..20}; do ${pkgs.pulseaudio}/bin/pactl list short sources | grep -q 'rnnoise_source' && { ${pkgs.pulseaudio}/bin/pactl set-default-source rnnoise_source; break; }; sleep 0.5; done"''
    ];

    home.activation.linkEasyEffectsPreset = lib.hm.dag.entryAfter ["writeBoundary"] ''
      PRESET_DIR="$HOME/.local/share/easyeffects/input"
      PRESET_LINK="$PRESET_DIR/${config.custom.easyeffects.preset}.json"
      PRESET_SOURCE="${config.custom.easyeffects.presetSource}"

      mkdir -p "$PRESET_DIR"

      if [ -e "$PRESET_LINK" ] || [ -L "$PRESET_LINK" ]; then
        rm -f "$PRESET_LINK"
      fi

      ln -sf "$PRESET_SOURCE" "$PRESET_LINK"

      echo "EasyEffects preset linked: $PRESET_LINK -> $PRESET_SOURCE"
    '';
  };
}
