{lib, ...}:
lib.custom.mkScript {
  name = "screenshot-tool";
  optionName = "capture.screenshot";
  description = "Screenshot capture tool";
  requiresWayland = true;
  keybind = ''Mod+Shift+S { spawn "screenshot-tool"; }'';
  runtimeInputs = pkgs: with pkgs; [grim slurp wl-clipboard libnotify inotify-tools coreutils];
  # Function form (see lib.custom.mkScript docs): keeps `config` access lazy,
  # evaluated only when the tool derivation is actually built, instead of
  # forcing it while the module system is still discovering imports.
  text = {config, ...}: let
    # Noctalia already exposes region-capture + save/clipboard via
    # [shell.screenshot] IPC (see modules/home/programs/desktop/noctalia.nix);
    # defer to it there instead of duplicating that logic with grim/slurp.
    useNoctalia = config.custom.programs.noctalia.enable;
  in
    if useNoctalia
    then ''
      set -uo pipefail

      DIR="$HOME/Pictures/Screenshots"
      mkdir -p "$DIR"

      noctalia msg screenshot-region

      # Noctalia's own [shell.screenshot] settings already save + copy the
      # PNG; it doesn't expose a "screenshot taken" hook to chain our own
      # notification action off of (checked docs.noctalia.dev/noctalia/
      # automation/hooks/ — no such event). Watch the directory for the new
      # file instead, so we can still offer a "Copy Path" button. Times out
      # quietly if the region select is cancelled (no file ever appears).
      FILE=$(inotifywait -q -e create,moved_to --format '%w%f' -t 30 "$DIR" 2>/dev/null || true)
      if [[ -n "$FILE" && -f "$FILE" ]]; then
        RESULT=$(notify-send \
          --action="copy-path=Copy Path" \
          "Screenshot Saved" "$FILE")
        if [ "$RESULT" = "copy-path" ]; then
          printf '%s' "$FILE" | wl-copy
        fi
      fi
    ''
    else ''
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
