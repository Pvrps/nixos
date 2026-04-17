{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.rustdesk;
  hasServer = cfg.server != "" && cfg.keyFile != "";
in {
  options.custom.programs.rustdesk = {
    enable = lib.mkEnableOption "RustDesk remote desktop";
    autoStart = lib.mkEnableOption "Auto-start RustDesk server in background";
    server = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "RustDesk relay/rendezvous server address (IP or hostname).";
    };
    keyFile = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to a file containing the RustDesk server public key.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.rustdesk-flutter
    ];

    systemd.user.services.rustdesk = lib.mkIf cfg.autoStart {
      Unit = {
        Description = "RustDesk Tray/Server Service";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk --server";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };

    # On first activation only (file absent), write RustDesk2.toml with server
    # config. The key is read at activation time from the sops-managed keyFile.
    # RustDesk owns the file from that point forward.
    home.activation.rustdeskConfig = lib.mkIf hasServer (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        config_file="$HOME/.config/rustdesk/RustDesk2.toml"
        if [ ! -f "$config_file" ]; then
          key=$(cat ${cfg.keyFile} | tr -d '\n')
          mkdir -p "$HOME/.config/rustdesk"
          cat > "$config_file" <<EOF
        rendezvous_server = "${cfg.server}"
        relay_server = "${cfg.server}"
        api_server = ""
        key = "$key"

        [options]
        custom-rendezvous-server = "${cfg.server}"
        relay-server = "${cfg.server}"
        key = "$key"
        EOF
        fi
      ''
    );
  };
}
