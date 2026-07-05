{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.profile.sveltekit;
in {
  options.profile.sveltekit = {
    enable = lib.mkEnableOption "SvelteKit + Bun development stack";

    bun.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Bun runtime/package manager.";
    };

    lsp.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable TypeScript language server.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Extra packages to add to the environment (e.g. ffmpeg, python3 for scripts).";
    };

    extraPythonPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Python packages to install alongside the extra python3 (e.g. pydub).";
    };
  };

  config = lib.mkIf cfg.enable {
    languages.javascript = {
      enable = true;
      bun.enable = cfg.bun.enable;
      lsp.enable = cfg.lsp.enable;
    };

    packages =
      cfg.extraPackages
      ++ lib.optional (cfg.extraPythonPackages != []) (
        pkgs.python3.withPackages (_: cfg.extraPythonPackages)
      );
  };
}
