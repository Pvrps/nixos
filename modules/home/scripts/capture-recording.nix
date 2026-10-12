{lib, ...}:
lib.custom.mkScript {
  name = "recording-tool";
  optionName = "capture.recording";
  description = "Screen recording tool";
  requiresWayland = true;
  keybind = ''Mod+Shift+C { spawn "recording-tool"; }'';
  mangoKeybind = "SUPER+SHIFT,c,spawn,recording-tool";
  runtimeInputs = pkgs:
    with pkgs; [
      gpu-screen-recorder
      slurp
      procps
      pulseaudio
      wl-clipboard
      libnotify
      gawk
      gnugrep
      coreutils
      jq
      niri
      mango
    ];
  text = ''
    set -uo pipefail

    # Mode: "region" (default, slurp selection) or "monitor" (focused output)
    MODE="''${1:-region}"

    STATE_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/recording-tool"
    mkdir -p "$STATE_DIR"
    chmod 700 "$STATE_DIR"
    PIDFILE="$STATE_DIR/$MODE-recording.pid"
    RECFILE="$STATE_DIR/$MODE-recording.file"
    DIR="$HOME/Videos/Recordings"
    mkdir -p "$DIR"

    # --- Stop an in-progress recording -------------------------------------
    if [ -f "$PIDFILE" ]; then
      PID=$(cat "$PIDFILE")
      if kill -0 "$PID" 2>/dev/null; then
        kill -SIGTERM "$PID"
        while kill -0 "$PID" 2>/dev/null; do sleep 0.1; done
      fi
      rm "$PIDFILE"

      if [ -f "$RECFILE" ]; then
        FILE=$(cat "$RECFILE")
        rm "$RECFILE"

        if [ -f "$FILE" ]; then
          wl-copy "$FILE"
          RESULT=$(notify-send \
            --action="copy-path=Copy Path" \
            "Recording Saved" "$FILE")
          if [[ "$RESULT" == "copy-path" ]]; then
            printf '%s' "$FILE" | wl-copy
          fi
        fi
      fi
      exit 0
    fi

    # --- Start a new recording ---------------------------------------------
    FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').mp4"

    # Determine the gpu-screen-recorder capture target for the mode.
    if [ "$MODE" = "monitor" ]; then
      # Connector name (e.g. "DP-3") of the focused output, from whichever
      # compositor is running.
      if [ -n "''${MANGO_INSTANCE_SIGNATURE:-}" ]; then
        OUTPUT=$(mmsg get all-monitors 2>/dev/null | jq -r '.monitors[] | select(.active) | .name' | head -1)
      else
        OUTPUT=$(niri msg focused-output 2>/dev/null | grep -oP '\(\K[^)]+' | head -1)
      fi
      if [ -z "$OUTPUT" ]; then
        notify-send "Recording Failed" "Could not determine focused monitor"
        exit 1
      fi
      CAPTURE_ARGS=(-w "$OUTPUT")
      STOP_HINT="$OUTPUT — Press Win+Shift+R to stop"
    else
      if ! AREA=$(slurp); then
        exit 0
      fi
      # slurp outputs "X,Y WxH"; convert to "WxH+X+Y" for gpu-screen-recorder.
      REGION=$(echo "$AREA" | awk '{split($1,a,","); split($2,b,"x"); printf "%sx%s+%s+%s", b[1], b[2], a[1], a[2]}')
      CAPTURE_ARGS=(-w region -region "$REGION")
      STOP_HINT="Press Win+Shift+C to stop"
    fi

    echo "$FILE" > "$RECFILE"

    AUDIO_SINK=$(pactl get-default-sink).monitor
    AUDIO_MIC=$(pactl get-default-source)

    gpu-screen-recorder \
      "''${CAPTURE_ARGS[@]}" \
      -a "$AUDIO_SINK" \
      -a "$AUDIO_MIC" \
      -c mp4 -o "$FILE" > /dev/null 2>&1 &
    PID=$!
    echo $PID > "$PIDFILE"

    notify-send "Recording Started" "$STOP_HINT"
  '';
  # The monitor mode is invoked via its own keybind; guarded behind each
  # compositor's enable.
  extraConfig = {config, ...}: {
    custom.programs.niri.keybinds = lib.mkIf config.custom.programs.niri.enable [
      ''Mod+Shift+R { spawn "recording-tool" "monitor"; }''
    ];
    custom.programs.mango.keybinds = lib.mkIf config.custom.programs.mango.enable [
      "SUPER+SHIFT,r,spawn,recording-tool monitor"
    ];
  };
}
