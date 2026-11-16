{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.opencode;
  inherit (cfg) context7 superpowers;
  rea = config.custom.programs.rea;

  # OpenCode V2 config shape: servers live under mcp.servers and connect
  # unless `disabled = true`.
  mcpServers =
    lib.optionalAttrs context7.enable {
      context7 = {
        type = "local";
        # Pass the API key via env var (CONTEXT7_API_KEY) rather than
        # --api-key, so it never appears in the process argv / ps output.
        command = [
          "${pkgs.bash}/bin/bash"
          "-c"
          "CONTEXT7_API_KEY=$(cat ${context7.apiKeyPath} | tr -d '\n') ${opencodeTools}/bin/context7-mcp"
        ];
      };
    }
    // lib.optionalAttrs cfg.mcp-nixos.enable {
      nixos = {
        type = "local";
        command = ["${pkgs.mcp-nixos}/bin/mcp-nixos"];
      };
    }
    // lib.optionalAttrs rea.enable {
      rea = {
        type = "local";
        command = ["${rea.package}/bin/rea" "mcp"];
      };
    };

  # MAINTENANCE: pinned npm tool versions live in package.json, see MAINTENANCE.md
  opencodeTools = pkgs.buildNpmPackage {
    pname = "opencode-pinned-tools";
    version = "1.0.0";
    src = ./opencode;
    npmDepsHash = "sha256-5wXLhmVetVV7LJM/IXI3Y9o4Qmeukw2uJDy09whnYgw=";
    dontNpmBuild = true;
    nativeBuildInputs = [pkgs.makeWrapper];
    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/node_modules/opencode-pinned-tools $out/bin
      cp -r node_modules package.json package-lock.json $out/lib/node_modules/opencode-pinned-tools

      makeWrapper ${pkgs.nodejs}/bin/node $out/bin/context7-mcp \
        --add-flags $out/lib/node_modules/opencode-pinned-tools/node_modules/@upstash/context7-mcp/dist/index.js

      runHook postInstall
    '';
  };
in {
  options.custom.programs.opencode = {
    enable = lib.mkEnableOption "OpenCode AI coding assistant";
    context7 = {
      enable = lib.mkEnableOption "Context7 MCP Server";
      apiKeyPath = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to the Context7 API key secret";
      };
    };
    superpowers = {
      enable = lib.mkEnableOption "Superpowers skills and plugin for OpenCode";
    };
    mcp-nixos = {
      enable = lib.mkEnableOption "MCP-NixOS server for NixOS packages, options, and resources";
    };
    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Extra opencode.json settings (agents, default_agent, permissions, ...), merged over the generated config";
    };
    extraInstructions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra sections appended to the global AGENTS.md";
    };
    pinnedTools = lib.mkOption {
      type = lib.types.package;
      default = opencodeTools;
      readOnly = true;
      internal = true;
      description = "Pinned npm tools (context7-mcp), shared with the claude-code module";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !context7.enable || context7.apiKeyPath != "";
        message = "custom.programs.opencode.context7.enable requires apiKeyPath to be set";
      }
    ];

    home = {
      packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
        [
          opencode2
        ]
        ++ lib.optionals context7.enable [opencodeTools];

      file = {
        ".config/opencode/opencode.json" = lib.mkIf (mcpServers != {} || cfg.settings != {}) {
          text = builtins.toJSON (lib.recursiveUpdate
            ({"$schema" = "https://opencode.ai/config.json";}
              // lib.optionalAttrs (mcpServers != {}) {mcp.servers = mcpServers;})
            cfg.settings);
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
            - Never push directly to `main`/`master`/`dev`; all changes on a `feature/<desc>` or `fix/<desc>` branch. This can be overridden.
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
          ''
          + lib.optionalString (cfg.extraInstructions != "") ''

            ${cfg.extraInstructions}'';
      };
    };
  };
}
