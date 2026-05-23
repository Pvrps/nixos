{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.arrpc;

  # We use the PR #143 branch of arrpc which drastically improves Linux/Proton game detection.
  # The patch adds:
  #   - ARRPC_BRIDGE_HOST support (binds WebSocket bridge to 127.0.0.1 by default)
  #   - broader path-segment matching for non-Steam Linux native game detection
  #   - Steam reaper detection: parses AppId= from Steam's reaper wrapper process and
  #     cross-references third_party_skus in the detectable DB, fixing games like
  #     Forza Horizon 6 that have no executables[] entry
  patched-arrpc = pkgs.arrpc.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "OpenAsar";
      repo = "arrpc";
      rev = "refs/pull/143/head";
      hash = "sha256-TBVrQN/QoBRKZOgN8Yr0gP0Fn0M+BeojoL3RpKOo5NU=";
    };

    patches = [../patches/arrpc.patch];
  });
in {
  options.custom.programs.arrpc.enable = lib.mkEnableOption "arRPC background service for Discord Rich Presence";

  config = lib.mkIf cfg.enable {
    systemd.user.services.arrpc = {
      Unit = {
        Description = "arRPC local Rich Presence server";
        After = ["network.target"];
      };
      Service = {
        ExecStart = "${patched-arrpc}/bin/arrpc";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    home.packages = [
      patched-arrpc
    ];
  };
}
