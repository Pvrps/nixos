{lib, ...}:
lib.custom.mkScript {
  name = "dir2clip";
  description = "Directory to clipboard ingestion tool";
  requiresWayland = true;
  runtimeInputs = pkgs:
    with pkgs; [jq libnotify wl-clipboard file tree gnugrep coreutils findutils];
  text = ''
    if [[ $# -ge 1 ]]; then
      DIR="$1"
    else
      DIR="."
    fi
    DIR="$(realpath "$DIR")"

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

      tree "$DIR" -I "$TREE_SKIP" --charset=utf-8 --noreport 2>/dev/null || true

      echo ""
      echo "---"
      echo ""

      find "$DIR" -type f \
        | grep -v -E "/($SKIP_DIRS)/" \
        | sort \
        | while IFS= read -r f; do
            REL=$(realpath --relative-to="$DIR" "$f")

            if printf '%s\n' "$REL" | grep -E -q "($SKIP_FILES)"; then
              printf '%s\n' "$REL" >> "$SKIPPED_SECRETS"
              continue
            fi

            BYTES=$(wc -c < "$f" 2>/dev/null || echo 0)
            BYTES=$(echo "$BYTES" | tr -d ' ')

            if [[ "$BYTES" -gt 1048576 ]]; then
              printf '%s (%s KB)\n' "$REL" "$((BYTES / 1024))" >> "$SKIPPED_LARGE"
              continue
            fi

            MIME=$(file --mime-type -b "$f" 2>/dev/null || echo "application/octet-stream")

            case "$MIME" in
              text/*|application/json|application/javascript|application/typescript|application/xml|application/x-yaml|application/x-toml|application/x-sh|application/x-csh|application/x-perl|application/x-python|application/x-ruby|application/x-php|application/x-lua|application/x-haskell|application/x-clojure|application/x-scheme|application/x-awk|application/x-tcl|application/x-httpd-php|application/xhtml+xml|application/atom+xml|application/rss+xml|application/svg+xml|application/x-shellscript|application/x-subrip)
                if grep -I -E -q "$SECRET_CONTENT" "$f" 2>/dev/null; then
                  printf '%s\n' "$REL" >> "$SKIPPED_SECRETS"
                  continue
                fi

                echo "====== $REL ======"
                cat "$f"
                echo ""
                ;;
            esac
          done
    } > "$TMPFILE"

    FILE_COUNT=$(grep -c '^====== ' "$TMPFILE" || true)
    SECRET_SKIP_COUNT=$(grep -c . "$SKIPPED_SECRETS" || true)
    LARGE_SKIP_COUNT=$(grep -c . "$SKIPPED_LARGE" || true)
    BYTE_COUNT=$(wc -c < "$TMPFILE")
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
      cat "$SKIPPED_SECRETS"
    fi

    if [[ "$LARGE_SKIP_COUNT" -gt 0 ]]; then
      echo ""
      echo "Large files skipped:"
      cat "$SKIPPED_LARGE"
    fi

    echo ""
    read -r -p "Copy included content to clipboard? [y/N] " CONFIRM
    case "$CONFIRM" in
      y|Y|yes|YES) ;;
      *)
        notify-send "dir2clip" "Copy cancelled"
        echo "Cancelled"
        exit 1
        ;;
    esac

    wl-copy < "$TMPFILE"

    if [[ "$TOKEN_ESTIMATE" -ge 1000 ]]; then
      notify-send "dir2clip" "Copied $FILE_COUNT files (~$((TOKEN_ESTIMATE / 1000))K tokens) from $(basename "$DIR")"
      echo "Copied $FILE_COUNT files (~$((TOKEN_ESTIMATE / 1000))K tokens) from $(basename "$DIR")"
    else
      notify-send "dir2clip" "Copied $FILE_COUNT files (~$TOKEN_ESTIMATE tokens) from $(basename "$DIR")"
      echo "Copied $FILE_COUNT files (~$TOKEN_ESTIMATE tokens) from $(basename "$DIR")"
    fi
  '';
}
