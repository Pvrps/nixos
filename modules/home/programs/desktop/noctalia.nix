{
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.noctalia;
  niriEnabled = config.custom.programs.niri.enable;
in {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  options.custom.programs.noctalia = {
    enable = lib.mkEnableOption "Noctalia shell (v5, native/Luau)";
    primaryMonitor = lib.mkOption {
      type = lib.types.str;
      description = "Wayland output name used for the lock screen and notifications. Required when noctalia is enabled.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.system.wayland.enable;
        message = "noctalia module requires a Wayland compositor to be enabled (e.g. custom.programs.niri.enable = true).";
      }
    ];

    programs.noctalia = {
      enable = true;
      # Started by niri's `spawn-at-startup` below, as a plain compositor
      # child (not a systemd user unit) — leave the module's own service off.
      systemd.enable = false;

      settings = {
        dock.enabled = false;
        wallpaper.enabled = true;

        location = {
          address = "Ontario"; # fallback only; auto_locate wins when it resolves
          auto_locate = true;
        };

        weather.enabled = true; # required for the weather widget/data to work at all

        calendar.enabled = true;

        # Theme mode/palette/opacity/font/wallpaper-path come from Stylix's
        # own built-in `noctalia` target (auto-enabled; see
        # home-manager's modules/noctalia/hm.nix), not set here — it maps
        # the same base16 scheme to the same mPrimary/mOnPrimary/... roles
        # v4's hand-written colorschemes/Stylix.json used, plus terminal
        # colors, dock/notification/osd opacity, and the shell font.
        theme.templates = {
          enable_builtin_templates = true;
          builtin_ids = ["btop" "foot" "starship"] ++ lib.optional niriEnabled "niri";
        };

        # v4's four independent radiusRatio/iRadiusRatio/boxRadiusRatio/
        # screenRadiusRatio knobs (all 0) collapse into one v5 scale.
        shell = {
          corner_radius_scale = 0;
          card_borders = true; # v4: ui.boxBorderEnabled
          # v4: appLauncher.overviewLayer — type-to-launch from niri overview.
          niri_overview_type_to_launch_enabled = true;

          launcher = {
            sort_by_usage = true; # v4: appLauncher.sortByMostUsed
            categories = false;
            compact = true;
          };

          screenshot = {
            directory = "${config.home.homeDirectory}/Pictures/Screenshots";
            filename_pattern = "%Y-%m-%d_%H-%M-%S";
            save_to_file = true;
            copy_to_clipboard = true;
            freeze_screen = true;
            annotate = false; # kept fast for Mod+Shift+S; see screenshot-annotate below
            close_on_copy = true;
          };
        };

        accessibility.ui_scale = 0.75; # v4: general.scaleRatio

        lockscreen.monitors = [cfg.primaryMonitor]; # v4: general.lockScreenMonitors

        notification = {
          position = "top_right";
          monitors = [cfg.primaryMonitor];
        };

        bar.default = {
          scale = 1.0;
          margin_ends = 0; # bar spans the full screen width
          radius = 0;
          capsule = true;

          start = ["launcher" "group:info" "group:sysmon" "group:window"];
          center = ["workspaces"];
          end = ["tray" "notifications" "battery" "volume" "control-center"];

          capsule_group = [
            {
              id = "info";
              members = ["clock" "weather"];
            }
            {
              id = "sysmon";
              members = ["cpu" "gpu"];
            }
            {
              id = "window";
              members = ["active_window" "media"];
            }
          ];
        };

        widget = {
          cpu = {
            type = "sysmon";
            stat = "cpu_usage";
          };
          # v4: SystemMonitor.showGpuTemp — dedicated GPU stat widget, since
          # v5 shows one stat per sysmon instance (hover still surfaces the
          # rest of the sampled stats on either widget).
          gpu = {
            type = "sysmon";
            stat = "gpu_temp";
          };
        };
      };
    };

    home.persistence."/persist".directories = [".cache/noctalia"];

    custom.programs.niri = lib.mkIf niriEnabled {
      startupCommands = [
        ''"noctalia"''
        ''"blueman-applet"''
      ];

      keybinds = [
        ''Mod+D { spawn "noctalia" "msg" "panel-toggle" "launcher"; }''
        ''Mod+C { spawn "noctalia" "msg" "panel-toggle" "control-center"; }''
        ''Mod+Shift+L { spawn "noctalia" "msg" "session" "lock"; }''
        # Replaces the grim/slurp screenshot-tool script: fast region
        # capture, save + copy, no editor (see [shell.screenshot] above).
        ''Mod+Shift+S { spawn "noctalia" "msg" "screenshot-region"; }''
        # Replaces the satty-based editing-tool script for the image case:
        # freezes every monitor and opens the built-in annotation editor
        # (crop/draw/etc.), then Copy/Save applies the same output policy.
        # No equivalent exists for editing-tool's clipboard-video branch
        # (losslesscut) — that workflow has no noctalia counterpart.
        ''Mod+Shift+E { spawn "noctalia" "msg" "screenshot-annotate"; }''
      ];

      layerRulesConfig = ''
        layer-rule {
            match namespace=r#"^noctalia-notification"#
            block-out-from "screen-capture"
        }
      '';
    };
  };
}
