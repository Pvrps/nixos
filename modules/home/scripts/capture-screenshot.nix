{lib, ...}:
lib.custom.mkScript {
  name = "screenshot-tool";
  optionName = "capture.screenshot";
  description = "Screenshot capture tool";
  requiresWayland = true;
  keybind = ''Mod+Shift+S { spawn "screenshot-tool"; }'';
  runtimeInputs = pkgs: with pkgs; [grim slurp wl-clipboard libnotify coreutils];
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
      noctalia msg screenshot-region
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
