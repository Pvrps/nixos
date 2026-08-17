{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.prismlauncher;
in {
  options.custom.programs.prismlauncher.enable = lib.mkEnableOption "Prism Launcher for Minecraft";

  config = lib.mkIf cfg.enable {
    home.packages = [
      # Override Prism to bundle and expose specific Temurin Java versions internally
      (pkgs.prismlauncher.override {
        jdks = [
          pkgs.temurin-bin-8
          pkgs.temurin-bin-17
          pkgs.temurin-bin-21
          pkgs.temurin-bin-25
        ];
      })
    ];
  };
}
