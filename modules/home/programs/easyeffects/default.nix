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
        type = lib.types.str;
        description = "Absolute string path to the EasyEffects preset JSON file";
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

      if [ -L "$PRESET_FILE" ]; then
        # It's a symlink from a previous generation — replace with a real copy unconditionally
        rm -f "$PRESET_FILE"
        cp "$PRESET_SOURCE" "$PRESET_FILE"
        chmod 644 "$PRESET_FILE"
        echo "EasyEffects preset migrated from symlink to writable copy: $PRESET_FILE"
      elif [ ! -e "$PRESET_FILE" ]; then
        # First install: no live file yet, just copy from Nix store
        cp "$PRESET_SOURCE" "$PRESET_FILE"
        chmod 644 "$PRESET_FILE"
        echo "EasyEffects preset installed: $PRESET_FILE"
      else
        # Live file exists as a real file: compare hashes to detect local edits
        LIVE_HASH=$(sha256sum "$PRESET_FILE"); LIVE_HASH=''${LIVE_HASH%% *}
        STORE_HASH=$(sha256sum "$PRESET_SOURCE"); STORE_HASH=''${STORE_HASH%% *}

        if [ "$LIVE_HASH" = "$STORE_HASH" ]; then
          # No local edits: preset is already up to date, nothing to do
          echo "EasyEffects preset up to date."
        else
          # Local edits detected: leave the live file alone
          echo "EasyEffects preset has local changes — skipping update. Run micsave to commit them."
        fi
      fi
    '';
  };
}
