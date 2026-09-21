{
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.bottles;
in {
  options.custom.programs.bottles.enable = lib.mkEnableOption "Bottles (Wine container manager) via Flatpak";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.custom.programs.flatpak.enable;
        message = "custom.programs.bottles requires custom.programs.flatpak.enable = true.";
      }
    ];

    custom.programs.flatpak.packages = lib.mkAfter ["com.usebottles.bottles"];
  };
}
