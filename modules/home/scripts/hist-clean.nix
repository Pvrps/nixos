{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.scripts.hist-clean;

  fzf = "${pkgs.fzf}/bin/fzf";
  grep = "${pkgs.gnugrep}/bin/grep";
  awk = "${pkgs.gawk}/bin/awk";
  mktemp = "${pkgs.coreutils}/bin/mktemp";
  mv = "${pkgs.coreutils}/bin/mv";
  cp = "${pkgs.coreutils}/bin/cp";
  wc = "${pkgs.coreutils}/bin/wc";

  hist-clean = pkgs.writeShellScriptBin "hist-clean" ''
    set -euo pipefail

    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    CYAN=$'\033[0;36m'
    YELLOW=$'\033[0;33m'
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    RESET=$'\033[0m'

    ZSH_HIST="$HOME/.zsh_history"
    BASH_HIST="$HOME/.bash_history"
    FISH_HIST="$HOME/.local/share/fish/fish_history"

    KEYWORD="''${1:-}"

    usage() {
      printf "%bUsage:%b hist-clean [keyword]\n" "$BOLD" "$RESET"
      printf "\n"
      printf "  Opens an fzf selector over all shell history entries.\n"
      printf "  If a keyword is given, the list is pre-filtered to matching entries.\n"
      printf "  Tab to multi-select entries, Enter to confirm, Esc to abort.\n"
      exit 0
    }

    [[ "''${1:-}" == "-h" || "''${1:-}" == "--help" ]] && usage

    # ── Parse a single history file into "SOURCE\x01RAWLINE\x01DISPLAY" records ─
    # Format written to the tmp file: SOURCE<SOH>RAWLINE<SOH>DISPLAY
    # SOH (\x01) is used as delimiter since it won't appear in commands.

    ENTRIES_FILE="$(''${mktemp})"
    trap 'rm -f "''${ENTRIES_FILE}"' EXIT

    parse_zsh() {
      local file="$1"
      [[ -f "$file" ]] || return 0
      # zsh extended history: lines starting with ': ts:elapsed;cmd'
      # We group pairs: the metadata line + the command line below it.
      local prev_meta=""
      while IFS= read -r line; do
        if [[ "$line" =~ ^:[[:space:]]*[0-9]+:[0-9]+\; ]]; then
          prev_meta="$line"
          # command is the part after the semicolon on the same line
          local cmd="''${line#*;}"
          printf 'zsh\x01%s\x01[zsh] %s\n' "$line" "$cmd" >> "''${ENTRIES_FILE}"
        else
          # continuation line (multi-line command) — associate with previous meta
          # represent as its own selectable entry so user can remove it explicitly
          printf 'zsh\x01%s\x01[zsh] %s\n' "$line" "$line" >> "''${ENTRIES_FILE}"
        fi
      done < "$file"
    }

    parse_bash() {
      local file="$1"
      [[ -f "$file" ]] || return 0
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        printf 'bash\x01%s\x01[bash] %s\n' "$line" "$line" >> "''${ENTRIES_FILE}"
      done < "$file"
    }

    parse_fish() {
      local file="$1"
      [[ -f "$file" ]] || return 0
      # fish history is YAML-ish: '- cmd: <command>' lines followed by '  when: <ts>'
      while IFS= read -r line; do
        if [[ "$line" =~ ^-[[:space:]]cmd:[[:space:]] ]]; then
          local cmd="''${line#*cmd: }"
          printf 'fish\x01%s\x01[fish] %s\n' "$line" "$cmd" >> "''${ENTRIES_FILE}"
        fi
      done < "$file"
    }

    parse_zsh  "$ZSH_HIST"
    parse_bash "$BASH_HIST"
    parse_fish "$FISH_HIST"

    TOTAL="$(''${wc} -l < "''${ENTRIES_FILE}" | tr -d ' ')"

    if [[ "$TOTAL" -eq 0 ]]; then
      printf "%bNo history entries found.%b\n" "$YELLOW" "$RESET"
      exit 0
    fi

    # ── Build the display list for fzf ───────────────────────────────────────────
    # Show the DISPLAY column (field 3) to the user; store the index for lookup.
    FZF_INPUT_FILE="$(''${mktemp})"
    trap 'rm -f "''${ENTRIES_FILE}" "''${FZF_INPUT_FILE}"' EXIT

    ''${awk} -F'\x01' '{print NR"\x01"$3}' "''${ENTRIES_FILE}" > "''${FZF_INPUT_FILE}"

    FZF_ARGS=(
      --multi
      --ansi
      --delimiter='\x01'
      --with-nth=2
      --header="TAB=select  ENTER=delete selected  ESC=abort  (''${TOTAL} entries)"
      --prompt="hist-clean> "
      --color="header:italic,prompt:cyan"
    )

    if [[ -n "$KEYWORD" ]]; then
      FZF_ARGS+=(--query="$KEYWORD")
    fi

    # Run fzf; if user aborts (Esc / Ctrl-C), exit cleanly
    SELECTED="$(''${awk} -F'\x01' '{print NR"\x01"$3}' "''${ENTRIES_FILE}" \
      | ''${fzf} "''${FZF_ARGS[@]}" || true)"

    if [[ -z "$SELECTED" ]]; then
      printf "%bNo entries selected. Aborting.%b\n" "$YELLOW" "$RESET"
      exit 0
    fi

    # ── Collect the raw lines to delete (by index) ───────────────────────────────
    SELECTED_INDICES="$(printf '%s\n' "$SELECTED" \
      | ''${awk} -F'\x01' '{print $1}')"

    printf "\n%b%s entries selected for deletion:%b\n\n" "$BOLD" \
      "$(printf '%s\n' "$SELECTED_INDICES" | ''${wc} -l | tr -d ' ')" "$RESET"

    # Show a preview of what will be removed
    while IFS= read -r idx; do
      display="$(''${awk} -F'\x01' -v n="$idx" 'NR==n{print $3}' "''${ENTRIES_FILE}")"
      printf "  %b-%b %s\n" "$RED" "$RESET" "$display"
    done <<< "$SELECTED_INDICES"

    printf "\n"
    read -r -p "$(printf '%bDelete these entries? [y/N]%b ' "$YELLOW" "$RESET")" CONFIRM
    [[ "$CONFIRM" =~ ^[Yy]$ ]] || { printf "Aborted.\n"; exit 0; }

    # ── Build a set of raw lines to remove, per source ───────────────────────────
    ZSH_REMOVE="$(''${mktemp})"
    BASH_REMOVE="$(''${mktemp})"
    FISH_REMOVE="$(''${mktemp})"
    trap 'rm -f "''${ENTRIES_FILE}" "''${FZF_INPUT_FILE}" "''${ZSH_REMOVE}" "''${BASH_REMOVE}" "''${FISH_REMOVE}"' EXIT

    while IFS= read -r idx; do
      source="$(''${awk} -F'\x01' -v n="$idx" 'NR==n{print $1}' "''${ENTRIES_FILE}")"
      rawline="$(''${awk} -F'\x01' -v n="$idx" 'NR==n{print $2}' "''${ENTRIES_FILE}")"
      case "$source" in
        zsh)  printf '%s\n' "$rawline" >> "''${ZSH_REMOVE}"  ;;
        bash) printf '%s\n' "$rawline" >> "''${BASH_REMOVE}" ;;
        fish) printf '%s\n' "$rawline" >> "''${FISH_REMOVE}" ;;
      esac
    done <<< "$SELECTED_INDICES"

    # ── Rewrite each history file, skipping removed lines ────────────────────────
    rewrite_file() {
      local src="$1"
      local removelist="$2"
      local label="$3"

      [[ -f "$src" ]] || return 0
      [[ -s "$removelist" ]] || return 0

      local tmp
      tmp="$(''${mktemp})"

      # For each line in src: print it only if it is NOT in removelist.
      # Use awk with a lookup table for O(n) performance.
      ''${awk} '
        NR==FNR { remove[$0]=1; next }
        !($0 in remove)
      ' "$removelist" "$src" > "$tmp"

      local before after removed_count
      before="$(''${wc} -l < "$src" | tr -d ' ')"
      after="$(''${wc} -l < "$tmp" | tr -d ' ')"
      removed_count=$(( before - after ))

      ''${cp} --backup=simple "$src" "''${src}.bak" 2>/dev/null || true
      ''${mv} "$tmp" "$src"

      printf "  %b%s%b  removed %b%d%b lines  %b(backup: %s.bak)%b\n" \
        "$CYAN" "$label" "$RESET" \
        "$GREEN" "$removed_count" "$RESET" \
        "$DIM" "$src" "$RESET"
    }

    printf "\n%bRewriting history files…%b\n\n" "$BOLD" "$RESET"
    rewrite_file "$ZSH_HIST"  "''${ZSH_REMOVE}"  "zsh "
    rewrite_file "$BASH_HIST" "''${BASH_REMOVE}" "bash"
    rewrite_file "$FISH_HIST" "''${FISH_REMOVE}" "fish"

    # ── Also purge this invocation from history (any shell will pick this up) ─────
    # Remove any trailing hist-clean lines that just got written by the current shell
    for hist_file in "$ZSH_HIST" "$BASH_HIST"; do
      [[ -f "$hist_file" ]] || continue
      tmp="$(''${mktemp})"
      ''${grep} -v 'hist-clean' "$hist_file" > "$tmp" || true
      ''${mv} "$tmp" "$hist_file"
    done

    printf "\n%bDone.%b\n" "$GREEN" "$RESET"
  '';
in {
  options.custom.scripts.hist-clean.enable =
    lib.mkEnableOption "hist-clean interactive shell history cleaner";

  config = lib.mkIf cfg.enable {
    home.packages = [hist-clean];
  };
}
