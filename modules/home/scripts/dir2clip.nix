{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.scripts.dir2clip;
  dir2clip-tool = pkgs.writeShellScriptBin "dir2clip" ''
    set -euo pipefail

    JQ="${pkgs.jq}/bin/jq"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    WL_COPY="${pkgs.wl-clipboard}/bin/wl-copy"
    FILE_CMD="${pkgs.file}/bin/file"
    TREE_CMD="${pkgs.tree}/bin/tree"
    GREP="${pkgs.gnugrep}/bin/grep"
    REALPATH="${pkgs.coreutils}/bin/realpath"

    if [[ $# -ge 1 ]]; then
      DIR="$1"
    else
      DIR="."
    fi
    DIR="$($REALPATH "$DIR")"

    if [[ ! -d "$DIR" ]]; then
      echo "Usage: dir2clip [directory]"
      echo "Error: '$DIR' is not a directory or does not exist"
      exit 1
    fi

    SKIP_DIRS='\.git|node_modules|target|result|vendor|build|dist|\.direnv|__pycache__|\.cache|\.sass-cache|\.next|\.nuxt|out|_output|_build|eggs|\.eggs|\.mypy_cache|\.pytest_cache|\.ruff_cache|\.terraform|\.serverless|\.venv|venv|\.tox|Pods|\.svn|\.hg'

    SKIP_FILES='\.env$|\.env\.[^.]+$|\.pem$|\.key$|\.secret$|\.local$|id_rsa$|id_ed25519$|\.cert$|\.crt$|\.ca-bundle$|\.passwd$|\.password$|\.token$|\.secrets$'

    TREE_SKIP='.git|node_modules|target|result|vendor|build|dist|.direnv|__pycache__|.cache|.sass-cache|.next|.nuxt|out|_output|_build|eggs|.eggs|.mypy_cache|.pytest_cache|.ruff_cache|.terraform|.serverless|.venv|venv|.tox|Pods|.svn|.hg'

    TMPFILE=$(mktemp)
    trap 'rm -f "$TMPFILE"' EXIT

    {
      echo "Directory: $DIR"
      echo ""

      if command -v "$TREE_CMD" &>/dev/null; then
        "$TREE_CMD" "$DIR" -I "$TREE_SKIP" --charset=utf-8 --noreport 2>/dev/null || true
      fi

      echo ""
      echo "---"
      echo ""

      find "$DIR" -type f \
        | "$GREP" -v -E "/($SKIP_DIRS)/" \
        | "$GREP" -v -E "($SKIP_FILES)" \
        | sort \
        | while IFS= read -r f; do
            REL=$($REALPATH --relative-to="$DIR" "$f")

            BYTES=$(wc -c < "$f" 2>/dev/null || echo 0)
            BYTES=$(echo "$BYTES" | tr -d ' ')

            if [[ "$BYTES" -gt 1048576 ]]; then
              echo "====== $REL ======"
              echo "[SKIPPED: exceeds 1MB ($((BYTES / 1024)) KB)]"
              echo ""
              continue
            fi

            MIME=$("$FILE_CMD" --mime-type -b "$f" 2>/dev/null || echo "application/octet-stream")

            case "$MIME" in
              text/*|application/json|application/javascript|application/typescript|application/xml|application/x-yaml|application/x-toml|application/x-sh|application/x-csh|application/x-perl|application/x-python|application/x-ruby|application/x-php|application/x-lua|application/x-haskell|application/x-clojure|application/x-scheme|application/x-awk|application/x-tcl|application/x-httpd-php|application/xhtml+xml|application/atom+xml|application/rss+xml|application/svg+xml|application/x-shellscript|application/x-subrip)
                echo "====== $REL ======"
                cat "$f"
                echo ""
                ;;
            esac
          done
    } > "$TMPFILE"

    FILE_COUNT=$("$GREP" -c '^====== ' "$TMPFILE" || true)
    BYTE_COUNT=$(wc -c < "$TMPFILE")
    TOKEN_ESTIMATE=$((BYTE_COUNT / 4))

    "$WL_COPY" < "$TMPFILE"

    if [[ "$TOKEN_ESTIMATE" -ge 1000 ]]; then
      "$NOTIFY" "dir2clip" "Copied $FILE_COUNT files (~$((TOKEN_ESTIMATE / 1000))K tokens) from $(basename "$DIR")"
      echo "Copied $FILE_COUNT files (~$((TOKEN_ESTIMATE / 1000))K tokens) from $(basename "$DIR")"
    else
      "$NOTIFY" "dir2clip" "Copied $FILE_COUNT files (~$TOKEN_ESTIMATE tokens) from $(basename "$DIR")"
      echo "Copied $FILE_COUNT files (~$TOKEN_ESTIMATE tokens) from $(basename "$DIR")"
    fi
  '';
in {
  options.custom.scripts.dir2clip.enable = lib.mkEnableOption "Directory to clipboard ingestion tool";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.system.wayland.enable;
        message = "dir2clip script requires a Wayland compositor (uses wl-clipboard).";
      }
    ];

    home.packages = [
      dir2clip-tool
    ];
  };
}
