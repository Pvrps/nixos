# Shared dev profile: editors (zed, optional vscode), opencode AI assistant,
# Java toolchain, and dev helper scripts. The opencode context7 secret path is
# supplied by the consumer (host-specific sops path).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.profiles.dev;
in {
  options.custom.profiles.dev = {
    enable = lib.mkEnableOption "Development profile (zed, opencode, java, dev scripts)";
    context7ApiKeyPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to the Context7 API key file (e.g. a sops secret path).";
    };
  };

  config = lib.mkIf cfg.enable {
    custom = {
      scripts = {
        gitingest.enable = true;
        ports-summary.enable = true;
        dir2clip.enable = true;
      };

      programs = {
        zed = {
          enable = true;
          extensions = [
            "nix"
            "java"
            "svelte"
            "xml"
            "dockerfile"
            "nginx"
            "graphql"
            "sql"
            "jsonnet"
            "just"
            "toml"
          ];
        };

        opencode = {
          enable = true;
          context7 = {
            enable = cfg.context7ApiKeyPath != null;
            apiKeyPath = lib.mkIf (cfg.context7ApiKeyPath != null) cfg.context7ApiKeyPath;
          };
          claudeAuth.enable = true;
          mcp-nixos.enable = true;
        };

        java.enable = true;

        vscode = {
          enable = false;
          javaFormatterConfig = ../../users/purps/files/eclipse-formatter.xml;
          extensions = with pkgs.vscode-extensions; [
            jnoortheen.nix-ide
            davidanson.vscode-markdownlint
            naumovs.color-highlight
            esbenp.prettier-vscode
            vscjava.vscode-java-pack
            redhat.java
            vscjava.vscode-java-debug
            vscjava.vscode-java-test
            vscjava.vscode-maven
            vscjava.vscode-java-dependency
            vscjava.vscode-gradle
            oderwat.indent-rainbow
          ];
          userSettings = {
            "editor.formatOnSave" = true;
            "editor.formatOnSaveMode" = "modificationsIfAvailable";
            "java.cleanup.actions" = [
              "qualifyStaticMembers"
              "addOverride"
              "addDeprecated"
              "stringConcatToTextBlock"
              "invertEquals"
              "addFinalModifier"
              "lambdaExpressionFromAnonymousClass"
              "lambdaExpression"
              "switchExpression"
              "tryWithResource"
              "renameFileToType"
              "organizeImports"
              "renameUnusedLocalVariables"
              "useSwitchForInstanceofPattern"
            ];
            "java.format.settings.url" = "/home/purps/.config/Code/User/eclipse-formatter.xml";
            "redhat.telemetry.enabled" = false;
            "window.restoreWindows" = "none";
            "git.confirmSync" = false;
            "[java]" = {
              "editor.defaultFormatter" = "redhat.java";
              "editor.formatOnSave" = true;
            };
            "editor.codeActionsOnSave" = {
              "source.generate.finalModifiers" = "explicit";
              "source.organizeImports" = "explicit";
            };
          };
        };
      };
    };
  };
}
