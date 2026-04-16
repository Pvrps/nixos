{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.scripts.capture.recording;

  recording-tool = pkgs.writeShellScriptBin "recording-tool" ''
    PIDFILE="/tmp/recording-tool.pid"
    RECFILE="/tmp/recording-tool.file"
    DIR="$HOME/Videos/Recordings"
    mkdir -p "$DIR"

    if [ -f "$PIDFILE" ]; then
      PID=$(cat "$PIDFILE")
      if ${pkgs.procps}/bin/kill -0 "$PID" 2>/dev/null; then
        ${pkgs.procps}/bin/kill -SIGTERM "$PID"
        while ${pkgs.procps}/bin/kill -0 "$PID" 2>/dev/null; do sleep 0.1; done
      fi
      rm "$PIDFILE"

      if [ -f "$RECFILE" ]; then
        FILE=$(cat "$RECFILE")
        rm "$RECFILE"

        if [ -f "$FILE" ]; then
          ${pkgs.wl-clipboard}/bin/wl-copy "$FILE"
          RESULT=$(${pkgs.libnotify}/bin/notify-send \
            --action="copy-path=Copy Path" \
            "Recording Saved" "$FILE")
          if [[ "$RESULT" == "copy-path" ]]; then
            printf '%s' "$FILE" | ${pkgs.wl-clipboard}/bin/wl-copy
          fi
        fi
      fi
    else
      FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').mp4"

      if AREA=$(${pkgs.slurp}/bin/slurp); then
        # slurp outputs "X,Y WxH"; convert to "WxH+X+Y" for gpu-screen-recorder
        REGION=$(echo "$AREA" | ${pkgs.gawk}/bin/awk '{split($1,a,","); split($2,b,"x"); printf "%sx%s+%s+%s", b[1], b[2], a[1], a[2]}')
        echo "$FILE" > "$RECFILE"

        AUDIO_SOURCE=$(${pkgs.pulseaudio}/bin/pactl get-default-sink).monitor

        ${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder \
          -w region -region "$REGION" \
          -a "$AUDIO_SOURCE" \
          -c mp4 -o "$FILE" > /dev/null 2>&1 &
        PID=$!
        echo $PID > "$PIDFILE"

        ${pkgs.libnotify}/bin/notify-send "Recording Started" "Press Win+Shift+C to stop"
      fi
    fi
  '';

  monitor-recording-tool = pkgs.writeShellScriptBin "monitor-recording-tool" ''
    PIDFILE="/tmp/monitor-recording-tool.pid"
    RECFILE="/tmp/monitor-recording-tool.file"
    DIR="$HOME/Videos/Recordings"
    mkdir -p "$DIR"

    if [ -f "$PIDFILE" ]; then
      PID=$(cat "$PIDFILE")
      if ${pkgs.procps}/bin/kill -0 "$PID" 2>/dev/null; then
        ${pkgs.procps}/bin/kill -SIGTERM "$PID"
        while ${pkgs.procps}/bin/kill -0 "$PID" 2>/dev/null; do sleep 0.1; done
      fi
      rm "$PIDFILE"

      if [ -f "$RECFILE" ]; then
        FILE=$(cat "$RECFILE")
        rm "$RECFILE"

        if [ -f "$FILE" ]; then
          ${pkgs.wl-clipboard}/bin/wl-copy "$FILE"
          RESULT=$(${pkgs.libnotify}/bin/notify-send \
            --action="copy-path=Copy Path" \
            "Recording Saved" "$FILE")
          if [[ "$RESULT" == "copy-path" ]]; then
            printf '%s' "$FILE" | ${pkgs.wl-clipboard}/bin/wl-copy
          fi
        fi
      fi
    else
      FILE="$DIR/$(date +'%Y-%m-%d_%H-%M-%S').mp4"

      # Extract connector name (e.g. "DP-3") from niri's focused output at runtime
      OUTPUT=$(niri msg focused-output 2>/dev/null | ${pkgs.gnugrep}/bin/grep -oP '\(\K[^)]+' | head -1)

      if [ -z "$OUTPUT" ]; then
        ${pkgs.libnotify}/bin/notify-send "Recording Failed" "Could not determine focused monitor"
        exit 1
      fi

      echo "$FILE" > "$RECFILE"

      AUDIO_SOURCE=$(${pkgs.pulseaudio}/bin/pactl get-default-sink).monitor

      ${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder \
        -w "$OUTPUT" \
        -a "$AUDIO_SOURCE" \
        -c mp4 -o "$FILE" > /dev/null 2>&1 &
      PID=$!
      echo $PID > "$PIDFILE"

      ${pkgs.libnotify}/bin/notify-send "Recording Started" "$OUTPUT — Press Win+Shift+R to stop"
    fi
  '';
in {
  options.custom.scripts.capture.recording.enable = lib.mkEnableOption "Screen recording tool";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.system.wayland.enable;
        message = "capture-recording requires a Wayland compositor (uses gpu-screen-recorder, slurp).";
      }
    ];

    home.packages = [
      recording-tool
      monitor-recording-tool
      pkgs.gpu-screen-recorder
      pkgs.slurp
      pkgs.procps
      pkgs.pulseaudio
      pkgs.wl-clipboard
      pkgs.libnotify
      pkgs.gawk
      pkgs.gnugrep
    ];

    custom.programs.niri.keybinds = [
      ''Mod+Shift+C { spawn "recording-tool"; }''
      ''Mod+Shift+R { spawn "monitor-recording-tool"; }''
    ];
  };
}
