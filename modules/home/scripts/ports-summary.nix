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

    declare -A cmd_name
    declare -A listen_addrs
    declare -A connections
    declare -A seen_pid
    declare -a pids_order

    current_pid=""
    current_type=""

    while IFS= read -r line; do
      field_type="''${line:0:1}"
      field_val="''${line:1}"

      case "$field_type" in
        p)
          current_pid="$field_val"
          if [[ -z "''${seen_pid[$current_pid]+_}" ]]; then
            pids_order+=("$current_pid")
            seen_pid[$current_pid]=1
          fi
          ;;
        c)
          cmd_name[$current_pid]="$field_val"
          ;;
        t)
          current_type="$field_val"
          ;;
        n)
          if [[ "$field_val" == *"->"* ]]; then
            local_part="''${field_val%%->*}"
            remote_part="''${field_val##*->}"
            connections[$current_pid]+="$current_type $local_part -> $remote_part"$'\n'
          else
            listen_addrs[$current_pid]+="$current_type $field_val"$'\n'
          fi
          ;;
      esac
    done < <($LSOF -i -P -n -F pctn 2>/dev/null)

    printf "%-6s %-22s %-16s %-8s %s\n" "PROTO" "LOCAL ADDRESS" "NAME" "PID" "PATH"
    printf "%s\n" "────────────────────────────────────────────────────────────────────────────────"

    for pid in "''${pids_order[@]}"; do
      if [[ -z "''${listen_addrs[$pid]+_}" ]]; then
        continue
      fi

      name="''${cmd_name[$pid]:-?}"
      exe_path=$($READLINK -f /proc/"$pid"/exe 2>/dev/null || echo "(unknown)")

      first=1
      while IFS= read -r addr_line; do
        [[ -z "$addr_line" ]] && continue
        proto="''${addr_line%% *}"
        addr="''${addr_line#* }"

        if [[ $first -eq 1 ]]; then
          printf "%-6s %-22s %-16s %-8s %s\n" "$proto" "$addr" "$name" "$pid" "$exe_path"
          first=0
        else
          printf "%-6s %-22s\n" "$proto" "$addr"
        fi
      done <<< "''${listen_addrs[$pid]}"

      while IFS= read -r conn_line; do
        [[ -z "$conn_line" ]] && continue
        conn_proto="''${conn_line%% *}"
        conn_rest="''${conn_line#* }"
        local_c="''${conn_rest% -> *}"
        remote_c="''${conn_rest##* -> }"
        printf "         └─ %-20s ← %s\n" "$local_c" "$remote_c"
      done <<< "''${connections[$pid]:-}"

      printf "\n"
    done
  '';
in {
  options.custom.scripts.ports-summary.enable = lib.mkEnableOption "ports-summary open port viewer";

  config = lib.mkIf cfg.enable {
    home.packages = [ports-summary];
  };
}
