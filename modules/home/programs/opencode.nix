{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.opencode;
  inherit (cfg) context7 bravesearch superpowers claudeAuth;

  # Write the config file if any feature that needs it is enabled
  needsConfigFile = context7.enable || bravesearch.enable || claudeAuth.enable || cfg.mcp-nixos.enable;
in {
  options.custom = {
    programs.opencode = {
      enable = lib.mkEnableOption "OpenCode AI coding assistant";
      context7 = {
        enable = lib.mkEnableOption "Context7 MCP Server";
        apiKeyPath = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Path to the Context7 API key secret";
        };
      };
      bravesearch = {
        enable = lib.mkEnableOption "Brave Search MCP Server";
        apiKeyPath = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Path to the Brave Search API key secret";
        };
      };
      superpowers = {
        enable = lib.mkEnableOption "Superpowers skills and plugin for OpenCode";
      };
      claudeAuth = {
        enable = lib.mkEnableOption "opencode-claude-auth plugin (use Claude Code credentials in OpenCode)";
      };
      mcp-nixos = {
        enable = lib.mkEnableOption "MCP-NixOS server for NixOS packages, options, and resources";
      };
    };
  };

  config = lib.mkIf cfg.enable (let
    opencodeTools = pkgs.buildNpmPackage {
      pname = "opencode-pinned-tools";
      version = "1.0.0";
      src = ./opencode;
      npmDepsHash = "sha256-nwYBHhjEgB4sa3qFqJcgp7bKB3Q4gQjVmX1ogUfV76I=";
      dontNpmBuild = true;
      nativeBuildInputs = [pkgs.makeWrapper];
      installPhase = ''
        runHook preInstall

        mkdir -p $out/lib/node_modules/opencode-pinned-tools $out/bin
        cp -r node_modules package.json package-lock.json $out/lib/node_modules/opencode-pinned-tools

        makeWrapper ${pkgs.nodejs}/bin/node $out/bin/context7-mcp \
          --add-flags $out/lib/node_modules/opencode-pinned-tools/node_modules/@upstash/context7-mcp/dist/index.js
        makeWrapper ${pkgs.nodejs}/bin/node $out/bin/mcp-server-brave-search \
          --add-flags $out/lib/node_modules/opencode-pinned-tools/node_modules/@modelcontextprotocol/server-brave-search/dist/index.js

        runHook postInstall
      '';
    };
  in {
    assertions = [
      {
        assertion = !context7.enable || context7.apiKeyPath != "";
        message = "custom.programs.opencode.context7.enable requires apiKeyPath to be set";
      }
      {
        assertion = !bravesearch.enable || bravesearch.apiKeyPath != "";
        message = "custom.programs.opencode.bravesearch.enable requires apiKeyPath to be set";
      }
    ];

    home = {
      packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
        [
          opencode
        ]
        ++ lib.optionals (context7.enable || bravesearch.enable) [opencodeTools];

      file = {
        ".config/opencode/opencode.json" = lib.mkIf needsConfigFile {
          text = builtins.toJSON (
            {
              "$schema" = "https://opencode.ai/config.json";
            }
            // lib.optionalAttrs claudeAuth.enable {
              plugin = ["opencode-claude-auth@1.5.4"];
            }
            // lib.optionalAttrs (context7.enable || bravesearch.enable) {
              mcp =
                (lib.optionalAttrs context7.enable {
                  context7 = {
                    type = "local";
                    command = [
                      "${pkgs.bash}/bin/bash"
                      "-c"
                      "${opencodeTools}/bin/context7-mcp --api-key $(cat ${context7.apiKeyPath} | tr -d '\n')"
                    ];
                    enabled = true;
                  };
                })
                // (lib.optionalAttrs bravesearch.enable {
                  bravesearch = {
                    type = "local";
                    command = [
                      "${pkgs.bash}/bin/bash"
                      "-c"
                      "BRAVE_API_KEY=$(cat ${bravesearch.apiKeyPath} | tr -d '\n') ${opencodeTools}/bin/mcp-server-brave-search"
                    ];
                    enabled = true;
                  };
                })
                // (lib.optionalAttrs cfg.mcp-nixos.enable {
                  nixos = {
                    type = "local";
                    command = [
                      "${pkgs.mcp-nixos}/bin/mcp-nixos"
                    ];
                    enabled = true;
                  };
                });
            }
          );
        };

        ".config/opencode/plugins/superpowers.js" = lib.mkIf superpowers.enable {
          source = "${inputs.superpowers}/.opencode/plugins/superpowers.js";
        };

        ".config/opencode/skills/superpowers" = lib.mkIf superpowers.enable {
          source = "${inputs.superpowers}/skills";
        };

        ".config/opencode/AGENTS.md".text =
          ''
            ## Hard constraints
            - apt/brew/yum are unavailable on NixOS — use `nix-shell -p <package>` for missing tools
            - Never push directly to `main`/`master`/`dev`; all changes on a `feature/<desc>` or `fix/<desc>` branch
            - One logical task per session; ignore unrelated issues
          ''
          + lib.optionalString context7.enable ''

            ## Pre-task
            - Use the `context7` MCP server for up-to-date library docs before writing code
          ''
          + lib.optionalString superpowers.enable ''

            ## Superpowers
            - Superpowers skills are available via OpenCode's native `skill` tool
            - Use `skill` tool to list available skills (e.g. brainstorming, test-driven-development, etc)
            - Do NOT write design docs or plans to disk; keep plans in-context only
            - Do NOT commit documentation or plans as part of the workflow
          '';
      };
    };
  });
}
