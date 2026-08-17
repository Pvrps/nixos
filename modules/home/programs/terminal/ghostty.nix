{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.ghostty;
  palette = lib.custom.mkTerminalPalette config.lib.stylix.colors;
  ansi = [
    palette.normal.black
    palette.normal.red
    palette.normal.green
    palette.normal.yellow
    palette.normal.blue
    palette.normal.magenta
    palette.normal.cyan
    palette.normal.white
    palette.bright.black
    palette.bright.red
    palette.bright.green
    palette.bright.yellow
    palette.bright.blue
    palette.bright.magenta
    palette.bright.cyan
    palette.bright.white
  ];
in {
  options.custom.programs.ghostty.enable = lib.mkEnableOption "Ghostty terminal emulator";

  config = lib.mkIf cfg.enable {
    assertions = [(lib.custom.mkRequireWayland config "ghostty")];

    stylix.targets.ghostty.enable = false;

    programs.ghostty = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;

      settings = {
        font-family = config.stylix.fonts.monospace.name;
        font-size = config.stylix.fonts.sizes.terminal;

        background-opacity = config.stylix.opacity.terminal;
        background = "#${config.lib.stylix.colors.base00}";
        foreground = "#${config.lib.stylix.colors.base05}";

        palette = lib.imap0 (i: c: "${toString i}=#${c}") ansi;

        window-decoration = false;
        window-padding-x = 4;
        window-padding-y = 4;

        gtk-single-instance = true;

        window-inherit-working-directory = false;
      };
    };

    custom.programs.niri.defaultTerminal = lib.mkDefault "ghostty";

    custom.programs.termfilepickers.terminal.command = lib.mkDefault [
      "${pkgs.ghostty}/bin/ghostty"
      "--class=file-chooser"
    ];
    custom.programs.termfilepickers.terminal.execArgs = lib.mkDefault ["-e"];

    custom.programs.niri.windowRulesConfig = lib.mkIf config.custom.programs.niri.enable ''
      window-rule {
          match app-id="ghostty"
          draw-border-with-background false
      }

      window-rule {
          match app-id="file-chooser"
          draw-border-with-background false
      }
    '';
  };
}
