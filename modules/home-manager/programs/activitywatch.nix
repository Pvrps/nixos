{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.activitywatch;
in {
  options.custom.programs.activitywatch = {
    enable = lib.mkEnableOption "ActivityWatch time tracking";
    withInput = lib.mkEnableOption "Input watcher (keypress/mouse tracking)";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.activitywatch
    ];

    systemd.user.services.activitywatch = {
      Unit = {
        Description = "ActivityWatch Server";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.activitywatch}/bin/aw-qt";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };

    systemd.user.services.activitywatch-window = lib.mkIf cfg.enable {
      Unit = {
        Description = "ActivityWatch Window Watcher";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.activitywatch}/bin/aw-watcher-window";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };

    systemd.user.services.activitywatch-afk = lib.mkIf cfg.enable {
      Unit = {
        Description = "ActivityWatch AFK Watcher";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.activitywatch}/bin/aw-watcher-afk";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };

    systemd.user.services.activitywatch-input = lib.mkIf cfg.withInput {
      Unit = {
        Description = "ActivityWatch Input Watcher";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.activitywatch}/bin/aw-watcher-input";
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}