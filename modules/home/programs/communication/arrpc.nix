{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.arrpc;

  # WORKAROUND: arrpc PR #143 (Linux/Proton game detection), see WORKAROUNDS.md
  patched-arrpc = pkgs.arrpc.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "OpenAsar";
      repo = "arrpc";
      # Bump rev+hash together, see WORKAROUNDS.md
      rev = "d2ecb61697f3986149350078dd9853592a9086ea";
      hash = "sha256-wDNt9kTccDTn1nQb8KCMhrSJ3YPfhxikuZBzBV8/EWo=";
    };

    patches = [../../patches/arrpc.patch];
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
