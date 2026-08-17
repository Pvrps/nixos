{
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.pinta;
in {
  options.custom.programs.pinta.enable = lib.mkEnableOption "Pinta image editor";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.flatpak.enable;
        message = "custom.programs.pinta requires custom.programs.flatpak.enable = true.";
      }
    ];

    custom.programs.flatpak.packages = ["com.github.PintaProject.Pinta"];
  };
}
