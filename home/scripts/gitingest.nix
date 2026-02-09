{pkgs, ...}: let
  ingest-tool = pkgs.writeShellScriptBin "gitingest" ''
    JQ="${pkgs.jq}/bin/jq"
    CURL="${pkgs.curl}/bin/curl"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    WL_COPY="${pkgs.wl-clipboard}/bin/wl-copy"
    GREP="${pkgs.gnugrep}/bin/grep"

    URL="$1"
    if [[ -z "$URL" ]]; then
      $NOTIFY "No repository URL provided"
      exit 1
    fi

    if [[ -z "$URL" ]] || ! echo "$URL" | $GREP -E -q '^https?://.+/.+'; then
       $NOTIFY "GitIngest Failed" "Invalid URL: '$URL'. Expecting https://host/user/repo"
       exit 1
    fi

    RESPONSE=$($CURL -sS -X POST "https://gitingest.com/api/ingest" \
      -H "Content-Type: application/json" \
      -d "{\"input_text\":\"$URL\", \"max_file_size\":10000}")

    if echo "$RESPONSE" | $GREP -q "\"detail\""; then
       ERR=$(echo "$RESPONSE" | $JQ -r '.detail[0].msg // .detail // "Unknown API error"')
       $NOTIFY "GitIngest Failed" "$ERR"
       exit 1
    fi

    CONTENT_LEN=$(echo "$RESPONSE" | $JQ -r '(.summary + .tree + .content) | length')
    if [[ "$CONTENT_LEN" -eq 0 ]]; then
       $NOTIFY "GitIngest Failed" "API returned empty content."
       exit 1
    fi

    echo "$RESPONSE" | $JQ -r '.summary + "\n\n" + .tree + "\n\n" + .content' | $WL_COPY

    $NOTIFY "GitIngest" "Copied contents of $URL"
  '';
in {
  home.packages = [
    ingest-tool
  ];
}
