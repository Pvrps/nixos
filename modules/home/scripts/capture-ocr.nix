{lib, ...}:
lib.custom.mkScript {
  name = "ocr-tool";
  optionName = "capture.ocr";
  description = "Screen region OCR tool";
  requiresWayland = true;
  keybind = ''Mod+Shift+O { spawn "ocr-tool"; }'';
  runtimeInputs = pkgs: with pkgs; [slurp grim tesseract wl-clipboard libnotify coreutils];
  text = ''
    set -uo pipefail

    if AREA=$(slurp); then
      TEXT=$(grim -g "$AREA" - | tesseract stdin stdout 2>/dev/null || true)
      if [[ -n "$TEXT" ]]; then
        printf '%s' "$TEXT" | wl-copy
        LINE_COUNT=$(printf '%s' "$TEXT" | wc -l)
        CHAR_COUNT=$(printf '%s' "$TEXT" | wc -c)
        notify-send "OCR Complete" "Copied $LINE_COUNT lines ($CHAR_COUNT chars) to clipboard"
      else
        notify-send "OCR Failed" "No text could be extracted from the selected region"
      fi
    fi
  '';
}
