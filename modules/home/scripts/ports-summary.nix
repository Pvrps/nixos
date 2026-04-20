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
    SORT="${pkgs.coreutils}/bin/sort"
    AWK="${pkgs.gawk}/bin/awk"

    BOLD=$'\033[1m'
    DIM=$'\033[2m'
    CYAN=$'\033[0;36m'
    RESET=$'\033[0m'

    declare -A pid_name
    declare -A pid_path
    declare -A pid_script
    declare -A pid_listeners
    declare -A pid_connections
    declare -A port_to_name

    # ── Pass 1: map every local TCP port to its process name ─────────────────
    _cur_pid=""
    _cur_cmd=""

    while IFS= read -r line; do
      f="''${line:0:1}"
      v="''${line:1}"
      case "$f" in
        p) _cur_pid="$v" ;;
        c) _cur_cmd="$v" ;;
        n)
          [[ "$v" == *"can't identify"* ]] && continue
          [[ "$v" == /* ]] && continue
          local_part="''${v%%->*}"
          local_port="''${local_part##*:}"
          [[ "$local_port" =~ ^[0-9]+$ ]] || continue
          if [[ -z "''${port_to_name[$local_port]+_}" ]]; then
            port_to_name[$local_port]="$_cur_cmd"
          fi
          ;;
      esac
    done < <("$LSOF" -i TCP -P -n -F pcn 2>/dev/null)

    # ── Pass 2: collect listeners + established connections per PID ───────────
    _cur_pid=""

    while IFS= read -r line; do
      f="''${line:0:1}"
      v="''${line:1}"
      case "$f" in
        p) _cur_pid="$v" ;;
        c)
          [[ -z "''${pid_name[$_cur_pid]+_}" ]] && pid_name[$_cur_pid]="$v"
          ;;
        n)
          [[ "$v" == *"can't identify"* ]] && continue
          [[ "$v" == /* ]] && continue
          if [[ "$v" == *"->"* ]]; then
            local_part="''${v%%->*}"
            remote_part="''${v##*->}"
            local_port="''${local_part##*:}"
            [[ "$remote_part" == *:* ]] || continue
            [[ "$local_port" =~ ^[0-9]+$ ]] || continue
            pid_connections[$_cur_pid]+="$local_port $remote_part"$'\n'
          else
            existing="''${pid_listeners[$_cur_pid]:-}"
            [[ "$existing" != *"$v"* ]] && pid_listeners[$_cur_pid]+="$v"$'\n'
          fi
          ;;
      esac
    done < <("$LSOF" -i -P -n -F pcn 2>/dev/null)

    # ── Pass 3: resolve display names + script paths ──────────────────────────
    for pid in "''${!pid_listeners[@]}"; do
      raw_name="''${pid_name[$pid]:-}"
      full_exe=$("$READLINK" -f /proc/"$pid"/exe 2>/dev/null || echo "")
      pid_path[$pid]="$full_exe"
      exe_base=$("$BASENAME" "$full_exe" 2>/dev/null || echo "$raw_name")

      if [[ "$exe_base" == "node" || "$exe_base" == "bun" || "$exe_base" == "deno" || "$raw_name" == "MainThread" ]]; then
        mapfile -t _args < <("$TR" '\0' '\n' < /proc/"$pid"/cmdline 2>/dev/null || true)
        resolved=""
        script_path=""

        # Priority 1: node_modules/.bin/ entry
        for arg in "''${_args[@]}"; do
          if [[ "$arg" == *"/node_modules/.bin/"* ]]; then
            bin_name="''${arg##*/node_modules/.bin/})"
            resolved="$exe_base ($bin_name"
            script_path=$("$READLINK" -f "$arg" 2>/dev/null || echo "$arg")
            break
          fi
        done

        # Priority 2: first real entrypoint argument
        if [[ -z "$resolved" ]]; then
          for arg in "''${_args[@]}"; do
            [[ "$arg" == "$full_exe" ]] && continue
            [[ -z "$arg" ]] && continue
            [[ "$arg" == --* || "$arg" == -e || "$arg" == -r ]] && continue
            [[ "$arg" == /nix/store/* && ! "$arg" == *.js && ! "$arg" == *.ts && ! "$arg" == *.mjs ]] && continue
            name_part="$("$BASENAME" "$arg")"
            [[ -z "$name_part" ]] && continue
            resolved="$exe_base ($name_part)"
            script_path="$arg"
            break
          done
        fi

        if [[ -n "$resolved" ]]; then
          pid_name[$pid]="$resolved"
          pid_script[$pid]="$script_path"
        else
          pid_name[$pid]="$exe_base"
        fi
      fi
    done

    # ── Sort by name ──────────────────────────────────────────────────────────
    mapfile -t sorted_pids < <(
      for pid in "''${!pid_listeners[@]}"; do
        printf '%s\t%s\n' "''${pid_name[$pid]:-zzz}" "$pid"
      done | "$SORT" | "$AWK" -F'\t' '{print $2}'
    )

    # ── Render ────────────────────────────────────────────────────────────────
    printf "\n"
    printf "%b Listening Ports%b\n" "$BOLD" "$RESET"
    printf " %s\n\n" "────────────────────────────────────────────────────────"

    for pid in "''${sorted_pids[@]}"; do
      name="''${pid_name[$pid]:-?}"
      path="''${pid_path[$pid]:-(unknown)}"
      script="''${pid_script[$pid]:-}"

      printf "%b%s%b  %b·  PID %s%b\n" "$BOLD" "$name" "$RESET" "$DIM" "$pid" "$RESET"
      printf "%b  %s%b\n" "$DIM" "$path" "$RESET"
      if [[ -n "$script" && "$script" != "$path" ]]; then
        printf "%b  %s%b\n" "$DIM" "$script" "$RESET"
      fi

      mapfile -t addrs < <(
        printf '%s' "''${pid_listeners[$pid]:-}" \
          | grep -v '^$' \
          | "$SORT" -t: -k2 -n
      )
      total_addrs="''${#addrs[@]}"

      for i in "''${!addrs[@]}"; do
        addr="''${addrs[$i]}"
        port="''${addr##*:}"
        is_last_addr=$(( i == total_addrs - 1 ))

        mapfile -t conns < <(
          printf '%s' "''${pid_connections[$pid]:-}" \
            | "$AWK" -v p="$port" '$1 == p && $2 != "" {print $2}' \
            | grep -v '^$' \
            | "$SORT" -u \
            || true
        )
        num_conns="''${#conns[@]}"

        # └─ for last addr regardless of whether it has children
        if [[ $is_last_addr -eq 1 ]]; then
          port_prefix="└─"
        else
          port_prefix="├─"
        fi

        printf "  %b%s%b %b%s%b\n" "$DIM" "$port_prefix" "$RESET" "$CYAN" "$addr" "$RESET"

        for j in "''${!conns[@]}"; do
          conn="''${conns[$j]}"
          is_last_conn=$(( j == num_conns - 1 ))

          remote_port="''${conn##*:}"
          conn_app=""
          if [[ "$conn" == 127.* || "$conn" == "::1"* ]]; then
            conn_app="''${port_to_name[$remote_port]:-}"
          fi

          if [[ $is_last_conn -eq 1 ]]; then
            conn_branch="└─"
          else
            conn_branch="├─"
          fi

          suffix=""
          if [[ -n "$conn_app" && "$conn_app" != "''${pid_name[$pid]%% *}" ]]; then
            suffix="  ''${DIM}($conn_app)''${RESET}"
          fi

          if [[ $is_last_addr -eq 1 ]]; then
            printf "       %b%s%b %s%s\n" "$DIM" "$conn_branch" "$RESET" "$conn" "$suffix"
          else
            printf "  %b│%b   %b%s%b %s%s\n" "$DIM" "$RESET" "$DIM" "$conn_branch" "$RESET" "$conn" "$suffix"
          fi
        done
      done

      printf "\n"
    done
  '';
in {
  options.custom.scripts.ports-summary.enable =
    lib.mkEnableOption "ports-summary open port viewer";

  config = lib.mkIf cfg.enable {
    home.packages = [ports-summary];
  };
}
