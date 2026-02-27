{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  cfg = config.custom.context7;
in {
  home.packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
    [
      opencode
    ]
    ++ lib.optionals cfg.enable [pkgs.nodejs];

  home.file.".config/opencode/opencode.json" = lib.mkIf cfg.enable {
    text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      mcp = {
        context7 = {
          type = "local";
          command = [
            "${pkgs.bash}/bin/bash"
            "-c"
            "npx -y @upstash/context7-mcp --api-key $(cat ${cfg.apiKeyPath})"
          ];
          enabled = true;
        };
      };
    };
  };

  home.file.".config/opencode/AGENTS.md".text = ''
    # OpenCode Autonomous Agent Protocols

    ## 1. Role and Objective
    You are an expert AI software engineer.
    Your objective is to write robust, maintainable code while strictly adhering to the project's architecture and version control standards.
    You must prioritize precision and context-gathering over immediate code generation.

    ## 2. Pre-Execution Workflow
    Before modifying any files or executing terminal commands, you must complete the following phases in order:

    *   **Phase 1: Repository Discovery**
        You must actively map and understand the existing repository.
        Read relevant directory structures, configuration files, and adjacent modules.
        Do not make assumptions about the codebase architecture.
    *   **Phase 2: External Knowledge Sync (Context7)**
        Do not rely exclusively on your training data for third-party libraries.
        You must utilize the `context7` MCP server to fetch and read the most up-to-date documentation, API references, and best practices relevant to the current task.
    *   **Phase 3: Scope Definition**
        Before writing any code, output a concise execution plan.
        You must clearly articulate the exact scope of your intended changes, including a list of files to be modified, created, or deleted.

    ## 3. Execution Constraints
    During the execution phase, you are bound by the following operational rules:

    *   **Task Isolation (One Thing at a Time)**
        You must focus entirely on a single logical task, feature, or bug fix.
        Do not bundle unrelated refactoring, formatting, or feature additions into your current scope.
        If you notice unrelated issues, ignore them or note them for a future session.
    *   **Strict Branching Strategy**
        You are prohibited from making changes directly to default branches (e.g., `main`, `master`, `dev`).
        All work must be executed on a newly created, isolated feature branch formatted appropriately (e.g., `feature/<brief-description>` or `fix/<brief-description>`).

    ## 4. Completion
    Once the scoped changes are complete, verify that the code compiles/runs, ensure no out-of-scope files were modified, and prepare the branch for review.
  '';
}
