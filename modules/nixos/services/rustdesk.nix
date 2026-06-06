{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.services.rustdesk;
  hasServer = cfg.server != "" && cfg.keyFile != "";
in {
  options.custom.services.rustdesk = {
    enable = lib.mkEnableOption "RustDesk system-level daemon (pre-login access)";
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
    environment.systemPackages = [pkgs.rustdesk-flutter];

    # Write RustDesk2.toml for root on first boot (file absent = never written).
    # rustdesk owns the file from that point forward; we don't overwrite.
    systemd.services.rustdesk-config = lib.mkIf hasServer {
      description = "Write RustDesk system config on first boot";
      before = ["rustdesk.service"];
      wantedBy = ["rustdesk.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        config_file="/root/.config/rustdesk/RustDesk2.toml"
        if [ ! -f "$config_file" ]; then
          key=$(tr -d '\n' < ${cfg.keyFile})
          mkdir -p /root/.config/rustdesk
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
      '';
    };

    systemd.services.rustdesk = {
      description = "RustDesk system daemon (pre-login remote access)";
      after = ["display-manager.service"];
      wants = ["display-manager.service"];
      wantedBy = ["multi-user.target"];
      environment = {
        HOME = "/root";
        XDG_DATA_HOME = "/root/.local/share";
        XDG_CONFIG_HOME = "/root/.config";
      };
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
        # Find the SDDM Xauthority file so the daemon can attach to :0
        # before any user logs in.
        ExecStart = let
          script = pkgs.writeShellScript "rustdesk-system" ''
            for f in /run/sddm/xauth_* /var/run/sddm/xauth_*; do
              [ -f "$f" ] && export XAUTHORITY="$f" && break
            done
            export DISPLAY=:0
            exec ${pkgs.rustdesk-flutter}/bin/rustdesk --server
          '';
        in "${script}";
      };
    };
  };
}
