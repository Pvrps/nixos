{
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.yazi;
in {
  options.custom.programs.yazi.enable = lib.mkEnableOption "Yazi terminal file manager";

  config = lib.mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
  };
}
