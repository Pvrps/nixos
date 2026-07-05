{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.profile.python;
in {
  options.profile.python = {
    enable = lib.mkEnableOption "Python development stack";

    pythonPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.python313;
      description = "Python interpreter package to use.";
    };

    uv = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable uv package manager.";
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.uv;
        description = "uv package.";
      };
    };

    lsp.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Pyright language server.";
    };

    ruff.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable ruff linter/formatter (via git-hooks + PATH).";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extra packages to add to the environment (e.g. ffmpeg, unzip, system tools).";
    };

    nativeLibs = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Native libraries to add to LD_LIBRARY_PATH (e.g. xorg.libX11 for tkinter).";
    };
  };

  config = lib.mkIf cfg.enable {
    languages.python = {
      enable = true;
      package = cfg.pythonPackage;

      uv = {
        enable = cfg.uv.enable;
        package = cfg.uv.package;
      };

      lsp.enable = cfg.lsp.enable;
    };

    packages =
      [cfg.uv.package]
      ++ lib.optional cfg.ruff.enable pkgs.ruff
      ++ cfg.extraPackages;

    env.LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath cfg.nativeLibs;
  };
}
