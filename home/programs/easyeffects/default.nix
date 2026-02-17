{
  pkgs,
  lib,
  ...
}: {
  services.easyeffects = {
    enable = true;
    preset = "blue_yeti";
  };

  home.packages = [pkgs.easyeffects];

  home.activation.linkEasyEffectsPreset = lib.hm.dag.entryAfter ["writeBoundary"] ''
    PRESET_DIR="$HOME/.local/share/easyeffects/input"
    PRESET_LINK="$PRESET_DIR/blue_yeti.json"
    PRESET_SOURCE="/persist/etc/nixos/home/programs/easyeffects/blue_yeti.json"

    mkdir -p "$PRESET_DIR"

    if [ -e "$PRESET_LINK" ] || [ -L "$PRESET_LINK" ]; then
      rm -f "$PRESET_LINK"
    fi

    ln -sf "$PRESET_SOURCE" "$PRESET_LINK"

    echo "EasyEffects preset linked: $PRESET_LINK -> $PRESET_SOURCE"
  '';
}
