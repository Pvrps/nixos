{pkgs, ...}: let
  ingest-tool = pkgs.writeShellScriptBin "gitingest" ''
    JQ="${pkgs.jq}/bin/jq"
    CURL="${pkgs.curl}/bin/curl"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    WL_COPY="${pkgs.wl-clipboard}/bin/wl-copy"
    GREP="${pkgs.gnugrep}/bin/grep"
    GUM="${pkgs.gum}/bin/gum"

    URL="$1"

    # 1. Validation
    if [[ -z "$URL" ]]; then
      echo "Usage: gitingest <url>"
      exit 1
    fi

    if ! echo "$URL" | $GREP -E -q '^https?://.+/.+'; then
       $NOTIFY "GitIngest Failed" "Invalid URL. Expecting https://host/user/repo"
       exit 1
    fi

    RESPONSE=$($GUM spin --spinner dot --title "Ingesting repository..." --show-output -- \
      $CURL -sS --fail --max-time 60 -X POST "https://gitingest.com/api/ingest" \
      -H "Content-Type: application/json" \
      -d "{\"input_text\":\"$URL\", \"max_file_size\":10000}")

    EXIT_CODE=$?

    if [ $EXIT_CODE -ne 0 ]; then
       $NOTIFY "GitIngest Failed" "Server timeout or connection error."
       echo "Error: Failed to reach gitingest.com (Exit code: $EXIT_CODE)"
       exit 1
    fi

    if echo "$RESPONSE" | $GREP -q "\"detail\""; then
       ERR=$(echo "$RESPONSE" | $JQ -r '.detail[0].msg // .detail // "Unknown API error"')
       $NOTIFY "GitIngest Failed" "$ERR"
       echo "API Error: $ERR"
       exit 1
    fi

    CONTENT_LEN=$(echo "$RESPONSE" | $JQ -r '(.summary + .tree + .content) | length')
    if [[ "$CONTENT_LEN" -eq 0 ]]; then
       $NOTIFY "GitIngest Failed" "API returned empty content."
       exit 1
    fi

    echo "$RESPONSE" | $JQ -r '.summary + "\n\n" + .tree + "\n\n" + .content' | $WL_COPY

    $NOTIFY "GitIngest" "Copied contents of $URL"
    echo "✓ Copied to clipboard!"
  '';
in {
  home.packages = [
    ingest-tool
  ];
}
