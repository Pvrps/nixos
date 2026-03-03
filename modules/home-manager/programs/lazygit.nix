{
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.lazygit;
in {
  options.custom.programs.lazygit.enable = lib.mkEnableOption "Lazygit terminal UI for git";

  config = lib.mkIf cfg.enable {
    programs.lazygit = {
      enable = true;

      enableZshIntegration = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };
  };
}
