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
    JQ="${pkgs.jq}/bin/jq"

    CONFIG_DIR="/persist/etc/nixos"
    GIT_PRESET_PATH="${cfg.presetGitPath}"
    LIVE_PRESET="$HOME/.local/share/easyeffects/input/${config.custom.programs.easyeffects.preset}.json"

    if [[ ! -f "$LIVE_PRESET" ]]; then
      echo "Live preset not found at $LIVE_PRESET. Is EasyEffects installed and has it been run at least once?"
      exit 1
    fi

    if [ ! -f "$GIT_PRESET_PATH" ]; then
      GIT_SUM=""
    else
      GIT_SUM=$($JQ --sort-keys . "$GIT_PRESET_PATH" | sha256sum); GIT_SUM=''${GIT_SUM%% *}
    fi
    LIVE_SUM=$($JQ --sort-keys . "$LIVE_PRESET" | sha256sum); LIVE_SUM=''${LIVE_SUM%% *}

    if [[ "$LIVE_SUM" != "$GIT_SUM" ]]; then
      echo "Changes detected in EasyEffects preset:"
      echo ""

      TMP_GIT=$(mktemp /tmp/micsave-git-XXXXXX.json)
      TMP_LIVE=$(mktemp /tmp/micsave-live-XXXXXX.json)
      trap "rm -f $TMP_GIT $TMP_LIVE" EXIT

      $JQ --sort-keys . "$GIT_PRESET_PATH" > "$TMP_GIT"
      $JQ --sort-keys . "$LIVE_PRESET" > "$TMP_LIVE"

      $GIT -C "$CONFIG_DIR" diff --no-index "$TMP_GIT" "$TMP_LIVE" \
        | $DELTA \
            --diff-so-fancy \
            --width=80 \
            2>/dev/null || true

      rm -f "$TMP_GIT" "$TMP_LIVE"
      trap - EXIT

      echo ""
      read -p "Commit these changes? (y/n): " -n 1 -r
      echo

      if [[ $REPLY =~ ^[Yy]$ ]]; then
        $JQ --sort-keys . "$LIVE_PRESET" > "$GIT_PRESET_PATH"
        chmod 644 "$GIT_PRESET_PATH"
        $GIT -C "$CONFIG_DIR" add -- "$GIT_PRESET_PATH"
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
  options.custom.scripts.micsave = {
    enable = lib.mkEnableOption "MicSave EasyEffects preset commit tool";
    presetGitPath = lib.mkOption {
      type = lib.types.str;
      description = "Absolute string path to the preset file in the git repo. Must be a string, not a Nix path, to remain writable.";
    };
  };

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
