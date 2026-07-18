{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.devenv;
  vscodeEnabled = config.custom.programs.vscode.enable or false;

  # Path to the centralized devenv profiles directory (relative to this module).
  # toString forces it into the nix store so builtins.readDir and readFile work
  # during flake evaluation.
  modulesDir = toString ../../devenv;
  profileEntries = builtins.attrNames (builtins.readDir modulesDir);

  profilesWithInit =
    lib.filter (
      dir:
        builtins.pathExists "${modulesDir}/${dir}/init.sh"
    )
    profileEntries;

  # For each profile with an init.sh, create a dev-init-<lang> binary.
  # The @MODULES_DIR@ placeholder in init.sh is replaced with the absolute
  # path to modules/devenv/ so the script can write correct devenv.yaml imports.
  initPackages =
    map (
      lang:
        pkgs.writeShellApplication {
          name = "dev-init-${lang}";
          runtimeInputs = [pkgs.devenv pkgs.direnv pkgs.git pkgs.gum];
          text = lib.replaceStrings ["@MODULES_DIR@"] [modulesDir] (
            builtins.readFile "${modulesDir}/${lang}/init.sh"
          );
        }
    )
    profilesWithInit;
in {
  options.custom.programs.devenv = {
    enable = lib.mkEnableOption "devenv.sh per-project developer environments";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.devenv] ++ initPackages;

    # direnv + nix-direnv for fast, reliable shell activation.
    # The mkhl.direnv VSCode extension propagates devenv env vars (like
    # JAVA_HOME) to VSCode's language server processes, not just the terminal.
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # When vscode is also enabled, install the mkhl.direnv extension.
    # This is devenv's officially recommended VSCode integration.
    programs.vscode.profiles.default.extensions = lib.mkIf vscodeEnabled (
      with pkgs.vscode-extensions; [
        mkhl.direnv
      ]
    );
  };
}
