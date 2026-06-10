{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.scripts.capture.ocr;
  ocr-tool = pkgs.writeShellScriptBin "ocr-tool" ''
    set -uo pipefail

    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    WL_COPY="${pkgs.wl-clipboard}/bin/wl-copy"

    if AREA=$(${pkgs.slurp}/bin/slurp); then
      TEXT=$(${pkgs.grim}/bin/grim -g "$AREA" - | ${pkgs.tesseract}/bin/tesseract stdin stdout 2>/dev/null || true)
      if [[ -n "$TEXT" ]]; then
        printf '%s' "$TEXT" | $WL_COPY
        LINE_COUNT=$(printf '%s' "$TEXT" | wc -l)
        CHAR_COUNT=$(printf '%s' "$TEXT" | wc -c)
        $NOTIFY "OCR Complete" "Copied $LINE_COUNT lines ($CHAR_COUNT chars) to clipboard"
      else
        $NOTIFY "OCR Failed" "No text could be extracted from the selected region"
      fi
    fi
  '';
in {
  options.custom.scripts.capture.ocr.enable = lib.mkEnableOption "Screen region OCR tool";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.system.wayland.enable;
        message = "ocr requires a Wayland compositor (uses grim, slurp, wl-clipboard).";
      }
    ];

    home.packages = [
      ocr-tool
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
      pkgs.libnotify
      pkgs.tesseract
    ];

    custom.programs.niri.keybinds = [
      ''Mod+Shift+O { spawn "ocr-tool"; }''
    ];
  };
}
