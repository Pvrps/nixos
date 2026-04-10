{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.scripts.capture.edit;
  editing-tool = pkgs.writeShellScriptBin "editing-tool" ''
    set -uo pipefail

    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    WL_PASTE="${pkgs.wl-clipboard}/bin/wl-paste"
    WL_COPY="${pkgs.wl-clipboard}/bin/wl-copy"
    SATTY="${pkgs.satty}/bin/satty"
    LOSSLESSCUT="${pkgs.losslesscut-bin}/bin/losslesscut --config-dir /tmp/losslesscut-tmp --settings-json '{\"autoSaveProjectFile\":false}' --"

    OUTPUT_DIR="$HOME/Pictures/Screenshots"
    mkdir -p "$OUTPUT_DIR"
    OUTPUT_FILE="$OUTPUT_DIR/$(date +'%Y-%m-%d_%H-%M-%S')-edited.png"

    run_satty_stdin() {
      $SATTY --filename - --output-filename "$OUTPUT_FILE"
    }

    run_satty_file() {
      local input="$1"
      $SATTY --filename "$input" --output-filename "$OUTPUT_FILE"
    }

    handle_satty_save() {
      if [[ -f "$OUTPUT_FILE" ]]; then
        $WL_COPY --type image/png < "$OUTPUT_FILE"
        RESULT=$($NOTIFY \
          --action="copy-path=Copy Path" \
          "Image Saved" "$OUTPUT_FILE")
        if [[ "$RESULT" == "copy-path" ]]; then
          printf '%s' "$OUTPUT_FILE" | $WL_COPY
        fi
      else
        $NOTIFY "Save Failed" "No image was saved"
      fi
    }

    process_video() {
      local input="$1"
      $LOSSLESSCUT "$input"
    }

    IMAGE_EXT="png jpg jpeg gif webp"
    VIDEO_EXT="mp4 webm mkv mov avi"

    if $WL_PASTE --type image/png > /dev/null 2>&1; then
      $WL_PASTE --type image/png | run_satty_stdin
      handle_satty_save
      exit 0
    fi

    CLIPBOARD_TEXT=$($WL_PASTE --type text/plain 2>/dev/null || true)

    if [[ -n "$CLIPBOARD_TEXT" ]]; then
      if [[ -f "$CLIPBOARD_TEXT" ]]; then
        ext="''${CLIPBOARD_TEXT##*.}"
        for e in ''$IMAGE_EXT; do
          if [[ "$ext" == "$e" ]]; then
            run_satty_file "$CLIPBOARD_TEXT"
            handle_satty_save
            exit 0
          fi
        done
        for e in ''$VIDEO_EXT; do
          if [[ "$ext" == "$e" ]]; then
            process_video "$CLIPBOARD_TEXT"
            exit 0
          fi
        done
      fi
    fi

    $NOTIFY "Nothing to edit" "No image or video in clipboard"
  '';
in {
  options.custom.scripts.capture.edit.enable = lib.mkEnableOption "Image/video editing tool";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.system.wayland.enable;
        message = "capture-edit requires a Wayland compositor (uses satty, wl-clipboard).";
      }
    ];

    home.packages = [
      editing-tool
      pkgs.satty
      pkgs.wl-clipboard
      pkgs.libnotify
      pkgs.losslesscut-bin
    ];

    xdg.configFile."satty/config.toml" = {
      text = ''
        [general]
        early-exit = true
        copy-command = "wl-copy --type image/png"
        initial-tool = "brush"
        disable-notifications = true
      '';
    };

    custom.programs.niri.keybinds = [
      ''Mod+Shift+E { spawn "editing-tool"; }''
    ];
  };
}
