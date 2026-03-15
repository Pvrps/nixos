{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.arrpc;

  # We use the PR #143 branch of arrpc which drastically improves Linux/Proton game detection
  patched-arrpc = pkgs.arrpc.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "OpenAsar";
      repo = "arrpc";
      rev = "refs/pull/143/head";
      hash = "sha256-LcwRkhggvHsMk29Gmjs68tAV675Zc8fqpgi4xglWfBI=";
    };

    patches = [./arrpc.patch];
  });

  # Script to fetch the latest Discord detectable games database
  fetch-arrpc-db = pkgs.writeShellScript "fetch-arrpc-db" ''
    mkdir -p ~/.config/arrpc
    # Fetch the live database from Discord's API
    ${pkgs.curl}/bin/curl -sL "https://discordapp.com/api/v8/applications/detectable" -o ~/.config/arrpc/detectable.json.tmp

    # Only replace if the download was successful (valid JSON)
    if ${pkgs.jq}/bin/jq -e . ~/.config/arrpc/detectable.json.tmp >/dev/null 2>&1; then
      mv ~/.config/arrpc/detectable.json.tmp ~/.config/arrpc/detectable.json
    else
      rm -f ~/.config/arrpc/detectable.json.tmp
    fi
  '';
in {
  options.custom.programs.arrpc.enable = lib.mkEnableOption "arRPC background service for Discord Rich Presence";

  config = lib.mkIf cfg.enable {
    systemd.user.services.arrpc = {
      Unit = {
        Description = "arRPC local Rich Presence server";
        After = ["network.target"];
      };
      Service = {
        # Fetch the latest DB before starting arRPC
        ExecStartPre = "${fetch-arrpc-db}";
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
