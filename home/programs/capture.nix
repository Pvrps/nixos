{pkgs, ...}: let
  screenshot-tool = pkgs.writeShellScriptBin "screenshot-tool" ''
    DIR="$HOME/Pictures/Screenshots"
    mkdir -p "$DIR"
    FILE="$DIR/$(date +'%Y-%m-%d-%H-%M-%S').png"

    if AREA=$(${pkgs.slurp}/bin/slurp); then
      ${pkgs.grim}/bin/grim -g "$AREA" - | tee "$FILE" | ${pkgs.wl-clipboard}/bin/wl-copy
      ${pkgs.libnotify}/bin/notify-send "Screenshot Saved" "$FILE"
    fi
  '';

  recording-tool = pkgs.writeShellScriptBin "recording-tool" ''
    PIDFILE="/tmp/recording-tool.pid"
    RECFILE="/tmp/recording-tool.file"
    DIR="$HOME/Videos/Recordings"
    mkdir -p "$DIR"

    if [ -f "$PIDFILE" ]; then
      PID=$(cat "$PIDFILE")
      if ${pkgs.procps}/bin/kill -0 "$PID" 2>/dev/null; then
        ${pkgs.procps}/bin/kill -SIGINT "$PID"
        while ${pkgs.procps}/bin/kill -0 "$PID" 2>/dev/null; do sleep 0.1; done
      fi
      rm "$PIDFILE"

      if [ -f "$RECFILE" ]; then
        FILE=$(cat "$RECFILE")
        rm "$RECFILE"

        if [ -f "$FILE" ]; then
           echo "file://$FILE" | ${pkgs.wl-clipboard}/bin/wl-copy -t text/uri-list
           ${pkgs.libnotify}/bin/notify-send "Recording Saved" "$FILE"
        fi
      fi
    else
      FILE="$DIR/$(date +'%Y-%m-%d-%H-%M-%S').mp4"

      if AREA=$(${pkgs.slurp}/bin/slurp); then
        echo "$FILE" > "$RECFILE"

        AUDIO_SOURCE=$(${pkgs.pulseaudio}/bin/pactl get-default-sink).monitor

        ${pkgs.wf-recorder}/bin/wf-recorder -g "$AREA" --audio="$AUDIO_SOURCE" --pixel-format yuv420p -f "$FILE" > /dev/null 2>&1 &
        PID=$!
        echo $PID > "$PIDFILE"

        ${pkgs.libnotify}/bin/notify-send "Recording Started" "Press Win+Shift+C to stop"
      fi
    fi
  '';
in {
  home.packages = [
    screenshot-tool
    recording-tool
  ];
}
