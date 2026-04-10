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
    useAwatcher = lib.mkEnableOption "Use awatcher instead of default watchers (works on X11 and Wayland)";
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      [pkgs.activitywatch]
      ++ lib.optionals cfg.useAwatcher [pkgs.awatcher];

    systemd.user.services = {
      activitywatch = {
        Unit = {
          Description = "ActivityWatch Server";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          ExecStart = "${pkgs.activitywatch}/bin/aw-server";
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };

      # awatcher replaces aw-watcher-window + aw-watcher-afk on both X11 and Wayland
      awatcher = lib.mkIf cfg.useAwatcher {
        Unit = {
          Description = "Awatcher - window and idle watcher (X11 + Wayland)";
          After = ["graphical-session.target" "activitywatch.service"];
          Requires = ["activitywatch.service"];
          PartOf = ["graphical-session.target"];
        };
        Service = {
          ExecStart = "${pkgs.awatcher}/bin/awatcher";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = ["graphical-session.target"];
        };
      };

      # Default watchers for X11-only environments (e.g. mickey with Plasma/X11)
      activitywatch-window = lib.mkIf (!cfg.useAwatcher) {
        Unit = {
          Description = "ActivityWatch Window Watcher";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          Requires = ["activitywatch.service"];
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

      activitywatch-afk = lib.mkIf (!cfg.useAwatcher) {
        Unit = {
          Description = "ActivityWatch AFK Watcher";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          Requires = ["activitywatch.service"];
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

      activitywatch-input = lib.mkIf cfg.withInput {
        Unit = {
          Description = "ActivityWatch Input Watcher";
          After = ["graphical-session.target"];
          PartOf = ["graphical-session.target"];
          Requires = ["activitywatch.service"];
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
  };
}
