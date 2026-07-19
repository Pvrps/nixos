{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.services.rustdesk;
  hasServer = cfg.serverFile != null && cfg.keyFile != null;
in {
  options.custom.services.rustdesk = {
    enable = lib.mkEnableOption "RustDesk system-level daemon (pre-login access and Wayland input control)";
    serverFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to a file containing the RustDesk relay/rendezvous server address. Read at runtime (e.g. a sops secret path).";
    };
    keyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to a file containing the RustDesk server public key. Read at runtime.";
    };
    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to a file containing the RustDesk permanent password (e.g. a sops secret path). Seeded into RustDesk.toml before each daemon start.";
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
      script = lib.custom.mkRustdeskConfigScript {
        configFile = "/root/.config/rustdesk/RustDesk2.toml";
        inherit (cfg) serverFile keyFile;
      };
    };

    # Runs `rustdesk --service` as root (upstream's packaging model). The
    # daemon watches logind sessions and spawns the per-session server as
    # the logged-in user (so Wayland screen capture still goes through the
    # user's desktop portal), while providing the privileged uinput IPC
    # services required for keyboard/mouse injection on Wayland. Without
    # this daemon, a plain user-mode `rustdesk --server` on Wayland is
    # view-only: input events are silently dropped.
    systemd.services.rustdesk = {
      description = "RustDesk system daemon (pre-login access, Wayland input)";
      after = ["display-manager.service"];
      wants = ["display-manager.service"];
      wantedBy = ["multi-user.target"];
      environment = {
        HOME = "/root";
        XDG_DATA_HOME = "/root/.local/share";
        XDG_CONFIG_HOME = "/root/.config";
      };
      serviceConfig =
        {
          Type = "simple";
          Restart = "always";
          RestartSec = "5s";
          KillMode = "mixed";
          LimitNOFILE = 100000;
          ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk --service";
        }
        # Enforce the permanent password before the daemon starts. Read at
        # runtime from the sops-managed file; only the path is in the store.
        // lib.optionalAttrs (cfg.passwordFile != null) {
          ExecStartPre = "${pkgs.writeShellScript "rustdesk-set-password" (lib.custom.mkRustdeskPasswordScript {
            configFile = "/root/.config/rustdesk/RustDesk.toml";
            inherit (cfg) passwordFile;
          })}";
        };
    };
  };
}
