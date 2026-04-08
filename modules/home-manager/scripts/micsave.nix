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
    PRESET_FILE="modules/home-manager/programs/easyeffects/blue_yeti.json"

    show_diff() {
      $GIT -C "$CONFIG_DIR" diff "$PRESET_FILE" | $DELTA \
        --diff-so-fancy \
        --width=80 \
        2>/dev/null || return 0
    }

    if ! $GIT -C "$CONFIG_DIR" diff --quiet -- "$PRESET_FILE" 2>/dev/null; then
      echo "Changes detected in EasyEffects preset:"
      echo ""
      show_diff | head -40
      echo ""

      read -p "Commit these changes? (y/n): " -n 1 -r
      echo

      if [[ $REPLY =~ ^[Yy]$ ]]; then
        $GIT -C "$CONFIG_DIR" add -- "$PRESET_FILE"
        $GIT -C "$CONFIG_DIR" commit -m "Update EasyEffects preset"
        $GIT -C "$CONFIG_DIR" push

        echo ""
        echo "✓ Changes committed!"
        echo ""
        echo "To apply: sudo nixos-rebuild switch --flake .#desktop"

        $NOTIFY "MicSave" "Preset changes committed to git"
      else
        echo "Skipped commit."
      fi
    else
      echo "No changes to EasyEffects preset."
      echo "Make sure to Export the preset (three dots > Export) before running micsave."
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