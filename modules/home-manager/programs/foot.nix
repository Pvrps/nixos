{
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.foot;
in {
  options.custom.programs.foot.enable = lib.mkEnableOption "Foot terminal emulator";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.system.wayland.enable;
        message = "foot module requires a Wayland compositor to be enabled (e.g. custom.programs.niri.enable = true).";
      }
    ];

    stylix.targets.foot.enable = false;

    programs.foot = {
      enable = true;
      settings = {
        main = {
          font = "${config.stylix.fonts.monospace.name}:size=${toString config.stylix.fonts.sizes.terminal}";
          dpi-aware = "no";
        };
        "colors-dark" = {
          alpha = config.stylix.opacity.terminal;
          foreground = config.lib.stylix.colors.base05;
          background = config.lib.stylix.colors.base00;
          regular0 = config.lib.stylix.colors.base00;
          regular1 = config.lib.stylix.colors.base08;
          regular2 = config.lib.stylix.colors.base0B;
          regular3 = config.lib.stylix.colors.base0A;
          regular4 = config.lib.stylix.colors.base0D;
          regular5 = config.lib.stylix.colors.base0E;
          regular6 = config.lib.stylix.colors.base0C;
          regular7 = config.lib.stylix.colors.base05;
          bright0 = config.lib.stylix.colors.base03;
          bright1 = config.lib.stylix.colors.base08;
          bright2 = config.lib.stylix.colors.base0B;
          bright3 = config.lib.stylix.colors.base0A;
          bright4 = config.lib.stylix.colors.base0D;
          bright5 = config.lib.stylix.colors.base0E;
          bright6 = config.lib.stylix.colors.base0C;
          bright7 = config.lib.stylix.colors.base07;
          "16" = config.lib.stylix.colors.base09;
          "17" = config.lib.stylix.colors.base0F;
          "18" = config.lib.stylix.colors.base01;
          "19" = config.lib.stylix.colors.base02;
          "20" = config.lib.stylix.colors.base04;
          "21" = config.lib.stylix.colors.base06;
        };
      };
    };

    # Use mkDefault so that if another terminal module is enabled and also sets
    # defaultTerminal, Nix's module system raises a conflict error — the same
    # mutual-exclusion mechanism used by dankmaterialshell/noctalia.
    custom.programs.niri.defaultTerminal = lib.mkDefault "foot";
  };
}
