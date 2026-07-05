{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.profile.java;
in {
  options.profile.java = {
    enable = lib.mkEnableOption "Java development stack";

    jdkPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.jdk21;
      description = "JDK package to use for this project.";
    };

    nativeLibs = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Native libraries to add to LD_LIBRARY_PATH (e.g. for LWJGL/AWT clients).";
    };
  };

  config = lib.mkIf cfg.enable {
    languages.java = {
      enable = true;
      jdk.package = cfg.jdkPackage;
      maven.enable = true;
      gradle.enable = true;
      lsp.enable = true;
    };

    env.LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath cfg.nativeLibs;
  };
}
