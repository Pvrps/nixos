{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.scripts.micsave;
  micsave = pkgs.writeShellScriptBin "micsave" ''
    set -euo pipefail

    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    GIT="${pkgs.git}/bin/git"
    DELTA="${pkgs.delta}/bin/delta"

    CONFIG_DIR="/persist/etc/nixos"
    PRESET_FILE="modules/home-manager/programs/easyeffects/${config.custom.programs.easyeffects.preset}.json"
    LIVE_PRESET="$HOME/.local/share/easyeffects/input/${config.custom.programs.easyeffects.preset}.json"

    if [[ ! -f "$LIVE_PRESET" ]]; then
      echo "Live preset not found at $LIVE_PRESET. Is EasyEffects installed and has it been run at least once?"
      exit 1
    fi

    GIT_PRESET_PATH="$CONFIG_DIR/$PRESET_FILE"

    if [ ! -f "$GIT_PRESET_PATH" ]; then
      GIT_SUM=""
    else
      GIT_SUM=$(sha256sum "$GIT_PRESET_PATH"); GIT_SUM=''${GIT_SUM%% *}
    fi
    LIVE_SUM=$(sha256sum "$LIVE_PRESET"); LIVE_SUM=''${LIVE_SUM%% *}

    if [[ "$LIVE_SUM" != "$GIT_SUM" ]]; then
      echo "Changes detected in EasyEffects preset:"
      echo ""
      $GIT -C "$CONFIG_DIR" diff --no-index "$GIT_PRESET_PATH" "$LIVE_PRESET" | $DELTA \
        --width=80 \
        2>/dev/null || true
      echo ""

      read -p "Commit these changes? (y/n): " -n 1 -r
      echo

      if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$LIVE_PRESET" "$GIT_PRESET_PATH"
        chmod 644 "$GIT_PRESET_PATH"
        $GIT -C "$CONFIG_DIR" add -- "$PRESET_FILE"
        $GIT -C "$CONFIG_DIR" commit -m "Update EasyEffects preset"

        echo ""
        echo "✓ Changes committed!"
        echo ""
        echo "To apply: sudo nixos-rebuild switch --flake .#desktop"

        $NOTIFY "MicSave" "Preset changes committed to git"
      else
        echo "Skipped."
      fi
    else
      echo "No changes to EasyEffects preset."
      $NOTIFY "MicSave" "No changes detected"
    fi
  '';
in {
  options.custom.scripts.micsave.enable = lib.mkEnableOption "MicSave EasyEffects preset commit tool";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.easyeffects.enable;
        message = "micsave requires easyeffects to be enabled (custom.programs.easyeffects.enable = true).";
      }
    ];

    home.packages = [micsave pkgs.delta];
  };
}
