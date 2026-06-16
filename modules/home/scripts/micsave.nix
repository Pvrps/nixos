{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.scripts.micsave;
  micsave = pkgs.writeShellApplication {
    name = "micsave";
    runtimeInputs = with pkgs; [libnotify git delta jq coreutils];
    text = ''
      CONFIG_DIR="${cfg.configDir}"
      GIT_PRESET_PATH="${cfg.presetGitPath}"
      LIVE_PRESET="$HOME/.local/share/easyeffects/input/${config.custom.programs.easyeffects.preset}.json"

      if [[ ! -f "$LIVE_PRESET" ]]; then
        echo "Live preset not found at $LIVE_PRESET. Is EasyEffects installed and has it been run at least once?"
        exit 1
      fi

      if [ ! -f "$GIT_PRESET_PATH" ]; then
        GIT_SUM=""
      else
        GIT_SUM=$(jq --sort-keys . "$GIT_PRESET_PATH" | sha256sum); GIT_SUM=''${GIT_SUM%% *}
      fi
      LIVE_SUM=$(jq --sort-keys . "$LIVE_PRESET" | sha256sum); LIVE_SUM=''${LIVE_SUM%% *}

      if [[ "$LIVE_SUM" != "$GIT_SUM" ]]; then
        echo "Changes detected in EasyEffects preset:"
        echo ""

        TMP_DIR=$(mktemp -d "''${XDG_RUNTIME_DIR:-/tmp}/micsave-XXXXXX")
        TMP_GIT="$TMP_DIR/git.json"
        TMP_LIVE="$TMP_DIR/live.json"
        trap 'rm -rf "$TMP_DIR"' EXIT

        jq --sort-keys . "$GIT_PRESET_PATH" > "$TMP_GIT"
        jq --sort-keys . "$LIVE_PRESET" > "$TMP_LIVE"

        git -C "$CONFIG_DIR" diff --no-index "$TMP_GIT" "$TMP_LIVE" \
          | delta \
              --diff-so-fancy \
              --width=80 \
              2>/dev/null || true

        echo ""
        read -p "Commit these changes? (y/n): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
          jq --sort-keys . "$LIVE_PRESET" > "$GIT_PRESET_PATH"
          chmod 644 "$GIT_PRESET_PATH"
          git -C "$CONFIG_DIR" add -- "$GIT_PRESET_PATH"
          git -C "$CONFIG_DIR" commit -m "Update EasyEffects preset"

          echo ""
          echo "✓ Changes committed!"

          notify-send "MicSave" "Preset changes committed to git"
        else
          echo "Skipped."
        fi
      else
        echo "No changes to EasyEffects preset."
        notify-send "MicSave" "No changes detected"
      fi
    '';
  };
in {
  options.custom.scripts.micsave = {
    enable = lib.mkEnableOption "MicSave EasyEffects preset commit tool";
    presetGitPath = lib.mkOption {
      type = lib.types.str;
      description = "Absolute string path to the preset file in the git repo. Must be a string, not a Nix path, to remain writable.";
    };
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/persist/etc/nixos";
      description = "Path to the NixOS config git repository.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.easyeffects.enable;
        message = "micsave requires easyeffects to be enabled (custom.programs.easyeffects.enable = true).";
      }
    ];

    home.packages = [micsave];
  };
}
