# Agent Instructions for NixOS Configuration

This repository contains the NixOS system configuration for the `desktop` system, managed via Nix Flakes. It features a modern, ephemeral setup using **impermanence**, **disko**, and **sops-nix**.

## 1. System Architecture & Critical Concepts

*   **Flake-based:** The entry point is `flake.nix`. All dependencies and outputs are defined there.
*   **Impermanence (Ephemeral Root):** The root filesystem (`/`) is a `tmpfs` and is wiped on every boot.
    *   **Persistent Data:** All permanent configuration and data reside in `/persist`.
    *   **Implication:** Do NOT manually edit files in `/etc` or `/home` expecting them to survive a reboot. You must configure them via Nix modules (e.g., `environment.etc` or Home Manager).
*   **Storage (Disko):** Disk partitioning is managed declaratively by `disko.nix` (Btrfs with subvolumes).
*   **Secrets (Sops-Nix):** Secrets are encrypted using `sops` and `age`. Never commit cleartext secrets.
*   **Theming (Stylix):** Global theming (fonts, colors, cursor) is handled by `stylix`. Avoid hardcoding hex colors; refer to Stylix variables where possible.

## 2. Validation, Linting & Formatting

You must rely on standard Nix tools for code quality. Do not apply arbitrary style rules; if the linter and formatter pass, the code is acceptable.

**Step 1: Code Quality (Mandatory)**
Before submitting any changes, run these commands to ensure correctness and style adherence.

*   **Lint (Statix):** Detects anti-patterns and potential errors.
    ```bash
    nix run nixpkgs#statix -- check .
    ```
*   **Format (Alejandra):** strictly enforces the project's formatting style.
    ```bash
    nix run nixpkgs#alejandra -- .
    ```

**Step 2: Verification**
*   **Check Flake Validity:**
    ```bash
    nix flake check
    ```
*   **Dry Build System:**
    Verifies that the configuration evaluates and builds without applying it. This is the primary safety check.
    ```bash
    nixos-rebuild dry-build --flake .#desktop
    ```

**Step 3: Application (Only when explicitly requested)**
*   **Switch System:**
    Applies the configuration to the running system.
    ```bash
    sudo nixos-rebuild switch --flake .#desktop
    ```
*   **Boot System:**
    Builds the configuration and sets it as the default for the next boot.
    ```bash
    sudo nixos-rebuild boot --flake .#desktop
    ```

## 3. Configuration Strategy (Home Manager vs. Manual)

When configuring applications, you must follow this priority order:

1.  **Home Manager Modules (Preferred):**
    *   Always check if Home Manager has a built-in module for the program first.
    *   Use structured options (e.g., `programs.git.userName`, `programs.fish.functions`).
    *   Use `programs.<name>.settings` (or `extraConfig`) to generate config files via the module whenever possible.
    *   *Why?* This ensures correct syntax, integration with other modules, and cleaner code.

2.  **Manual Configuration (Fallback):**
    *   Only if NO Home Manager module exists, or if the module is broken/severely limited.
    *   Use `xdg.configFile."<app>/config".text` or `home.file`.
    *   Avoid creating imperative write scripts.

## 4. Directory Structure & Modularity

This repository strictly separates reusable logic (modules) from specific instantiations (systems and users).

*   `flake.nix`: The flake entry point.
*   `modules/`: Reusable, generic NixOS and Home Manager building blocks.
    *   `nixos/`: System-level modules (`core.nix`, `users.nix`, `gaming.nix`, `custom.nix`, etc.).
    *   `home-manager/`: User-level modules, including granular program setups (`programs/`) and custom options (`custom.nix`).
        *   **CRITICAL:** These modules should *never* contain hardcoded user preferences, secrets, or themes. They must remain generic and expose settings via `config.custom.*`.
*   `systems/`: Instantiated machines.
    *   `desktop/`: Configuration specific to the `desktop` host.
        *   `default.nix`: Main system entry point (imports from `modules/nixos`).
        *   `hardware.nix`, `disko.nix`, `persist.nix`: Host-specific definitions.
*   `home/`: Instantiated Home Manager configurations.
    *   `users/<username>/`: User-specific profiles (e.g., `purps`).
        *   `default.nix`: User entry point. Imports specific modules from `modules/home-manager` and defines their `custom.*` options, secrets, and desktop environments.
        *   `stylix.nix`: User-specific theming.
*   `secrets.yaml`: Encrypted secrets file.

## 5. Configuration Decoupling Rules

*   **Avoid Hardcoding:** If a program module (e.g. `zen.nix`, `steam.nix`) requires a user-specific setting (like a username, extension list, or custom startup command), do *not* hardcode it in the module.
*   **Use `custom.nix`:** Expose those settings by defining `lib.mkOption` within `modules/nixos/custom.nix` or `modules/home-manager/custom.nix`.
*   **Configure in `home/users/<user>`:** Set the actual values for those options inside the user's `default.nix` using the `custom.<option>` attributes.
*   **Theming is User-Level:** Global theming like cursors and fonts are configured per-user via Stylix inside their own `home/users/<user>/stylix.nix`.
*   **Secrets:** Sops secrets should generally be provisioned system-wide inside `modules/nixos/users.nix` (e.g. `config.sops.secrets."github-ssh-key".path`) and passed to user modules via `custom` options (e.g., `custom.ssh.githubKeyPath`).

## 6. Code Style & Patterns

*   **Trust the Tools:** Follow `alejandra` and `statix`.
*   **Functional Patterns:** Use `let ... in` bindings for local variables.
*   **Imports:** Use relative paths. Group imports at the top of the file.
*   **Secrets:** Access secrets via `config.sops.secrets."name".path`.
    *   Example: `passwordFile = config.sops.secrets."user-password".path;`
*   **Theming:** Do not hardcode font names or color hex codes if Stylix covers it. Let Stylix handle the global look and feel.

## 7. Agent Operational Rules

1.  **Safety First:** NEVER run `nixos-rebuild switch` without first running `nixos-rebuild dry-build` or `nix flake check` and receiving user confirmation.
2.  **Impermanence Awareness:** Remember that writing to files outside of `/persist` via shell commands is temporary. Always implement changes via Nix configuration files.
3.  **Secret Safety:** Never read `secrets.yaml` directly or output its contents. Use `sops` tools if interaction is required (and requested by the user).
4.  **Context:** Before editing `flake.nix`, read it to understand existing inputs and overlays.
5.  **Troubleshooting:**
    *   **"Read-only file system":** You are likely trying to modify `/nix/store` directly. Modify source files in `/persist/etc/nixos`.
    *   **"File exists":** When switching, if a file conflicts with a managed file, ask the user before forcing or deleting.
6.  **Research:** If you are unsure about a specific configuration syntax, option, or error message, use the internet to research it before guessing.

## 8. Tips

1.  **Command not found:** Feel free to use `nix-shell -p <package>` if you need to temporarily use a tool that the system does not have.
