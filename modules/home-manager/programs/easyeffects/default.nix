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
      ''"bash" "-c" "for i in {1..20}; do ${pkgs.pulseaudio}/bin/pactl list short sources | grep -q 'easyeffects_source' && { ${pkgs.pulseaudio}/bin/pactl set-default-source easyeffects_source; break; }; sleep 0.5; done"''
    ];

    home.activation.linkEasyEffectsPreset = lib.hm.dag.entryAfter ["writeBoundary"] ''
      PRESET_DIR="$HOME/.local/share/easyeffects/input"
      PRESET_FILE="$PRESET_DIR/${cfg.preset}.json"
      PRESET_SOURCE="${cfg.presetSource}"

      mkdir -p "$PRESET_DIR"

      if [ ! -e "$PRESET_FILE" ]; then
        # First install: no live file yet, just copy from Nix store
        cp "$PRESET_SOURCE" "$PRESET_FILE"
        echo "EasyEffects preset installed: $PRESET_FILE"
      else
        # Live file exists: compare hashes to detect local edits
        LIVE_HASH=$(sha256sum "$PRESET_FILE" | awk '{print $1}')
        STORE_HASH=$(sha256sum "$PRESET_SOURCE" | awk '{print $1}')

        if [ "$LIVE_HASH" = "$STORE_HASH" ]; then
          # No local edits: preset is already up to date, nothing to do
          echo "EasyEffects preset up to date."
        else
          # Local edits detected: prompt user
          echo "Warning: EasyEffects preset has local changes."
          printf "Overwrite local changes with Nix store version? [y/N]: "
          read -r -t 30 REPLY </dev/tty || REPLY="N"
          if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
            echo "Please run 'micsave' in your terminal to commit your preset changes, then re-run: home-manager switch"
          else
            echo "Skipping preset update. Run micsave then rebuild to apply git changes."
          fi
        fi
      fi
    '';
  };
}
