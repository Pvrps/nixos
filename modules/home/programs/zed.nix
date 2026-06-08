{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.custom.programs.zed;

  sysBin = pkg: bin: {
    binary = {
      path = "${pkg}/bin/${bin}";
      ignore_system_version = true;
    };
  };

  defaultSettings = {
    auto_update = false;
    telemetry = {
      diagnostics = false;
      metrics = false;
    };
    helix_mode = true;
    format_on_save = "on";

    # Point every LSP at the system-installed binary so Zed never
    # tries to download its own copy.
    lsp = {
      # Keep the Nix extension's "nil" entry alive so it doesn't error.
      nil =
        (sysBin pkgs.nil "nil")
        // {
          initialization_options = {
            nix = {
              flake = {
                autoArchive = true;
              };
            };
          };
        };
      nixd =
        (sysBin pkgs.nixd "nixd")
        // {
          initialization_options = {
            nixd = {
              nixpkgs = {
                expr = "import <nixpkgs> { }";
              };
              formatting = {
                command = ["${pkgs.alejandra}/bin/alejandra"];
              };
              flake = {
                autoArchive = true;
              };
            };
          };
        };
      basedpyright =
        (sysBin pkgs.basedpyright "basedpyright-langserver")
        // {
          binary =
            ((sysBin pkgs.basedpyright "basedpyright-langserver").binary)
            // {
              arguments = ["--stdio"];
            };
          settings = {
            python = {
              pythonPath = ".venv/bin/python";
            };
            "basedpyright.analysis" = {
              typeCheckingMode = "standard";
              diagnosticSeverityOverrides = {
                reportMissingImports = "warning";
                reportMissingModuleSource = "warning";
                reportMissingTypeStubs = "warning";
                reportOptionalMemberAccess = "warning";
                reportOptionalSubscript = "warning";
                reportAttributeAccessIssue = "warning";
                reportGeneralTypeIssues = "warning";
                reportArgumentType = "warning";
                reportUninitializedInstanceVariable = "warning";
                reportCallIssue = "warning";
              };
            };
          };
        };
      "typescript-language-server" = sysBin pkgs.typescript-language-server "typescript-language-server";
      "svelte-language-server" =
        (sysBin pkgs.svelte-language-server "svelteserver")
        // {
          binary =
            ((sysBin pkgs.svelte-language-server "svelteserver").binary)
            // {
              arguments = ["--stdio"];
            };
        };
      "bash-language-server" = sysBin pkgs.bash-language-server "bash-language-server";
      marksman = sysBin pkgs.marksman "marksman";
      taplo = sysBin pkgs.taplo "taplo";
      "yaml-language-server" =
        (sysBin pkgs.yaml-language-server "yaml-language-server")
        // {
          binary =
            ((sysBin pkgs.yaml-language-server "yaml-language-server").binary)
            // {
              arguments = ["--stdio"];
            };
        };
      lemminx = sysBin pkgs.lemminx "lemminx";
      "dockerfile-language-server" =
        (sysBin pkgs.docker-language-server "docker-language-server")
        // {
          binary =
            ((sysBin pkgs.docker-language-server "docker-language-server").binary)
            // {
              arguments = ["start" "--stdio"];
            };
        };
      sqls = sysBin pkgs.sqls "sqls";
      "jq-lsp" = sysBin pkgs.jq-lsp "jq-lsp";
      nginx = sysBin pkgs.nginx-language-server "nginx-language-server";
      graphql =
        (sysBin pkgs.graphql-language-service-cli "graphql-lsp")
        // {
          binary =
            ((sysBin pkgs.graphql-language-service-cli "graphql-lsp").binary)
            // {
              arguments = ["server" "--method" "stream"];
            };
        };
      "jsonnet-language-server" = sysBin pkgs.jsonnet-language-server "jsonnet-language-server";
      vtsls =
        (sysBin pkgs.vtsls "vtsls")
        // {
          binary =
            ((sysBin pkgs.vtsls "vtsls").binary)
            // {
              arguments = ["--stdio"];
            };
        };
      "tailwindcss-language-server" = sysBin pkgs.tailwindcss-language-server "tailwindcss-language-server";
      "tailwindcss-intellisense-css" = sysBin pkgs.tailwindcss-language-server "tailwindcss-language-server";
      "just-lsp" = sysBin pkgs.just-lsp "just-lsp";
      "package-version-server" = sysBin pkgs.package-version-server "package-version-server";
      "vscode-css-language-server" =
        (sysBin pkgs.vscode-langservers-extracted "vscode-css-language-server")
        // {
          binary =
            ((sysBin pkgs.vscode-langservers-extracted "vscode-css-language-server").binary)
            // {
              arguments = ["--stdio"];
            };
        };
      "vscode-html-language-server" =
        (sysBin pkgs.vscode-langservers-extracted "vscode-html-language-server")
        // {
          binary =
            ((sysBin pkgs.vscode-langservers-extracted "vscode-html-language-server").binary)
            // {
              arguments = ["--stdio"];
            };
        };
      "vscode-json-language-server" =
        (sysBin pkgs.vscode-langservers-extracted "vscode-json-language-server")
        // {
          binary =
            ((sysBin pkgs.vscode-langservers-extracted "vscode-json-language-server").binary)
            // {
              arguments = ["--stdio"];
            };
        };
      "vscode-markdown-language-server" =
        (sysBin pkgs.vscode-langservers-extracted "vscode-markdown-language-server")
        // {
          binary =
            ((sysBin pkgs.vscode-langservers-extracted "vscode-markdown-language-server").binary)
            // {
              arguments = ["--stdio"];
            };
        };
      eslint =
        (sysBin pkgs.vscode-langservers-extracted "vscode-eslint-language-server")
        // {
          binary =
            ((sysBin pkgs.vscode-langservers-extracted "vscode-eslint-language-server").binary)
            // {
              arguments = ["--stdio"];
            };
          settings = {
            rulesCustomizations = [
              {
                rule = "*";
                severity = "warn";
              }
            ];
          };
        };
    };

    # Justfiles have no standard extension — teach Zed to recognise them
    file_types = {
      "Just" = ["justfile" "Justfile" ".justfile"];
    };

    # Use Tailwind's built-in CSS mode for CSS files so @theme,
    # @custom-variant etc. are recognised; disable the default
    # CSS language server which flags them as unknown.
    languages = {
      CSS = {
        language_servers = [
          "tailwindcss-intellisense-css"
          "!vscode-css-language-server"
          "..."
        ];
      };
    };
  };
in {
  options.custom.programs.zed = {
    enable = lib.mkEnableOption "Zed editor";

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of Zed extension repository names to install on startup.";
    };

    userSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Settings written to Zed's settings.json (merged with module defaults).";
    };

    userKeymaps = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Configuration written to Zed's keymap.json (list of keybinding objects).";
    };

    defaultEditor = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to set zed -w as the default editor via $EDITOR/$VISUAL.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor;
      inherit (cfg) extensions userKeymaps defaultEditor;
      mutableUserSettings = false;
      userSettings = lib.mkMerge [defaultSettings cfg.userSettings];
    };
  };
}
