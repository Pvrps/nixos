{lib, ...}:
lib.custom.mkScript {
  name = "gitingest";
  description = "GitIngest repository ingestion tool";
  requiresWayland = true;
  runtimeInputs = pkgs: with pkgs; [jq curl libnotify wl-clipboard gnugrep gum];
  text = ''
    URL="''${1:-}"

    # 1. Validation
    if [[ -z "$URL" ]]; then
      echo "Usage: gitingest <url>"
      exit 1
    fi

    if ! echo "$URL" | grep -E -q '^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(/.*)?$'; then
       notify-send "GitIngest Failed" "Only public https://github.com/owner/repo URLs are accepted"
       echo "Error: expected https://github.com/owner/repo"
       exit 1
    fi

    PAYLOAD=$(jq -n --arg url "$URL" '{input_text: $url, max_file_size: 10000}')

    if ! RESPONSE=$(gum spin --spinner dot --title "Ingesting repository..." --show-output -- \
      curl -sS --fail --max-time 60 -X POST "https://gitingest.com/api/ingest" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD"); then
       notify-send "GitIngest Failed" "Server timeout or connection error."
       echo "Error: Failed to reach gitingest.com"
       exit 1
    fi

    if echo "$RESPONSE" | grep -q "\"detail\""; then
       ERR=$(echo "$RESPONSE" | jq -r '.detail[0].msg // .detail // "Unknown API error"')
       notify-send "GitIngest Failed" "$ERR"
       echo "API Error: $ERR"
       exit 1
    fi

    CONTENT_LEN=$(echo "$RESPONSE" | jq -r '(.summary + .tree + .content) | length')
    if [[ "$CONTENT_LEN" -eq 0 ]]; then
       notify-send "GitIngest Failed" "API returned empty content."
       exit 1
    fi

    echo "$RESPONSE" | jq -r '.summary + "\n\n" + .tree + "\n\n" + .content' | wl-copy

    notify-send "GitIngest" "Copied contents of $URL"
    echo "✓ Copied to clipboard!"
  '';
}
