{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.ghostty;
in {
  options.custom.programs.ghostty.enable = lib.mkEnableOption "Ghostty terminal emulator";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.system.wayland.enable;
        message = "Ghostty module requires a Wayland compositor to be enabled.";
      }
    ];

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

        palette = [
          "0=#${config.lib.stylix.colors.base00}"
          "1=#${config.lib.stylix.colors.base08}"
          "2=#${config.lib.stylix.colors.base0B}"
          "3=#${config.lib.stylix.colors.base0A}"
          "4=#${config.lib.stylix.colors.base0D}"
          "5=#${config.lib.stylix.colors.base0E}"
          "6=#${config.lib.stylix.colors.base0C}"
          "7=#${config.lib.stylix.colors.base05}"
          "8=#${config.lib.stylix.colors.base03}"
          "9=#${config.lib.stylix.colors.base08}"
          "10=#${config.lib.stylix.colors.base0B}"
          "11=#${config.lib.stylix.colors.base0A}"
          "12=#${config.lib.stylix.colors.base0D}"
          "13=#${config.lib.stylix.colors.base0E}"
          "14=#${config.lib.stylix.colors.base0C}"
          "15=#${config.lib.stylix.colors.base07}"
        ];

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

    custom.programs.niri.windowRules = lib.mkIf config.custom.programs.niri.enable [
      ''
        window-rule {
          match app-id="ghostty"
          draw-border-with-background false
        }
      ''
      ''
        window-rule {
          match app-id="file-chooser"
          draw-border-with-background false
        }
      ''
    ];
  };
}
