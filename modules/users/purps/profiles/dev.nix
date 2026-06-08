{
  pkgs,
  osConfig,
  ...
}: {
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
          enable = true;
          apiKeyPath = osConfig.sops.secrets."context7-api-key".path;
        };
        bravesearch = {
          enable = true;
          apiKeyPath = osConfig.sops.secrets."bravesearch-api-key".path;
        };
        #superpowers.enable = true;
        claudeAuth.enable = true;
        mcp-nixos.enable = true;
      };
      java.enable = true;
      vscode = {
        enable = false;
        javaFormatterConfig = ../files/eclipse-formatter.xml;
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
}
