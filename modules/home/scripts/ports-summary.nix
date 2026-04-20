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

    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    CYAN=$'\033[0;36m'
    RESET=$'\033[0m'

    declare -A pid_name
    declare -A pid_path
    declare -A pid_proto
    declare -A pid_listeners
    declare -A pid_connections

    current_pid=""

    while IFS= read -r line; do
      field_type="''${line:0:1}"
      field_val="''${line:1}"

      case "$field_type" in
        p)
          current_pid="$field_val"
          ;;
        t)
          pid_proto[$current_pid]="$field_val"
          ;;
        n)
          if [[ "$field_val" == *"->"* ]]; then
            local_addr="''${field_val%%->*}"
            remote_addr="''${field_val##*->}"
            local_port="''${local_addr##*:}"
            pid_connections[$current_pid]+="$local_port:$remote_addr"$'\n'
          else
            pid_listeners[$current_pid]+="$field_val"$'\n'
          fi
          ;;
      esac
    done < <($LSOF -i -P -n -F ptn 2>/dev/null)

    sorted_pids=$(
      for pid in "''${!pid_proto[@]}"; do
        echo "$pid"
      done | sort -n
    )

    for pid in $sorted_pids; do
      full_exe=$($READLINK -f /proc/"$pid"/exe 2>/dev/null || echo "")
      exe_base=$($BASENAME "$full_exe" 2>/dev/null || echo "?")

      if [[ "$exe_base" == "node" || "$exe_base" == "bun" || "$exe_base" == "deno" ]]; then
        mapfile -t _args < <($TR '\0' '\n' < /proc/"$pid"/cmdline 2>/dev/null)
        app_name=""
        for arg in "''${_args[@]}"; do
          if [[ "$arg" == *"/node_modules/"* ]]; then
            node_dir="''${arg##*node_modules/}"
            pkg="''${node_dir%%/*}"
            if [[ -n "$pkg" ]]; then
              app_name="$exe_base ($pkg)"
              break
            fi
          fi
        done
        [[ -z "$app_name" ]] && app_name="$exe_base"
        pid_name[$pid]="$app_name"
      else
        pid_name[$pid]="$exe_base"
      fi
      pid_path[$pid]="$full_exe"
    done

    printf "\n"
    printf " ''${BOLD}Listening Ports''${RESET}\n"
    printf " %s\n\n" "───────────────────────────────────────────────────────"

    for pid in $sorted_pids; do
      name="''${pid_name[$pid]:-?}"
      path="''${pid_path[$pid]:-(unknown)}"
      proto="''${pid_proto[$pid]:-IPv4}"

      printf " ''${BOLD}%s''${RESET}  -  ''${BOLD}PID %s''${RESET}  [''${CYAN}%s''${RESET}]\n" \
        "$name" "$pid" "$proto"

      printf " ''${DIM}│  %s''${RESET}\n" "$path"

      mapfile -t addrs < <(printf '%s' "''${pid_listeners[$pid]}" | grep -v '^$')
      total_addrs="''${#addrs[@]}"

      for i in "''${!addrs[@]}"; do
        addr="''${addrs[$i]}"
        port="''${addr##*:}"

        conns_for_port=""
        if [[ -n "''${pid_connections[$pid]+_}" ]]; then
          conns_for_port=$(printf '%s' "''${pid_connections[$pid]}" | grep "^$port:" | cut -d: -f2-)
        fi

        is_last_port=$(( i == total_addrs - 1 ))

        if [[ -n "$conns_for_port" ]]; then
          mapfile -t conn_lines < <(echo "$conns_for_port" | grep -v '^$')
          has_conns="''${#conn_lines[@]}"
          for j in "''${!conn_lines[@]}"; do
            conn="''${conn_lines[$j]}"
            is_last_conn=$(( j == has_conns - 1 ))
            if [[ $is_last_port -eq 1 && $is_last_conn -eq 1 ]]; then
              printf " ''${DIM}│''${RESET}  ''${CYAN}%s''${RESET}\n" "$addr"
              printf "   ''${DIM}└─''${RESET} %s\n" "$conn"
            elif [[ $j -eq 0 ]]; then
              printf " ''${DIM}│''${RESET}  ''${CYAN}%s''${RESET}\n" "$addr"
              printf "   ''${DIM}├─''${RESET} %s\n" "$conn"
            elif [[ $is_last_conn -eq 1 ]]; then
              printf "   ''${DIM}└─''${RESET} %s\n" "$conn"
            else
              printf "   ''${DIM}├─''${RESET} %s\n" "$conn"
            fi
          done
        else
          if [[ $i -eq 0 ]]; then
            printf " ''${DIM}│''${RESET}  ''${CYAN}%s''${RESET}\n" "$addr"
          elif [[ $is_last_port -eq 1 ]]; then
            printf " ''${DIM}│''${RESET}  ''${CYAN}%s''${RESET}\n" "$addr"
          else
            printf " ''${DIM}│''${RESET}  ''${CYAN}%s''${RESET}\n" "$addr"
          fi
        fi
      done

      printf "\n"
    done
  '';
in {
  options.custom.scripts.ports-summary.enable = lib.mkEnableOption "ports-summary open port viewer";

  config = lib.mkIf cfg.enable {
    home.packages = [ports-summary];
  };
}