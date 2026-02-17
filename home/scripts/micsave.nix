{pkgs, ...}: let
  micsave = pkgs.writeShellScriptBin "micsave" ''
    set -euo pipefail

    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    GIT="${pkgs.git}/bin/git"

    CONFIG_DIR="/persist/etc/nixos"
    PRESET_FILE="home/programs/easyeffects/blue_yeti.json"

    if ! $GIT -C "$CONFIG_DIR" diff --quiet -- "$PRESET_FILE" 2>/dev/null; then
      echo "Changes detected in EasyEffects preset:"
      echo ""
      $GIT -C "$CONFIG_DIR" diff -- "$PRESET_FILE" | head -20
      echo ""

      read -p "Commit these changes? (y/n): " -n 1 -r
      echo

      if [[ $REPLY =~ ^[Yy]$ ]]; then
        $GIT -C "$CONFIG_DIR" add -- "$PRESET_FILE"
        $GIT -C "$CONFIG_DIR" commit -m "Update EasyEffects preset"

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
      $NOTIFY "MicSave" "No changes detected"
    fi
  '';
in {
  home.packages = [micsave];
}
