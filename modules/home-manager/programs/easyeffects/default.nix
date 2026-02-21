{
  config,
  pkgs,
  lib,
  ...
}: {
  services.easyeffects = {
    enable = true;
    preset = config.custom.easyeffects.preset;
  };

  home.packages = [pkgs.easyeffects];

  home.activation.linkEasyEffectsPreset = lib.hm.dag.entryAfter ["writeBoundary"] ''
    PRESET_DIR="$HOME/.local/share/easyeffects/input"
    PRESET_LINK="$PRESET_DIR/${config.custom.easyeffects.preset}.json"
    PRESET_SOURCE="${config.custom.easyeffects.presetSource}"

    mkdir -p "$PRESET_DIR"

    if [ -e "$PRESET_LINK" ] || [ -L "$PRESET_LINK" ]; then
      rm -f "$PRESET_LINK"
    fi

    ln -sf "$PRESET_SOURCE" "$PRESET_LINK"

    echo "EasyEffects preset linked: $PRESET_LINK -> $PRESET_SOURCE"
  '';
}
