{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    opencode
  ];

  home.file.".config/opencode/AGENTS.md".text = ''
    # GLOBAL AGENT CONTEXT & INSTRUCTIONS

    You are operating in a strict NixOS environment. You MUST adhere to the following workflow.

    ## 1. SYSTEM ENVIRONMENT & PATHS
    - **OS:** NixOS with Nix Flakes. Ephemeral root (`tmpfs`). Root is wiped on every boot. All persistent data lives under `/persist`.
    - **Projects Directory:** ALL projects MUST be created inside `~/Development/`.
      - **FATAL ERROR:** Do not run `mkdir <name>` in `~`. Always use `mkdir -p ~/Development/<name> && cd ~/Development/<name>`.
    - **Scripting:** Write scripts ONLY in `bash`/`sh`. NEVER write scripts in `fish`.

    ## 2. THE MANDATORY WORKFLOW (STEP-BY-STEP)
    **FATAL ERROR:** You are strictly forbidden from writing code until you have completed steps 1 through 5 in exact order.

    1. **Task Management:** If `td` database is missing, run `td init`. Then run `td usage --new-session`, `td create "Title" --type feature --priority P1`, and `td start <id>`.
    2. **Directory & Git Init:** `mkdir -p ~/Development/<name>`, `cd` into it, and IMMEDIATELY run `git init`.
    3. **Project Scaffold (Main Branch):** If starting a new project, run your scaffolding command NOW. Once scaffolding is complete, run `git add .` and `git commit -m "chore: initial project scaffold"` on the `main` branch.
    4. **Feature Branching:** **FATAL ERROR:** NEVER do your actual manual coding on `main`. IMMEDIATELY run `git switch -c feature/<descriptive-name>`.
    5. **Development:** *...write your feature code...*
    6. **Verification:** You MUST run the project's specific type-check and build commands to verify it compiles. Do not proceed if there are errors.
    7. **Commit Changes:** Stage and commit your feature work: `git add .` and `git commit -m "feat: description"`.
    8. **Review & Stop:** Run `td review <id>`. Once you run this, your task is COMPLETE. Output a SINGLE, concise final message, and STOP generating text. DO NOT run further commands (`ls`, `pwd`, etc.).

    ## 3. VERSION CONTROL RULES
    - **Ignored Files:** NEVER attempt to track or commit agent state directories (`.todo/`, `.sidecar/`). If `git status` shows them, add them to `.gitignore`.
    - **Workflow enforcement:** All commits after the initial project scaffold MUST happen on a `feature/*` branch.

    ## 4. PROJECT-SPECIFIC CONTEXT (AGENTS.md)
    - **Initialization:** Whenever you initialize a brand new project, you MUST create a local `AGENTS.md` file in the project root. Document persistent architectural decisions, libraries used, and custom commands.
    - **Reading:** Whenever you start a task in an existing project, you MUST read the project-root `AGENTS.md` before writing any code.

    ## 5. DEPENDENCY MANAGEMENT (NIX ONLY)
    **FATAL ERROR:** NEVER use `npm -g`, `pip install`, `cargo install`, or `brew`.
    - Every project MUST have a `shell.nix`. NEVER create `flake.nix` for local projects.
    - Standard `shell.nix` template:
      ```nix
      { pkgs ? import <nixpkgs> {} }:
      pkgs.mkShell { buildInputs = with pkgs; [ bun ]; }
      ```

    ---

    ## 6. WEB PROJECTS (SVELTE 5 + TAILWIND V4 + BUN)
    **Constraint:** NEVER start the dev server yourself. Tell the user to run: `cd ~/Development/<name> && nix-shell --run "bun run dev"`

    ### Web Initialization
    Run from INSIDE the project directory (`.`):
    `nix-shell -p bun --run "bun x sv create . --template minimal --types ts --add tailwindcss='plugins:typography,forms' playwright prettier eslint sveltekit-adapter='adapter:auto' --install bun --no-dir-check"`

    ### Web Verification Protocol
    Before running `td review`, you MUST verify the web application compiles without errors:
    1. Run `nix-shell --run "bun run check"`
    2. Run `nix-shell --run "bun run build"`
    If either command fails, debug and fix the code before reviewing.

    ### MANDATORY WEB RESEARCH PROTOCOL
    **FATAL ERROR:** Your internal pre-training data is outdated. You are STRICTLY FORBIDDEN from writing any UI, state, or styling code until you use your `WebFetch` tool to read these EXACT URLs.
    **Constraint:** ONLY fetch these exact `https://` URLs:
    - **Svelte 5 Runes:** `https://svelte.dev/docs/svelte/what-are-runes`
    - **Svelte 5 State:** `https://svelte.dev/docs/svelte/$state`
    - **Svelte 5 Derived:** `https://svelte.dev/docs/svelte/$derived`
    - **Svelte 5 Effects:** `https://svelte.dev/docs/svelte/$effect`
    - **Svelte 5 Props:** `https://svelte.dev/docs/svelte/$props`
    - **Svelte 5 Bindable:** `https://svelte.dev/docs/svelte/$bindable`
    - **Svelte 5 Inspect:** `https://svelte.dev/docs/svelte/$inspect`
    - **Svelte 5 Host:** `https://svelte.dev/docs/svelte/$host`
    - **Tailwind v4 Vite:** `https://tailwindcss.com/docs/installation/using-vite`
    - **Tailwind v4 Dark Mode:** `https://tailwindcss.com/docs/dark-mode`

    ### Web Anti-Patterns (FATAL ERRORS)
    Even after researching, ensure you NEVER make these legacy mistakes:
    - **FATAL ERROR:** NEVER create `tailwind.config.js` or `.cjs`. Tailwind v4 does not use them. Configuration lives entirely in CSS using the `@theme` directive.
    - **FATAL ERROR:** NEVER use legacy Svelte `$` reactive blocks. NEVER fallback to `svelte/store` or `writable`. You MUST use Runes.
    - **FATAL ERROR:** NEVER attempt to import runes (e.g., `import { $state } from 'svelte'`). Svelte 5 automatically injects runes into `.svelte` and `.svelte.ts` files. Importing them causes compiler crashes.
    - **FATAL ERROR:** NEVER use `$state` or `$effect` in a plain `.ts` or `.js` file. This causes `rune_outside_svelte` errors. State files MUST be named with the `.svelte.ts` extension (e.g., `src/lib/theme.svelte.ts`).
    - **FATAL ERROR:** When importing from a `.svelte.ts` file, you MUST use the `.svelte` extension in the import path to satisfy Vite. (e.g., `import { themeState } from '$lib/theme.svelte';`).
    - **FATAL ERROR:** NEVER put an `$effect` at the root level of a module. It causes `effect_orphan` errors. `$effect` requires a component context (like `+layout.svelte`).
    - **FATAL ERROR:** NEVER access `window`, `document`, or `localStorage` during Server-Side Rendering (SSR). You MUST wrap browser APIs in `if (browser)` checks using `import { browser } from '$app/environment'`.
  '';
}
