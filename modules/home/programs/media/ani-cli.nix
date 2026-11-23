{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.aniCli;

  # Plays ani-cli episodes in Celluloid.
  #
  # ani-cli hands its player mpv command-line flags (--referrer, --sub-file,
  # --force-media-title, ...); the referrer is mandatory or the streams
  # refuse to play. ani-cli only passes those flags to players whose path
  # contains "mpv", hence the name. Celluloid forwards --mpv-KEY=VALUE to
  # its embedded mpv as options (not command-line flags), wrapping VALUE in
  # single quotes and unescaping \x sequences, so:
  #   - backslashes and quotes in values are escaped;
  #   - --sub-file (a CLI-only alias) becomes --sub-files, a ':'-separated
  #     list, so the ':' in subtitle URLs is escaped for mpv.
  #
  # --no-existing-session: Celluloid otherwise hands the file to an already
  # open window and drops every --mpv-* option on the way (no referrer, no
  # title, no resume), so each episode gets its own instance.
  #
  # Resume: mpv's built-in watch-later keys saved positions on the stream
  # URL, but ani-cli scrapes a fresh URL every run, so positions would never
  # match. Instead we key on the media title ("<anime> Episode <n>"), which
  # is stable across runs, by giving each episode its own watch-later
  # directory. Celluloid sends mpv "quit" on close, so the position is saved.
  # The patched ani-cli -c stays on an episode while its directory holds a
  # position (see patches/ani-cli-resume-continue.patch).
  player = pkgs.writeShellScriptBin "mpv-celluloid" ''
    title=""
    for arg in "$@"; do
      case "$arg" in
        --force-media-title=*) title="''${arg#--force-media-title=}" ;;
      esac
    done

    extra=()
    ${lib.optionalString cfg.resumePlayback ''
      key=$(printf '%s' "$title" | tr -cs '[:alnum:]._-' '_')
      dir="''${ANI_CLI_HIST_DIR:-''${XDG_STATE_HOME:-$HOME/.local/state}/ani-cli}/watch-later/''${key:-default}"
      prev="$dir/.previous"
      mkdir -p "$dir"

      # Resume from the saved position, if any. It is parked in $prev until
      # Celluloid exits: closing the window while the stream is still loading
      # saves no (or an empty) position, which must not wipe the old one.
      latest=$(ls -t "$dir" 2>/dev/null | head -n1)
      if [ -n "$latest" ]; then
        pos=$(sed -n 's/^start=//p' "$dir/$latest" | head -n1)
        mv -f "$dir/$latest" "$prev"
        rm -f "$dir"/*
        [ -n "$pos" ] && extra+=("--start=$pos")
      fi
      extra+=(--save-position-on-quit=yes --watch-later-options=start "--watch-later-directory=$dir")
    ''}

    opts=()
    files=()
    for arg in "''${extra[@]}" "$@"; do
      case "$arg" in
        --*=*)
          k="''${arg%%=*}"
          k="''${k#--}"
          v="''${arg#*=}"
          if [ "$k" = sub-file ]; then
            k=sub-files
            v="''${v//:/\\:}"
          fi
          v="''${v//\\/\\\\}"
          v="''${v//\'/\\\'}"
          opts+=("--mpv-$k=$v")
          ;;
        --no-*) opts+=("--mpv-''${arg#--no-}=no") ;;
        --*) opts+=("--mpv-''${arg#--}=yes") ;;
        *) files+=("$arg") ;;
      esac
    done

    started=$(date +%s)
    ${lib.getExe pkgs.celluloid} --no-existing-session "''${opts[@]}" -- "''${files[@]}"
    status=$?

    ${lib.optionalString cfg.resumePlayback ''
      # Drop saves without a position, then decide what survives.
      for f in "$dir"/*; do
        [ -f "$f" ] && ! grep -q '^start=' "$f" && rm -f "$f"
      done
      if [ -n "$(ls "$dir")" ]; then
        rm -f "$prev" # new position saved
      elif [ -e "$prev" ] && [ $(($(date +%s) - started)) -lt 60 ]; then
        mv -f "$prev" "$dir/restored" # closed before it really played
      else
        rm -f "$prev" # watched to the end
      fi
    ''}
    exit "$status"
  '';

  ani-cli = pkgs.ani-cli.overrideAttrs (old: {
    patches = (old.patches or []) ++ [../../patches/ani-cli-resume-continue.patch];
  });

  # Bake env defaults into the binary instead of home.sessionVariables so
  # they work in any context without re-login (still overridable per-run).
  # The player is referenced by store path so it stays off $PATH.
  ani-cli-wrapped = pkgs.symlinkJoin {
    name = "ani-cli-wrapped";
    paths = [ani-cli];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/ani-cli \
        --set-default ANI_CLI_QUALITY ${lib.escapeShellArg cfg.quality} \
        --set-default ANI_CLI_PLAYER ${lib.getExe player}
    '';
  };
in {
  options.custom.programs.aniCli = {
    enable = lib.mkEnableOption "ani-cli anime streaming tool (plays in Celluloid)";

    quality = lib.mkOption {
      type = lib.types.str;
      default = "best";
      description = "Preferred stream quality (best, worst, 1080, 720, ...).";
    };

    resumePlayback = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Save playback position when Celluloid closes and resume the same
        episode at that timestamp when it is played again. Positions are
        keyed on the episode title, so resuming survives ani-cli's changing
        stream URLs. `ani-cli -c` then offers the last watched episode again
        while it was quit midway, otherwise the next one.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ani-cli-wrapped];
  };
}
