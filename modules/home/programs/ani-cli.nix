{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.aniCli;

  # mpv wrapper that resumes an episode at the last watched timestamp.
  #
  # mpv's built-in watch-later keys saved positions on the stream URL, but
  # ani-cli scrapes a fresh URL every run, so positions would never match.
  # Instead we key on the media title ("<anime> Episode <n>"), which is
  # stable across runs, by giving each episode its own watch-later directory.
  #
  # The name must start with "mpv" so ani-cli's player dispatch matches the
  # "mpv*" branch and passes the required --referrer flag.
  mpvResume = pkgs.writeShellScriptBin "mpv-ani-cli" ''
    title=""
    for arg in "$@"; do
      case "$arg" in
        --force-media-title=*) title="''${arg#--force-media-title=}" ;;
      esac
    done
    key=$(printf '%s' "$title" | tr -cs '[:alnum:]._-' '_')
    dir="''${XDG_STATE_HOME:-$HOME/.local/state}/ani-cli/watch-later/''${key:-default}"
    mkdir -p "$dir"

    # Resume from the most recent saved position, if any. Files are removed
    # after reading; mpv rewrites one on quit (or not, if watched to the end).
    latest=$(ls -t "$dir" 2>/dev/null | head -n1)
    if [ -n "$latest" ]; then
      pos=$(sed -n 's/^start=//p' "$dir/$latest" | head -n1)
      rm -f "$dir"/*
      [ -n "$pos" ] && set -- --start="$pos" "$@"
    fi

    exec ${lib.getExe pkgs.mpv} \
      --save-position-on-quit \
      --watch-later-options=start \
      --watch-later-directory="$dir" \
      "$@"
  '';

  # "Continue watching" that, unlike `ani-cli -c`, replays the last watched
  # episode when it was quit midway (mpv-ani-cli then resumes the timestamp).
  # Falls back to `ani-cli -c` (next episode) when the episode was finished.
  #
  # The last watched episode is derived from the newest watch-later directory;
  # a watch_later file inside it means playback stopped before the end.
  aniResume = pkgs.writeShellScriptBin "ani-resume" ''
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/ani-cli/watch-later"
    latest=$(ls -t "$state" 2>/dev/null | head -n1)

    if [ -n "$latest" ] && [ -n "$(ls -A "$state/$latest" 2>/dev/null)" ]; then
      # Key format: <anime_title>_Episode_<n> (see mpv-ani-cli).
      ep="''${latest##*_Episode_}"
      query=$(printf '%s' "''${latest%_Episode_*}" | tr '_' ' ')
      printf 'Resuming: %s - episode %s\n' "$query" "$ep"
      exec ani-cli -e "$ep" "$query"
    fi

    exec ani-cli -c
  '';

  # Bake env defaults into the binary instead of home.sessionVariables so
  # they work in any context without re-login (still overridable per-run).
  ani-cli-wrapped = pkgs.symlinkJoin {
    name = "ani-cli-wrapped";
    paths = [pkgs.ani-cli];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/ani-cli \
        --set-default ANI_CLI_QUALITY ${lib.escapeShellArg cfg.quality} \
        ${lib.optionalString cfg.resumePlayback "--set-default ANI_CLI_PLAYER mpv-ani-cli"}
    '';
  };
in {
  options.custom.programs.aniCli = {
    enable = lib.mkEnableOption "ani-cli anime streaming tool";

    quality = lib.mkOption {
      type = lib.types.str;
      default = "best";
      description = "Preferred stream quality (best, worst, 1080, 720, ...).";
    };

    resumePlayback = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Save playback position when mpv quits and resume the same episode at
        that timestamp when it is played again. Positions are keyed on the
        episode title, so resuming survives ani-cli's changing stream URLs.
        Also provides `ani-resume`: replays the last watched episode if it
        was quit midway, otherwise continues with the next one (like -c).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Default nixpkgs build bundles mpv as the playback backend (withMpv = true).
    # Clapper can't receive the HTTP Referer header ani-cli streams require,
    # so mpv is used only for ani-cli playback; Clapper stays the MIME default.
    home.packages = [ani-cli-wrapped] ++ lib.optionals cfg.resumePlayback [mpvResume aniResume];
  };
}
