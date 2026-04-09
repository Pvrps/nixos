{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.scripts.capture.screenshot;
  screenshot-tool = pkgs.writeShellScriptBin "screenshot-tool" ''
    DIR="$HOME/Pictures/Screenshots"
    mkdir -p "$DIR"
    FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').png"

    if AREA=$(${pkgs.slurp}/bin/slurp); then
      ${pkgs.grim}/bin/grim -g "$AREA" - | tee "$FILE" | ${pkgs.wl-clipboard}/bin/wl-copy
      RESULT=$(${pkgs.libnotify}/bin/notify-send \
        --action="copy-path=Copy Path" \
        "Screenshot Saved" "$FILE")
      if [ "$RESULT" = "copy-path" ]; then
        printf '%s' "$FILE" | ${pkgs.wl-clipboard}/bin/wl-copy
      fi
    fi
  '';
in {
  options.custom.scripts.capture.screenshot.enable = lib.mkEnableOption "Screenshot capture tool";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.system.wayland.enable;
        message = "capture-screenshot requires a Wayland compositor (uses grim, slurp, wl-clipboard).";
      }
    ];

    home.packages = [
      screenshot-tool
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
      pkgs.libnotify
    ];

    custom.programs.niri.keybinds = [
      ''Mod+Shift+S { spawn "screenshot-tool"; }''
    ];
  };
}