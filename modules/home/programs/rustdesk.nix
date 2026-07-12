{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.rustdesk;
  hasServer = cfg.serverFile != null && cfg.keyFile != null;
in {
  options.custom.programs.rustdesk = {
    enable = lib.mkEnableOption "RustDesk remote desktop";
    autoStart = lib.mkEnableOption "Auto-start RustDesk server in background";
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
      description = "Path to a file containing the RustDesk permanent password (e.g. a sops secret path). Seeded into RustDesk.toml before each service start. Requires autoStart.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = hasServer;
        message = "custom.programs.rustdesk requires both serverFile and keyFile to be set; otherwise the client is installed but never configured.";
      }
    ];

    home.packages = [
      pkgs.rustdesk-flutter
    ];

    systemd.user.services.rustdesk = lib.mkIf cfg.autoStart {
      Unit = {
        Description = "RustDesk Tray/Server Service";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service =
        {
          ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk --server";
          Restart = "on-failure";
          RestartSec = 3;
        }
        # Enforce the permanent password before the server starts. Read at
        # runtime from the sops-managed file; only the path is in the store.
        // lib.optionalAttrs (cfg.passwordFile != null) {
          ExecStartPre = "${pkgs.writeShellScript "rustdesk-set-password" (lib.custom.mkRustdeskPasswordScript {
            configFile = "$HOME/.config/rustdesk/RustDesk.toml";
            inherit (cfg) passwordFile;
          })}";
        };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };

    # On first activation only (file absent), write RustDesk2.toml with server
    # config. Both server address and key are read at activation time from the
    # sops-managed files. RustDesk owns the file from that point forward.
    home.activation.rustdeskConfig = lib.mkIf hasServer (
      lib.hm.dag.entryAfter ["writeBoundary"] (lib.custom.mkRustdeskConfigScript {
        configFile = "$HOME/.config/rustdesk/RustDesk2.toml";
        inherit (cfg) serverFile keyFile;
      })
    );
  };
}
