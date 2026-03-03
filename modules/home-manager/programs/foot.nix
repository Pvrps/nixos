{lib, config, ...}: let
  cfg = config.custom.programs.foot;
in {
  options.custom.programs.foot.enable = lib.mkEnableOption "Foot terminal emulator";

  config = lib.mkIf cfg.enable {
    programs.foot = {
      enable = true;
      settings = {
      };
    };
  };
}
