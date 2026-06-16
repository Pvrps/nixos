{lib, ...}:
lib.custom.mkScript {
  name = "screenshot-tool";
  optionName = "capture.screenshot";
  description = "Screenshot capture tool";
  requiresWayland = true;
  keybind = ''Mod+Shift+S { spawn "screenshot-tool"; }'';
  runtimeInputs = pkgs: with pkgs; [grim slurp wl-clipboard libnotify coreutils];
  text = ''
    set -uo pipefail

    DIR="$HOME/Pictures/Screenshots"
    mkdir -p "$DIR"
    FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

    if AREA=$(slurp); then
      grim -g "$AREA" - | tee "$FILE" | wl-copy
      RESULT=$(notify-send \
        --action="copy-path=Copy Path" \
        "Screenshot Saved" "$FILE")
      if [ "$RESULT" = "copy-path" ]; then
        printf '%s' "$FILE" | wl-copy
      fi
    fi
  '';
}
