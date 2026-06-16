{lib, ...}:
lib.custom.mkScript {
  name = "editing-tool";
  optionName = "capture.edit";
  description = "Image/video editing tool";
  requiresWayland = true;
  keybind = ''Mod+Shift+E { spawn "editing-tool"; }'';
  runtimeInputs = pkgs: with pkgs; [satty wl-clipboard libnotify losslesscut-bin coreutils];
  text = ''
    set -uo pipefail

    LOSSLESSCUT_TMP="''${XDG_RUNTIME_DIR:-/tmp}/losslesscut-tmp"

    OUTPUT_DIR="$HOME/Pictures/Screenshots"
    mkdir -p "$OUTPUT_DIR"
    OUTPUT_FILE="$OUTPUT_DIR/$(date +'%Y-%m-%d_%H-%M-%S')-edited.png"

    run_satty_stdin() {
      satty --filename - --output-filename "$OUTPUT_FILE"
    }

    run_satty_file() {
      local input="$1"
      satty --filename "$input" --output-filename "$OUTPUT_FILE"
    }

    handle_satty_save() {
      if [[ -f "$OUTPUT_FILE" ]]; then
        wl-copy --type image/png < "$OUTPUT_FILE"
        RESULT=$(notify-send \
          --action="copy-path=Copy Path" \
          "Image Saved" "$OUTPUT_FILE")
        if [[ "$RESULT" == "copy-path" ]]; then
          printf '%s' "$OUTPUT_FILE" | wl-copy
        fi
      else
        notify-send "Save Failed" "No image was saved"
      fi
    }

    process_video() {
      local input="$1"
      # shellcheck disable=SC2086
      losslesscut --config-dir "$LOSSLESSCUT_TMP" --settings-json '{"autoSaveProjectFile":false}' -- "$input"
    }

    IMAGE_EXT="png jpg jpeg gif webp"
    VIDEO_EXT="mp4 webm mkv mov avi"

    if wl-paste --type image/png > /dev/null 2>&1; then
      wl-paste --type image/png | run_satty_stdin
      handle_satty_save
      exit 0
    fi

    CLIPBOARD_TEXT=$(wl-paste --type text/plain 2>/dev/null || true)

    if [[ -n "$CLIPBOARD_TEXT" ]]; then
      if [[ -f "$CLIPBOARD_TEXT" ]]; then
        ext="''${CLIPBOARD_TEXT##*.}"
        for e in $IMAGE_EXT; do
          if [[ "$ext" == "$e" ]]; then
            run_satty_file "$CLIPBOARD_TEXT"
            handle_satty_save
            exit 0
          fi
        done
        for e in $VIDEO_EXT; do
          if [[ "$ext" == "$e" ]]; then
            process_video "$CLIPBOARD_TEXT"
            exit 0
          fi
        done
      fi
    fi

    notify-send "Nothing to edit" "No image or video in clipboard"
  '';
  extraConfig.xdg.configFile."satty/config.toml".text = ''
    [general]
    early-exit = true
    copy-command = "wl-copy --type image/png"
    initial-tool = "brush"
    disable-notifications = true
  '';
}
