{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.foot;
  palette = lib.custom.mkTerminalPalette config.lib.stylix.colors;
in {
  options.custom.programs.foot = {
    enable = lib.mkEnableOption "Foot terminal emulator";
    pad = lib.mkOption {
      type = lib.types.str;
      default = "4x4";
      description = "Internal padding inside the terminal window, in the format WxH (logical pixels).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [(lib.custom.mkRequireWayland config "foot")];

    stylix.targets.foot.enable = false;

    programs.foot = {
      enable = true;
      settings = {
        main = {
          font = "${config.stylix.fonts.monospace.name}:size=${toString config.stylix.fonts.sizes.terminal}";
          dpi-aware = "no";
          pad = config.custom.programs.foot.pad;
        };
        "colors-dark" = lib.mkIf config.stylix.enable {
          alpha = config.stylix.opacity.terminal;
          foreground = config.lib.stylix.colors.base05;
          background = config.lib.stylix.colors.base00;
          regular0 = palette.normal.black;
          regular1 = palette.normal.red;
          regular2 = palette.normal.green;
          regular3 = palette.normal.yellow;
          regular4 = palette.normal.blue;
          regular5 = palette.normal.magenta;
          regular6 = palette.normal.cyan;
          regular7 = palette.normal.white;
          bright0 = palette.bright.black;
          bright1 = palette.bright.red;
          bright2 = palette.bright.green;
          bright3 = palette.bright.yellow;
          bright4 = palette.bright.blue;
          bright5 = palette.bright.magenta;
          bright6 = palette.bright.cyan;
          bright7 = palette.bright.white;
          "16" = config.lib.stylix.colors.base09;
          "17" = config.lib.stylix.colors.base0F;
          "18" = config.lib.stylix.colors.base01;
          "19" = config.lib.stylix.colors.base02;
          "20" = config.lib.stylix.colors.base04;
          "21" = config.lib.stylix.colors.base06;
        };
      };
    };

    custom.programs = {
      # Use mkDefault so that if another terminal module is enabled and also sets
      # defaultTerminal, Nix's module system raises a conflict error — the same
      # mutual-exclusion mechanism used by dankmaterialshell/noctalia.
      niri.defaultTerminal = lib.mkDefault "foot";

      termfilepickers.terminal = {
        command = lib.mkDefault [
          "${pkgs.foot}/bin/foot"
          "--app-id=file-chooser"
        ];
        execArgs = lib.mkDefault ["-e"];
      };
    };
  };
}
