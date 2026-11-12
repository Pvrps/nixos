{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.claude-code;
  inherit (cfg) context7 superpowers;

  # Same pinned context7-mcp build the opencode module uses
  inherit (config.custom.programs.opencode) pinnedTools;

  mcpServers =
    lib.optionalAttrs context7.enable {
      context7 = {
        type = "stdio";
        # Pass the API key via env var (CONTEXT7_API_KEY) rather than
        # --api-key, so it never appears in the process argv / ps output.
        command = "${pkgs.bash}/bin/bash";
        args = [
          "-c"
          "CONTEXT7_API_KEY=$(cat ${context7.apiKeyPath} | tr -d '\n') ${pinnedTools}/bin/context7-mcp"
        ];
      };
    }
    // lib.optionalAttrs cfg.mcp-nixos.enable {
      nixos = {
        type = "stdio";
        command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
        args = [];
      };
    };

  mcpConfig = pkgs.writeText "claude-code-mcp.json" (builtins.toJSON {inherit mcpServers;});

  # Claude Code keeps user-scoped MCP servers and installed plugins in mutable
  # state (~/.claude.json, ~/.claude/plugins), so declare them as CLI flags.
  # `--mcp-config=` needs the `=`: the flag is variadic and the space form
  # swallows the subcommand or prompt that follows it.
  wrapperFlags =
    lib.optional (mcpServers != {}) "--mcp-config=${mcpConfig}"
    ++ lib.optionals superpowers.enable ["--plugin-dir" "${inputs.superpowers}"];

  unwrapped = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

  claude-code =
    if wrapperFlags == []
    then unwrapped
    else
      pkgs.symlinkJoin {
        name = "claude-code-wrapped-${unwrapped.version}";
        paths = [unwrapped];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/claude --add-flags ${lib.escapeShellArg (lib.escapeShellArgs wrapperFlags)}
        '';
        inherit (unwrapped) meta;
      };
in {
  options.custom.programs.claude-code = {
    enable = lib.mkEnableOption "Claude Code AI coding assistant";
    context7 = {
      enable = lib.mkEnableOption "Context7 MCP Server";
      apiKeyPath = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to the Context7 API key secret";
      };
    };
    superpowers = {
      enable = lib.mkEnableOption "Superpowers plugin for Claude Code";
    };
    mcp-nixos = {
      enable = lib.mkEnableOption "MCP-NixOS server for NixOS packages, options, and resources";
    };
  };

  config = lib.mkIf cfg.enable {
    home.persistence."/persist" = {
      directories = [".claude"];
      files = [".claude.json"];
    };

    assertions = [
      {
        assertion = !context7.enable || context7.apiKeyPath != "";
        message = "custom.programs.claude-code.context7.enable requires apiKeyPath to be set";
      }
    ];

    home = {
      packages = [claude-code];

      # ~/.claude/settings.json is left unmanaged: Claude Code writes to it
      # (/model, /config, permission prompts).
      file.".claude/CLAUDE.md".text =
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
          - Do NOT write design docs or plans to disk; keep plans in-context only
          - Do NOT commit documentation or plans as part of the workflow
        '';
    };
  };
}
