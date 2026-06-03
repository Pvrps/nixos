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
    FIND="${pkgs.findutils}/bin/find"
    SORT="${pkgs.coreutils}/bin/sort"
    WC="${pkgs.coreutils}/bin/wc"
    CAT="${pkgs.coreutils}/bin/cat"

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

    SKIP_FILES='(^|/)\.env($|\.)|\.pem$|\.key$|\.p12$|\.pfx$|\.jks$|\.kdbx$|\.asc$|\.gpg$|\.age$|\.secret$|\.secrets$|\.local$|id_rsa$|id_ed25519$|\.cert$|\.crt$|\.ca-bundle$|\.passwd$|\.password$|\.token$|(^|/)credentials($|\.)|(^|/)secrets($|\.)|(^|/)\.npmrc$|(^|/)\.pypirc$|(^|/)\.netrc$|(^|/)\.aws/(credentials|config)$|(^|/)\.kube/config$'

    SECRET_CONTENT='BEGIN (OPENSSH|RSA|DSA|EC|PGP) PRIVATE KEY|AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|github_pat_|ghp_[A-Za-z0-9_]+|sk-[A-Za-z0-9_-]{20,}|xox[baprs]-|api[_-]?key[[:space:]]*=|token[[:space:]]*=|password[[:space:]]*='

    TREE_SKIP='.git|node_modules|target|result|vendor|build|dist|.direnv|__pycache__|.cache|.sass-cache|.next|.nuxt|out|_output|_build|eggs|.eggs|.mypy_cache|.pytest_cache|.ruff_cache|.terraform|.serverless|.venv|venv|.tox|Pods|.svn|.hg'

    TMPFILE=$(mktemp)
    SKIPPED_SECRETS=$(mktemp)
    SKIPPED_LARGE=$(mktemp)
    trap 'rm -f "$TMPFILE" "$SKIPPED_SECRETS" "$SKIPPED_LARGE"' EXIT

    {
      echo "Directory: $DIR"
      echo ""

      if command -v "$TREE_CMD" &>/dev/null; then
        "$TREE_CMD" "$DIR" -I "$TREE_SKIP" --charset=utf-8 --noreport 2>/dev/null || true
      fi

      echo ""
      echo "---"
      echo ""

      "$FIND" "$DIR" -type f \
        | "$GREP" -v -E "/($SKIP_DIRS)/" \
        | "$SORT" \
        | while IFS= read -r f; do
            REL=$($REALPATH --relative-to="$DIR" "$f")

            if printf '%s\n' "$REL" | "$GREP" -E -q "($SKIP_FILES)"; then
              printf '%s\n' "$REL" >> "$SKIPPED_SECRETS"
              continue
            fi

            BYTES=$("$WC" -c < "$f" 2>/dev/null || echo 0)
            BYTES=$(echo "$BYTES" | tr -d ' ')

            if [[ "$BYTES" -gt 1048576 ]]; then
              printf '%s (%s KB)\n' "$REL" "$((BYTES / 1024))" >> "$SKIPPED_LARGE"
              continue
            fi

            MIME=$("$FILE_CMD" --mime-type -b "$f" 2>/dev/null || echo "application/octet-stream")

            case "$MIME" in
              text/*|application/json|application/javascript|application/typescript|application/xml|application/x-yaml|application/x-toml|application/x-sh|application/x-csh|application/x-perl|application/x-python|application/x-ruby|application/x-php|application/x-lua|application/x-haskell|application/x-clojure|application/x-scheme|application/x-awk|application/x-tcl|application/x-httpd-php|application/xhtml+xml|application/atom+xml|application/rss+xml|application/svg+xml|application/x-shellscript|application/x-subrip)
                if "$GREP" -I -E -q "$SECRET_CONTENT" "$f" 2>/dev/null; then
                  printf '%s\n' "$REL" >> "$SKIPPED_SECRETS"
                  continue
                fi

                echo "====== $REL ======"
                "$CAT" "$f"
                echo ""
                ;;
            esac
          done
    } > "$TMPFILE"

    FILE_COUNT=$("$GREP" -c '^====== ' "$TMPFILE" || true)
    SECRET_SKIP_COUNT=$("$GREP" -c . "$SKIPPED_SECRETS" || true)
    LARGE_SKIP_COUNT=$("$GREP" -c . "$SKIPPED_LARGE" || true)
    BYTE_COUNT=$("$WC" -c < "$TMPFILE")
    TOKEN_ESTIMATE=$((BYTE_COUNT / 4))

    echo "dir2clip summary"
    echo "Directory: $DIR"
    echo "Files included: $FILE_COUNT"
    echo "Skipped secret-like files: $SECRET_SKIP_COUNT"
    echo "Skipped large files: $LARGE_SKIP_COUNT"
    echo "Estimated tokens: $TOKEN_ESTIMATE"

    if [[ "$SECRET_SKIP_COUNT" -gt 0 ]]; then
      echo ""
      echo "Secret-like files skipped:"
      "$CAT" "$SKIPPED_SECRETS"
    fi

    if [[ "$LARGE_SKIP_COUNT" -gt 0 ]]; then
      echo ""
      echo "Large files skipped:"
      "$CAT" "$SKIPPED_LARGE"
    fi

    echo ""
    read -r -p "Copy included content to clipboard? [y/N] " CONFIRM
    case "$CONFIRM" in
      y|Y|yes|YES) ;;
      *)
        "$NOTIFY" "dir2clip" "Copy cancelled"
        echo "Cancelled"
        exit 1
        ;;
    esac

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
