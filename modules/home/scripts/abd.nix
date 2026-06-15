{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.scripts.abd;

  # Python strings use double quotes throughout to avoid Nix '' string conflicts
  extractorPy = pkgs.writeText "abd-extractor.py" ''
    import re
    import sys
    import html

    site = sys.argv[1]
    page = sys.stdin.read()

    mp3s = []
    title = ""

    if site == "goldenaudiobooks":
        patterns = [
            r"href=[\"']([^\"']*\.mp3[^\"']*)[\"']",
            r"(?<![\"'/])https?://[^\s<>\"']+\.mp3(?:\?[^\s<>\"']*)?",
        ]
        seen = set()
        for pat in patterns:
            for m in re.finditer(pat, page, re.IGNORECASE):
                url = html.unescape(m.group(1) if m.lastindex else m.group(0))
                if url not in seen:
                    seen.add(url)
                    mp3s.append(url)

        def sort_key(u):
            m = re.search(r"/(\d+)\.mp3", u)
            return int(m.group(1)) if m else 0
        mp3s.sort(key=sort_key)

        m = re.search(r"<h1[^>]*>(.*?)</h1>", page, re.IGNORECASE | re.DOTALL)
        if not m:
            m = re.search(r"<title>(.*?)</title>", page, re.IGNORECASE | re.DOTALL)
        if m:
            title = re.sub(r"<[^>]+>", "", m.group(1)).strip()
            title = html.unescape(title)
            title = re.sub(r"\s*[-|]\s*[Gg]olden[Aa]udio[Bb]ooks.*$", "", title).strip()
            title = re.sub(r"\s+[Aa]udiobook\s*$", "", title, flags=re.IGNORECASE).strip()

    if not mp3s:
        print("ERROR: no MP3 URLs found on page", file=sys.stderr)
        sys.exit(1)

    print(f"TITLE={title}")
    for u in mp3s:
        print(f"MP3={u}")
  '';

  abd-tool = pkgs.writeShellScriptBin "abd" ''
    set -euo pipefail

    CURL="${pkgs.curl}/bin/curl"
    PYTHON="${pkgs.python3}/bin/python3"
    EXTRACTOR="${extractorPy}"
    M4B="2m4b"

    usage() {
      echo "Usage: abd <url> [output.m4b]"
      echo ""
      echo "Audiobook Downloader - download and convert an audiobook to M4B."
      echo ""
      echo "Supported sites:"
      echo "  goldenaudiobooks.com"
      echo ""
      echo "Arguments:"
      echo "  url         Page URL of the audiobook"
      echo "  output.m4b  Output file (default: derived from page title)"
      exit 1
    }

    [[ $# -ge 1 ]] || usage
    PAGE_URL="$1"
    OUTPUT_ARG="''${2:-}"

    # ── site dispatcher ────────────────────────────────────────────────────────
    case "$PAGE_URL" in
      *goldenaudiobooks.com*)
        SITE="goldenaudiobooks"
        ;;
      *)
        echo "Error: unsupported site: $PAGE_URL"
        echo "Supported: goldenaudiobooks.com"
        exit 1
        ;;
    esac

    # ── fetch page HTML ────────────────────────────────────────────────────────
    echo "Fetching page: $PAGE_URL"
    HTML=$($CURL -sS --fail --max-time 30 \
      -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:125.0) Gecko/20100101 Firefox/125.0" \
      "$PAGE_URL")

    # ── extract MP3 URLs and title ─────────────────────────────────────────────
    EXTRACTED=$(echo "$HTML" | $PYTHON "$EXTRACTOR" "$SITE")

    TITLE=$(echo "$EXTRACTED" | grep '^TITLE=' | head -1 | cut -d= -f2-)
    mapfile -t MP3S < <(echo "$EXTRACTED" | grep '^MP3=' | sed 's/^MP3=//')

    COUNT="''${#MP3S[@]}"
    if [[ "$COUNT" -eq 0 ]]; then
      echo "Error: no MP3 URLs found on page"
      exit 1
    fi

    echo "Found $COUNT MP3 file(s)  [title: ''${TITLE:-unknown}]"

    # ── determine output filename ──────────────────────────────────────────────
    if [[ -n "$OUTPUT_ARG" ]]; then
      FINAL_OUTPUT="$OUTPUT_ARG"
    elif [[ -n "$TITLE" ]]; then
      SAFE_TITLE=$(echo "$TITLE" | tr -d '/:*?"<>\\|' | tr ' ' '_')
      FINAL_OUTPUT="''${SAFE_TITLE}.m4b"
    else
      FINAL_OUTPUT="audiobook.m4b"
    fi

    # ── work directory ─────────────────────────────────────────────────────────
    WORKDIR=$(mktemp -d --suffix=_abd)
    trap 'rm -rf "$WORKDIR"' EXIT
    echo "Working in $WORKDIR"

    # ── download MP3s ──────────────────────────────────────────────────────────
    echo "Downloading $COUNT files..."
    IDX=0
    for URL in "''${MP3S[@]}"; do
      IDX=$((IDX + 1))
      PADDED=$(printf '%04d' "$IDX")
      DEST="$WORKDIR/''${PADDED}.mp3"
      echo "  [$IDX/$COUNT] $URL"
      $CURL -sS --fail --max-time 300 --retry 3 --retry-delay 2 \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:125.0) Gecko/20100101 Firefox/125.0" \
        -o "$DEST" "$URL"
    done

    # ── concatenate into a single MP3 ─────────────────────────────────────────
    if [[ "$COUNT" -eq 1 ]]; then
      MERGED="$WORKDIR/0001.mp3"
    else
      echo "Concatenating $COUNT files..."
      CONCAT_LIST="$WORKDIR/concat.txt"
      for F in "$WORKDIR"/*.mp3; do
        printf 'file %s\n' "$F" >> "$CONCAT_LIST"
      done
      MERGED="$WORKDIR/merged.mp3"
      ${pkgs.ffmpeg}/bin/ffmpeg -y -f concat -safe 0 -i "$CONCAT_LIST" \
        -c copy "$MERGED" -v error -nostats
    fi

    # ── convert to M4B via 2m4b ───────────────────────────────────────────────
    echo "Converting to M4B: $FINAL_OUTPUT"
    "$M4B" "$MERGED" "$FINAL_OUTPUT"

    echo ""
    echo "Done: $FINAL_OUTPUT"
  '';
in {
  options.custom.scripts.abd.enable = lib.mkEnableOption "Audiobook Downloader - download and convert audiobooks to M4B";

  config = lib.mkIf cfg.enable {
    home.packages = [
      abd-tool
    ];
  };
}
