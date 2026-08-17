{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.liquidctl;
in {
  options.custom.programs.liquidctl = {
    enable = lib.mkEnableOption "liquidctl NZXT Kraken LCD control";

    lcdImage = lib.mkOption {
      type = lib.types.path;
      description = "Path to image or GIF to display on the Kraken LCD screen.";
    };

    brightness = lib.mkOption {
      type = lib.types.ints.between 0 100;
      default = 50;
      description = "LCD screen brightness (0-100).";
    };

    orientation = lib.mkOption {
      type = lib.types.enum [0 90 180 270];
      default = 0;
      description = "LCD screen orientation in degrees.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.liquidctl];

    systemd.user.services.liquidctl-lcd = {
      Unit = {
        Description = "Set NZXT Kraken LCD screen image";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "liquidctl-lcd-set" ''
          ${pkgs.liquidctl}/bin/liquidctl --match "Kraken" initialize
          ${pkgs.liquidctl}/bin/liquidctl --match "Kraken" set lcd screen brightness ${toString cfg.brightness}
          ${pkgs.liquidctl}/bin/liquidctl --match "Kraken" set lcd screen orientation ${toString cfg.orientation}
          ${pkgs.liquidctl}/bin/liquidctl --match "Kraken" set lcd screen gif ${cfg.lcdImage}
        '';
        RemainAfterExit = true;
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
