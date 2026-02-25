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

    You are operating in a strict NixOS environment with an ephemeral root (`tmpfs`). All persistent data lives under `/persist`.
    ALL projects MUST be created inside `~/Development/`.
    Write scripts ONLY in `bash`/`sh`. NEVER write scripts in `fish`.

    ## 1. PROJECT INITIALIZATION (NEW PROJECTS ONLY)
    **FATAL ERROR:** If you are asked to create a NEW project, you MUST execute these exact steps sequentially. Do not skip any steps.

    1. **Directory Context:** Use `pwd` to check your current path. If you are already inside the intended empty project directory (e.g., `~/Development/<name>`), DO NOT create a new directory. If you are not, run `mkdir -p ~/Development/<name>` and `cd` into it. NEVER nest project folders.
    2. **Initialize Git & Tasks:** Run `git init` and `td init`.
    3. **Nix Environment:** Create a `shell.nix` in the project root tailored to the required tech stack (e.g., bun, go, rust). NEVER create a `flake.nix` for local projects.
    4. **Project Scaffolding:** Execute the framework-specific scaffolding commands (see Tech Stack rules below).
    5. **Project Context:** Create a local `AGENTS.md` in the project root documenting the architecture, theme, and tech stack of this specific project.
    6. **Initial Commit:** You MUST ensure task tracking files are ignored. Run `echo ".todos/" >> .gitignore && echo ".sidecar/" >> .gitignore`. Only after doing this, stage everything and commit: `git add . && git commit -m "chore: initial project scaffold"` on the `main` branch.
    7. **Task Breakdown & Graphing:** Run `td usage --new-session`. You MUST create a logical task graph using `td create`.
       - **DEPENDENCY LOGIC:** You MUST use the `--depends-on <id>` flag ONLY when a task logically requires a previous one (e.g., "Implement Search UI" depends on "Setup API Client").
       - **CONCURRENCY:** Tasks that are independent (e.g., "Landing Page" vs "Settings Page") should NOT have dependencies on each other.
       - **GOAL:** Create a realistic project roadmap, not a forced linear chain.
    8. **THE PLANNING WALL:** After creating the task graph, you MUST STOP. You are STRICTLY FORBIDDEN from starting a task or creating a feature branch in the same turn. Output the task list (showing which tasks are unblocked and which are waiting) and wait for the user to select a task.

    ## 2. THE DEVELOPMENT WORKFLOW (EVERY TASK)
    **FATAL ERROR:** You are strictly forbidden from writing code until you have followed this workflow. NEVER work directly on `main`.

    1. **Task Selection:** Run `td next` to identify unblocked tasks.
       - **BUG REPORTS / CHANGES:** If the user reports a bug or requests a change, you MUST treat this as a NEW task. Run `td create` for the bug fix, stop, and wait for user acknowledgment.
    2. **Start Task:** Run `td start <id>`.
    3. **Branching (MANDATORY):** You MUST run `git switch -c feature/<task-id>-<short-description>` BEFORE running any file-writing tools (`write`, `edit`, `sed`, etc.).
       - **VERIFICATION:** Before editing your first file in a task, run `git branch --show-current`. If you are on `main`, you MUST switch branches immediately.
    4. **Development:** *...write your feature code...*
       - **TASK ISOLATION:** Only write code relevant to the CURRENT task. Do NOT implement future features or unrelated tasks. If you finish a task early, STOP. Do not move to the next one.
    5. **Verification:** You MUST run the project's specific type-check, lint, and build commands (see Tech Stack rules below). Debug and fix any errors before proceeding.
    6. **Commit:** `git add .` and `git commit -m "feat: <description>"`.
    7. **Review & Stop:** Run `td review <id>`.

    **TERMINAL STATE (THE EXECUTION WALL):** Once you run `td review`, your work for this turn is finished. You are STRICTLY FORBIDDEN from running `td start` for the next task. Output a single final message explaining how to run/test the current work, and STOP.

    ## 3. STRICT AVOIDANCE RULES
    - **Self-Approval Loophole:** NEVER run `td approve` on your own work. NEVER run `td usage --new-session` mid-task to bypass review blocks.
    - **Package Managers:** NEVER use `npm -g`, `pip install`, `cargo install`, or `brew`.
    - **Ignored Files:** NEVER track or commit `.todos/` or `.sidecar/`. Add them to `.gitignore` if `git status` shows them.

    ---

    ## 4. TECH STACK: WEB PROJECTS (SVELTE 5 + TAILWIND V4 + BUN)
    If the project is a web application, you MUST apply these specific rules during Initialization and Verification.

    ### Web Nix Environment (Step 1.3)
    Use this exact `shell.nix`:
    ```nix
    { pkgs ? import <nixpkgs> {} }:
    pkgs.mkShell { buildInputs = with pkgs; [ bun ]; }
    ```

    ### Web Scaffolding (Step 1.4)
    Run exactly: `nix-shell -p bun --run "bun x sv create . --template minimal --types ts --add tailwindcss='plugins:typography,forms' playwright prettier eslint sveltekit-adapter='adapter:auto' --install bun --no-dir-check"`

    ### Web Verification (Step 2.5)
    Before running `td review`, you MUST verify the web application compiles without errors:
    1. `nix-shell --run "bun run check"`
    2. `nix-shell --run "bun run build"`

    ### MANDATORY WEB RESEARCH PROTOCOL
    **FATAL ERROR:** Your internal pre-training data is outdated. You are STRICTLY FORBIDDEN from writing any UI, state, or styling code until you use your `WebFetch` tool to read these EXACT URLs:
    - Svelte 5 Runes: `https://svelte.dev/docs/svelte/what-are-runes`
    - Svelte 5 State: `https://svelte.dev/docs/svelte/$state`
    - Svelte 5 Derived: `https://svelte.dev/docs/svelte/$derived`
    - Svelte 5 Effects: `https://svelte.dev/docs/svelte/$effect`
    - Svelte 5 Props: `https://svelte.dev/docs/svelte/$props`
    - Svelte 5 Bindable: `https://svelte.dev/docs/svelte/$bindable`
    - Svelte 5 Inspect: `https://svelte.dev/docs/svelte/$inspect`
    - Svelte 5 Host: `https://svelte.dev/docs/svelte/$host`
    - Tailwind v4 Vite: `https://tailwindcss.com/docs/installation/using-vite`
    - Tailwind v4 Dark Mode: `https://tailwindcss.com/docs/dark-mode`

    ### Web Anti-Patterns (FATAL ERRORS)
    Even after researching, ensure you NEVER make these legacy mistakes:
    - **FATAL ERROR:** NEVER create `tailwind.config.js` or `.cjs`. Tailwind v4 does not use them. Configuration lives entirely in CSS using the `@theme` directive.
    - **FATAL ERROR:** NEVER use legacy Svelte `$` reactive blocks. NEVER fallback to `svelte/store` or `writable`. You MUST use Runes.
    - **FATAL ERROR:** NEVER attempt to import runes (e.g., `import { $state } from 'svelte'`). Svelte 5 automatically injects runes into `.svelte` and `.svelte.ts` files. Importing them causes compiler crashes.
    - **FATAL ERROR:** NEVER use `$state` or `$effect` in a plain `.ts` or `.js` file. This causes `rune_outside_svelte` errors. State files MUST be named with the `.svelte.ts` extension (e.g., `src/lib/theme.svelte.ts`).
    - **FATAL ERROR:** When importing from a `.svelte.ts` file, you MUST use the `.svelte` extension in the import path to satisfy Vite. (e.g., `import { themeState } from '$lib/theme.svelte';`).
    - **FATAL ERROR:** NEVER put an `$effect` at the root level of a module. It causes `effect_orphan` errors. `$effect` requires a component context (like `+layout.svelte`).
    - **FATAL ERROR:** NEVER access `window`, `document`, or `localStorage` during Server-Side Rendering (SSR). You MUST wrap browser APIs in `if (browser)` checks using `import { browser } from '$app/environment'`.
    - **FATAL ERROR:** Avoid exporting instantiated state classes directly (e.g. `export const myStore = new Store()`) in Svelte 5 + Vite, as this can trigger infinite Hot Module Replacement (HMR) loops. Instead, initialize state inside components or use Svelte's Context API (`setContext`/`getContext`) to provide state.
    - **FATAL ERROR:** NEVER leave the default SvelteKit boilerplate in `src/routes/+page.svelte` intact. When building the main UI/Dashboard, you MUST overwrite this file so the user sees the actual application.
  '';
}
