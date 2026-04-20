{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.scripts.ports-summary;

  ports-summary = pkgs.writeShellScriptBin "ports-summary" ''
    set -euo pipefail

    LSOF="${pkgs.lsof}/bin/lsof"
    READLINK="${pkgs.coreutils}/bin/readlink"
    BASENAME="${pkgs.coreutils}/bin/basename"
    TR="${pkgs.coreutils}/bin/tr"

    # ANSI colors
    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    CYAN=$'\033[0;36m'
    RESET=$'\033[0m'

    declare -A cmd_app
    declare -A exe_path
    declare -a listeners
    declare -A seen_listener
    declare -A connections
    declare -A resolved_pid

    current_pid=""
    current_type=""

    while IFS= read -r line; do
      field_type="''${line:0:1}"
      field_val="''${line:1}"

      case "$field_type" in
        p)
          current_pid="$field_val"
          ;;
        t)
          current_type="$field_val"
          ;;
        n)
          if [[ "$field_val" == *"->"* ]]; then
            local_addr="''${field_val%%->*}"
            remote_addr="''${field_val##*->}"
            local_port="''${local_addr##*:}"
            key="$current_pid:$local_port"
            connections[$key]+="$remote_addr"$'\n'
          else
            lkey="$current_pid:$current_type:$field_val"
            if [[ -z "''${seen_listener[$lkey]+_}" ]]; then
              seen_listener[$lkey]=1
              listeners+=("$lkey")
            fi
          fi
          ;;
      esac
    done < <($LSOF -i -P -n -F ptn 2>/dev/null)

    for lkey in "''${listeners[@]}"; do
      pid="''${lkey%%:*}"
      if [[ -n "''${resolved_pid[$pid]+_}" ]]; then
        continue
      fi
      resolved_pid[$pid]=1

      full_exe=$($READLINK -f /proc/"$pid"/exe 2>/dev/null || echo "")
      exe_path[$pid]="$full_exe"
      exe_base=$($BASENAME "$full_exe" 2>/dev/null || echo "?")

      if [[ "$exe_base" == "node" || "$exe_base" == "bun" || "$exe_base" == "deno" ]]; then
        mapfile -t _args < <($TR '\0' '\n' < /proc/"$pid"/cmdline 2>/dev/null)
        raw_cmdline="''${_args[1]:-}"
        if [[ -n "$raw_cmdline" ]]; then
          app_base=$($BASENAME "$raw_cmdline")
          cmd_app[$pid]="$exe_base ($app_base)"
        else
          cmd_app[$pid]="$exe_base"
        fi
      else
        cmd_app[$pid]="$exe_base"
      fi
    done

    printf "\n"
    printf " ''${BOLD}Listening Ports''${RESET}\n"
    printf " %s\n\n" "───────────────────────────────────────────────────────"

    for lkey in "''${listeners[@]}"; do
      pid="''${lkey%%:*}"
      rest="''${lkey#*:}"
      proto="''${rest%%:*}"
      addr="''${rest#*:}"

      name="''${cmd_app[$pid]:-?}"
      full_exe="''${exe_path[$pid]:-(unknown)}"

      port="''${addr##*:}"
      conn_key="$pid:$port"

      printf "  ''${BOLD}%s''${RESET}  ·  PID %s  ·  ''${CYAN}%s''${RESET}  [%s]\n" \
        "$name" "$pid" "$addr" "$proto"
      printf "  ''${DIM}│  %s''${RESET}\n" "$full_exe"

      if [[ -n "''${connections[$conn_key]+_}" ]]; then
        mapfile -t remotes < <(printf '%s' "''${connections[$conn_key]}" | grep -v '^$')
        total="''${#remotes[@]}"
        for i in "''${!remotes[@]}"; do
          if (( i == total - 1 )); then
            printf "  └─ %s\n" "''${remotes[$i]}"
          else
            printf "  ├─ %s\n" "''${remotes[$i]}"
          fi
        done
      fi

      printf "\n"
    done
  '';
in {
  options.custom.scripts.ports-summary.enable = lib.mkEnableOption "ports-summary open port viewer";

  config = lib.mkIf cfg.enable {
    home.packages = [ports-summary];
  };
}
