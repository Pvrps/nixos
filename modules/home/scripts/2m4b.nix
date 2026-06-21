{lib, ...}:
lib.custom.mkScript {
  name = "2m4b";
  optionName = "2m4b";
  description = "MP3 to chapterized M4B audiobook converter";
  runtimeInputs = pkgs: with pkgs; [(ffmpeg-full.override {withUnfree = true;}) python3 gnugrep coreutils];
  text = ''
    usage() {
      echo "Usage: 2m4b [options] <input.mp3> [output.m4b]"
      echo ""
      echo "Convert an audiobook MP3 to a chapterized M4B."
      echo "Chapter source is picked in order of preference:"
      echo "  1. Existing container chapters (e.g. ID3v2 CHAP)"
      echo "  2. Embedded CUESHEET tag"
      echo "  3. Silence detection (auto-chapter)"
      echo ""
      echo "Options:"
      echo "  -b <rate>     Audio bitrate (default: 64k mono, 96k stereo)"
      echo "  --min <s>     Min chapter length for silence detection (default: 300)"
      echo "  --max <s>     Max chapter length for silence detection (default: 900)"
      echo "  --sd <s>      Min silence duration to cut at (default: 1.5)"
      echo "  --noise <dB>  Silence threshold (default: -30dB)"
      exit 1
    }

    BITRATE=""
    MIN_LEN=300
    MAX_LEN=900
    SIL_DUR=1.5
    NOISE="-30dB"
    POSITIONAL=()

    while [[ $# -gt 0 ]]; do
      case "$1" in
        -b) BITRATE="$2"; shift 2 ;;
        --min) MIN_LEN="$2"; shift 2 ;;
        --max) MAX_LEN="$2"; shift 2 ;;
        --sd) SIL_DUR="$2"; shift 2 ;;
        --noise) NOISE="$2"; shift 2 ;;
        -h|--help) usage ;;
        -*) echo "Unknown option: $1"; usage ;;
        *) POSITIONAL+=("$1"); shift ;;
      esac
    done

    [[ ''${#POSITIONAL[@]} -ge 1 ]] || usage
    INPUT="''${POSITIONAL[0]}"
    OUTPUT="''${POSITIONAL[1]:-''${INPUT%.*}.m4b}"

    # Render seconds as H:MM:SS for human-readable durations.
    fmt_hms() {
      local t=''${1%.*}
      printf '%d:%02d:%02d' $((t / 3600)) $(((t % 3600) / 60)) $((t % 60))
    }

    # Drive ffmpeg via -progress and print a single rewriting status line that
    # reports a real percentage of the total duration plus encode speed, so the
    # media-position counter is never mistaken for time remaining. Usage:
    #   run_with_progress <label> <total_seconds> <loglevel> -- <ffmpeg args...>
    # Stderr is left untouched so callers can capture e.g. silencedetect output.
    run_with_progress() {
      local label="$1" total="$2" loglevel="$3"; shift 3
      [[ "$1" == "--" ]] && shift
      local total_s=''${total%.*}
      [[ "$total_s" -gt 0 ]] 2>/dev/null || total_s=0
      ffmpeg -hide_banner -nostats -loglevel "$loglevel" -progress pipe:1 "$@" \
        | while IFS='=' read -r key val; do
            case "$key" in
              out_time_us|out_time_ms)
                cur=$((val / 1000000))
                if [[ "$total_s" -gt 0 ]]; then
                  pct=$((cur * 100 / total_s))
                  [[ "$pct" -gt 100 ]] && pct=100
                  printf '\r  %s: %3d%%  (%s / %s)        ' \
                    "$label" "$pct" "$(fmt_hms "$cur")" "$(fmt_hms "$total_s")"
                else
                  printf '\r  %s: %s        ' "$label" "$(fmt_hms "$cur")"
                fi
                ;;
              progress)
                [[ "$val" == "end" ]] && printf '\r  %s: done%50s\n' "$label" ""
                ;;
            esac
          done
      # Propagate ffmpeg's exit status, not the while-loop's, so encode/scan
      # failures still abort under `set -o errexit -o pipefail`.
      return "''${PIPESTATUS[0]}"
    }

    if [[ ! -f "$INPUT" ]]; then
      echo "Error: '$INPUT' does not exist"
      exit 1
    fi

    PYSCRIPT=$(mktemp --suffix=.py)
    META=$(mktemp --suffix=.ffmeta)
    trap 'rm -f "$PYSCRIPT" "$META"' EXIT

    cat > "$PYSCRIPT" <<'PYEOF'
    import re
    import sys

    mode = sys.argv[1]
    total_ms = int(float(sys.argv[2]) * 1000)
    text = sys.stdin.read()

    cuts = []

    if mode == "cue":
        # CUE-style: TRACK n AUDIO / TITLE "..." / INDEX 01 MM:SS:cc
        # The third field is centiseconds in practice (values > 74 appear).
        pat = re.compile(r'TITLE "([^"]*)"\s*\n\s*INDEX 01 (\d+):(\d+):(\d+)')
        for title, mm, ss, cc in pat.findall(text):
            start = (int(mm) * 60 + int(ss)) * 1000 + int(cc) * 10
            cuts.append([title, start])
        cuts.sort(key=lambda c: c[1])
    else:
        # Parse ffmpeg silencedetect output; cut chapters at silence
        # midpoints, preferring the longest silence within the
        # [min_len, max_len] window after the current chapter start.
        min_ms = int(float(sys.argv[3]) * 1000)
        max_ms = int(float(sys.argv[4]) * 1000)
        starts = [float(x) for x in re.findall(r"silence_start: (-?[0-9.]+)", text)]
        ends = [float(x) for x in re.findall(r"silence_end: (-?[0-9.]+)", text)]
        silences = [(int((s + e) / 2 * 1000), e - s) for s, e in zip(starts, ends)]
        cuts = [[None, 0]]
        cur = 0
        while cur + max_ms < total_ms:
            window = [x for x in silences if cur + min_ms <= x[0] <= cur + max_ms]
            if window:
                pick = max(window, key=lambda x: x[1])[0]
            else:
                later = [x for x in silences if x[0] > cur + max_ms]
                if not later:
                    break
                pick = later[0][0]
            if pick >= total_ms - min_ms:
                break
            cuts.append([None, pick])
            cur = pick

    # Drop degenerate chapters shorter than 1s (e.g. markers at EOF)
    pruned = []
    for i, cut in enumerate(cuts):
        end = cuts[i + 1][1] if i + 1 < len(cuts) else total_ms
        if end - cut[1] >= 1000:
            pruned.append(cut)
    cuts = pruned
    if not cuts:
        cuts = [[None, 0]]

    def esc(s):
        out = []
        for ch in s:
            if ch in "=;#\\":
                out.append("\\" + ch)
            elif ch == "\n":
                out.append("\\\n")
            else:
                out.append(ch)
        return "".join(out)

    lines = [";FFMETADATA1"]
    for i, cut in enumerate(cuts):
        title = cut[0] if cut[0] else "Chapter %02d" % (i + 1)
        end = cuts[i + 1][1] if i + 1 < len(cuts) else total_ms
        lines.append("[CHAPTER]")
        lines.append("TIMEBASE=1/1000")
        lines.append("START=%d" % cut[1])
        lines.append("END=%d" % end)
        lines.append("title=%s" % esc(title))

    sys.stdout.write("\n".join(lines) + "\n")
    sys.stderr.write("Generated %d chapters\n" % len(cuts))
    PYEOF

    DURATION=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$INPUT")
    CHANNELS=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=nw=1:nk=1 "$INPUT")
    CHAPTER_COUNT=$(ffprobe -v error -show_chapters -of csv=p=0 "$INPUT" | grep -c . || true)
    CUESHEET=$(ffprobe -v error -show_entries format_tags=CUESHEET -of default=nw=1:nk=1 "$INPUT" || true)
    COVER_CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$INPUT" || true)

    if [[ -z "$BITRATE" ]]; then
      if [[ "''${CHANNELS:-1}" -ge 2 ]]; then
        BITRATE="96k"
      else
        BITRATE="64k"
      fi
    fi

    EARGS=(-y -i "$INPUT")

    if [[ "$CHAPTER_COUNT" -ge 2 ]]; then
      MODE="container"
      echo "Using $CHAPTER_COUNT existing container chapters"
      EARGS+=(-map_chapters 0)
    elif [[ -n "$CUESHEET" ]]; then
      MODE="cuesheet"
      echo "Using embedded CUESHEET tag for chapters"
      printf '%s' "$CUESHEET" | python3 "$PYSCRIPT" cue "$DURATION" > "$META"
      EARGS+=(-i "$META" -map_chapters 1)
    else
      MODE="silence"
      echo "No chapter data found; scanning for silences (full decode, ~total runtime / speed)..."
      SILENCE_LOG=$(mktemp --suffix=.silog)
      trap 'rm -f "$PYSCRIPT" "$META" "$SILENCE_LOG"' EXIT
      # silencedetect findings are emitted at `info` level on stderr (captured
      # to file); -progress drives the status line on stdout.
      run_with_progress "Scanning" "$DURATION" info -- \
        -i "$INPUT" -vn -af "silencedetect=noise=$NOISE:d=$SIL_DUR" -f null - \
        2> "$SILENCE_LOG"
      python3 "$PYSCRIPT" silence "$DURATION" "$MIN_LEN" "$MAX_LEN" < "$SILENCE_LOG" > "$META"
      EARGS+=(-i "$META" -map_chapters 1)
    fi

    # NOTE: do NOT use `ffmpeg -encoders | grep -q` here. Under `set -o pipefail`
    # `grep -q` closes the pipe on first match, ffmpeg dies with SIGPIPE (141),
    # and the pipeline reports failure even though the encoder is present, so we
    # silently fell back to the lower-quality `aac` encoder. Capture first, then
    # match the captured text.
    ENCODERS=$(ffmpeg -hide_banner -encoders 2>/dev/null || true)
    if [[ "$ENCODERS" == *libfdk_aac* ]]; then
      AAC_CODEC="libfdk_aac"
      ENCODE_EXTRA=(-afterburner 0)
      if [[ "''${CHANNELS:-1}" -lt 2 ]]; then
        ENCODE_EXTRA+=(-profile:a aac_he)
      fi
    else
      AAC_CODEC="aac"
      ENCODE_EXTRA=(-aac_coder fast)
    fi

    EARGS+=(-map 0:a -map_metadata 0 -c:a "$AAC_CODEC" -b:a "$BITRATE" "''${ENCODE_EXTRA[@]}")

    case "$COVER_CODEC" in
      mjpeg | png) EARGS+=(-map 0:v:0 -c:v copy -disposition:v:0 attached_pic) ;;
    esac

    EARGS+=(-movflags +faststart -f ipod "$OUTPUT")

    echo "Encoding to $OUTPUT ($AAC_CODEC $BITRATE, chapter mode: $MODE)..."
    run_with_progress "Encoding" "$DURATION" warning -- "''${EARGS[@]}"

    OUT_CHAPTERS=$(ffprobe -v error -show_chapters -of csv=p=0 "$OUTPUT" | grep -c . || true)
    echo "✓ Wrote $OUTPUT ($OUT_CHAPTERS chapters)"
  '';
}
