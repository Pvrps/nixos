{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.ani-cli;
in {
  options.custom.programs.ani-cli = {
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
        Save playback position on quit and resume the same episode at that
        timestamp when replayed (mpv watch-later, scoped to ani-cli only).
        Resume works as long as the provider returns the same stream URL.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Default nixpkgs build bundles mpv as the playback backend (withMpv = true).
    # Clapper can't receive the HTTP Referer header ani-cli streams require,
    # so mpv is used only for ani-cli playback; Clapper stays the MIME default.
    home.packages = [pkgs.ani-cli];

    home.sessionVariables =
      {
        ANI_CLI_QUALITY = cfg.quality;
      }
      // lib.optionalAttrs cfg.resumePlayback {
        # ani-cli matches "mpv*" in its player dispatch, so extra flags pass through.
        ANI_CLI_PLAYER = "mpv --save-position-on-quit";
      };
  };
}
