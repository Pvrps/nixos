{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.rustdesk;
in {
  options.custom.programs.rustdesk = {
    enable = lib.mkEnableOption "RustDesk remote desktop";
    autoStart = lib.mkEnableOption "Auto-start RustDesk server in background";
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
  };
}
