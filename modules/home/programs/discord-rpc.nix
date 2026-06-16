{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.discord-rpc;

  # Python daemon: connects to arRPC bridge WebSocket (ws://127.0.0.1:1337),
  # sends the active profile's activity JSON, and keeps the connection alive
  # with periodic pings so Discord maintains the status.
  # Reads the active profile name from ~/.local/share/discord-rpc/current,
  # loads the profile JSON from ~/.config/discord-rpc/profiles/<name>.json.
  # On SIGTERM/SIGINT: sends null activity to clear status before exiting.
  drpc-daemon = pkgs.writeShellApplication {
    name = "drpc-daemon";
    runtimeInputs = [
      (pkgs.python3.withPackages (p: [p.websockets]))
    ];
    text = ''
      exec python3 ${./discord-rpc/daemon.py}
    '';
  };

  # drpc: user-facing CLI for managing the discord-rpc systemd service and profiles
  drpc = pkgs.writeShellApplication {
    name = "drpc";
    runtimeInputs = [pkgs.jq];
    text = builtins.readFile ./discord-rpc/drpc.sh;
  };
in {
  options.custom.programs.discord-rpc = {
    enable = lib.mkEnableOption "Custom Discord RPC CLI with profiles via arRPC";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.arrpc.enable;
        message = "custom.programs.discord-rpc requires custom.programs.arrpc.enable = true.";
      }
    ];

    home.packages = [drpc drpc-daemon];

    # Ensure profile and state directories exist
    home.file = {
      ".config/discord-rpc/profiles/.keep".text = "";
      ".local/share/discord-rpc/.keep".text = "";
    };

    # Systemd user service — started on demand by `drpc enable`, not auto-started
    systemd.user.services.discord-rpc = {
      Unit = {
        Description = "Discord custom RPC status daemon";
        After = ["arrpc.service"];
        Requires = ["arrpc.service"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${drpc-daemon}/bin/drpc-daemon";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      # No Install.WantedBy — only started on demand via `drpc enable`
    };
  };
}
