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
    DIRNAME="${pkgs.coreutils}/bin/dirname"
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
    declare -A port_to_pid

    # ── Resolve a friendly display name for any PID ───────────────────────────
    resolve_display_name() {
      local pid="$1"
      local raw_cmd="$2"
      local full_exe="$3"
      local exe_base
      exe_base=$("$BASENAME" "$full_exe" 2>/dev/null || echo "$raw_cmd")

      if [[ "$exe_base" == "node" || "$exe_base" == "bun" || "$exe_base" == "deno" \
         || "$exe_base" == "electron" || "$raw_cmd" == "MainThread" ]]; then

        mapfile -t _args < <("$TR" '\0' '\n' < /proc/"$pid"/cmdline 2>/dev/null || true)

        # node_modules/.bin/ wins for node/bun/deno
        for arg in "''${_args[@]}"; do
          if [[ "$arg" == *"/node_modules/.bin/"* ]]; then
            echo "$exe_base (''${arg##*/node_modules/.bin/})"
            return
          fi
        done

        if [[ "$exe_base" == "electron" ]]; then
          # Priority 1: .asar path → climb to app name
          for arg in "''${_args[@]}"; do
            [[ "$arg" == "$full_exe" || "$arg" == "/proc/self/exe" ]] && continue
            [[ -z "$arg" ]] && continue
            [[ "$arg" == --* ]] && continue
            if [[ "$arg" == *.asar || "$arg" == */resources/app || "$arg" == */resources/app.asar ]]; then
              parent="$("$DIRNAME" "$arg")"
              pname="$("$BASENAME" "$parent")"
              if [[ "$pname" == "resources" ]]; then
                parent="$("$DIRNAME" "$parent")"
                pname="$("$BASENAME" "$parent")"
              fi
              # Strip nix store hash prefix (e.g. abc123-vesktop-1.5.3 → vesktop-1.5.3)
              pname="''${pname#*-}"
              # Strip version suffix (e.g. vesktop-1.5.3 → vesktop)
              pname="''${pname%-[0-9]*}"
              if [[ -n "$pname" && "$pname" != "." ]]; then
                echo "electron ($pname)"
                return
              fi
            fi
          done

          # Priority 2: --user-data-dir= (works for subprocesses like network service)
          for arg in "''${_args[@]}"; do
            if [[ "$arg" == --user-data-dir=* ]]; then
              udd="''${arg#--user-data-dir=}"
              udd_name="$("$BASENAME" "$udd")"
              if [[ -n "$udd_name" && "$udd_name" != "." ]]; then
                echo "electron ($udd_name)"
                return
              fi
            fi
          done

          # Priority 3: first non-flag non-binary arg basename
          for arg in "''${_args[@]}"; do
            [[ "$arg" == "$full_exe" || "$arg" == "/proc/self/exe" ]] && continue
            [[ -z "$arg" ]] && continue
            [[ "$arg" == --* ]] && continue
            name_part="$("$BASENAME" "$arg")"
            [[ -z "$name_part" || "$name_part" == "$exe_base" || "$name_part" == "exe" ]] && continue
            echo "electron ($name_part)"
            return
          done

          echo "electron"
          return
        fi

        # node/bun/deno: first real entrypoint arg
        for arg in "''${_args[@]}"; do
          [[ "$arg" == "$full_exe" ]] && continue
          [[ -z "$arg" ]] && continue
          [[ "$arg" == --* || "$arg" == -e || "$arg" == -r ]] && continue
          [[ "$arg" == /nix/store/* && ! "$arg" == *.js && ! "$arg" == *.ts && ! "$arg" == *.mjs ]] && continue
          name_part="$("$BASENAME" "$arg")"
          [[ -z "$name_part" ]] && continue
          echo "$exe_base ($name_part)"
          return
        done

        echo "$exe_base"
        return
      fi

      echo "$exe_base"
    }

    # ── Pass 1: map every local TCP port to its PID and process name ──────────
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
            port_to_pid[$local_port]="$_cur_pid"
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

      resolved=$(resolve_display_name "$pid" "$raw_name" "$full_exe")
      pid_name[$pid]="$resolved"

      exe_base=$("$BASENAME" "$full_exe" 2>/dev/null || echo "$raw_name")
      if [[ "$exe_base" == "node" || "$exe_base" == "bun" || "$exe_base" == "deno" \
         || "$exe_base" == "electron" || "$raw_name" == "MainThread" ]]; then
        mapfile -t _args < <("$TR" '\0' '\n' < /proc/"$pid"/cmdline 2>/dev/null || true)
        for arg in "''${_args[@]}"; do
          [[ "$arg" == "$full_exe" || "$arg" == "/proc/self/exe" ]] && continue
          [[ -z "$arg" ]] && continue
          [[ "$arg" == --* || "$arg" == -e || "$arg" == -r ]] && continue
          [[ "$arg" == /nix/store/* && ! "$arg" == *.js && ! "$arg" == *.ts \
             && ! "$arg" == *.mjs && ! "$arg" == *.asar ]] && continue
          pid_script[$pid]="$arg"
          break
        done
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
          conn_label=""

          if [[ "$conn" == 127.* || "$conn" == "::1"* ]]; then
            conn_raw_name="''${port_to_name[$remote_port]:-}"
            conn_pid="''${port_to_pid[$remote_port]:-}"
            if [[ -n "$conn_pid" && -n "$conn_raw_name" ]]; then
              conn_exe=$("$READLINK" -f /proc/"$conn_pid"/exe 2>/dev/null || echo "")
              conn_label=$(resolve_display_name "$conn_pid" "$conn_raw_name" "$conn_exe")
            fi
          fi

          if [[ $is_last_conn -eq 1 ]]; then
            conn_branch="└─"
          else
            conn_branch="├─"
          fi

          suffix=""
          if [[ -n "$conn_label" && "$conn_label" != "''${pid_name[$pid]%% *}" ]]; then
            suffix="  ''${DIM}($conn_label)''${RESET}"
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
