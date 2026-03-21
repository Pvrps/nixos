{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.custom.programs.easyeffects;
in {
  options.custom = {
    programs.easyeffects = {
      enable = lib.mkEnableOption "EasyEffects audio processor";
      preset = lib.mkOption {
        type = lib.types.str;
        default = "blue_yeti";
        description = "EasyEffects preset name";
      };
      presetSource = lib.mkOption {
        type = lib.types.path;
        description = "Path to the EasyEffects preset JSON file";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.easyeffects = {
      enable = true;
      inherit (cfg) preset;
    };

    home.packages = [pkgs.easyeffects];

    custom.programs.niri.startupCommands = [
      ''"bash" "-c" "for i in {1..20}; do ${pkgs.pulseaudio}/bin/pactl list short sources | grep -q 'rnnoise_source' && { ${pkgs.pulseaudio}/bin/pactl set-default-source rnnoise_source; break; }; sleep 0.5; done"''
    ];

    home.activation.linkEasyEffectsPreset = lib.hm.dag.entryAfter ["writeBoundary"] ''
      PRESET_DIR="$HOME/.local/share/easyeffects/input"
      PRESET_LINK="$PRESET_DIR/${cfg.preset}.json"
      PRESET_SOURCE="${cfg.presetSource}"

      mkdir -p "$PRESET_DIR"

      if [ -e "$PRESET_LINK" ] || [ -L "$PRESET_LINK" ]; then
        rm -f "$PRESET_LINK"
      fi

      ln -sf "$PRESET_SOURCE" "$PRESET_LINK"

      echo "EasyEffects preset linked: $PRESET_LINK -> $PRESET_SOURCE"
    '';
  };
}
