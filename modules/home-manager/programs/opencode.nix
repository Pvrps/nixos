{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.custom.programs.opencode;
  context7 = config.custom.opencode.context7;
in {
  options.custom.programs.opencode.enable = lib.mkEnableOption "OpenCode AI coding assistant";

  config = lib.mkIf cfg.enable {
    home = {
      packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
        [
          opencode
        ]
        ++ lib.optionals context7.enable [pkgs.nodejs];

      file = {
        ".config/opencode/opencode.json" = lib.mkIf context7.enable {
          text = builtins.toJSON {
            "$schema" = "https://opencode.ai/config.json";
            mcp = {
              context7 = {
                type = "local";
                command = [
                  "${pkgs.bash}/bin/bash"
                  "-c"
                  "npx -y @upstash/context7-mcp --api-key $(cat ${context7.apiKeyPath} | tr -d '\n')"
                ];
                enabled = true;
              };
            };
          };
        };

        ".config/opencode/AGENTS.md".text = ''
          ## Hard constraints
          - apt/brew/yum are unavailable on NixOS — use `nix-shell -p <package>` for missing tools
          - Never push directly to `main`/`master`/`dev`; all changes on a `feature/<desc>` or `fix/<desc>` branch
          - One logical task per session; ignore unrelated issues

          ## Pre-task
          - Use the `context7` MCP server for up-to-date library docs before writing code
        '';
      };
    };
  };
}
