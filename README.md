# NixOS Configuration

This repository is public, but it is primarily written for my own machines. It may still be useful as a reference for structuring a multi-host NixOS/Home Manager setup.

## Layout

```text
flake.nix                # Flake inputs + mkHost (auto-imports all shared modules)
justfile                 # Common maintenance commands
modules/lib/             # lib.custom.* helpers (mkScript, mkContainer, mkUserSecrets, ...)
modules/devenv/<lang>/   # Shared devenv.sh project templates, scaffolded via `dev-init-<lang>`
modules/nixos/           # Shared NixOS modules — all option-gated, auto-imported
modules/nixos/profiles/  # Host profiles (workstation) that bundle defaults
modules/hosts/<host>/    # Host-specific: hardware, disko, persistence, users, deltas
modules/hosts/_shared/   # Shared disko layout (parameterized)
modules/home/            # Shared Home Manager modules — all option-gated, auto-imported
modules/home/profiles/   # Home profiles (desktop) for cross-cutting user glue
modules/users/<user>/    # Per-user composition (pure choice lists)
```

How it fits together:

- `mkHost` (flake.nix) imports **all** of `modules/nixos` and `modules/home` via
  `import-tree`. Modules are option-gated (`custom.*`), so importing costs
  nothing until a host or user enables them. There are no per-host import lists
  to maintain.
- Hosts enable a profile (`custom.profiles.workstation.enable`) plus their
  genuine deltas. Profiles set everything with `mkDefault`, so any line can be
  overridden per-host.
- Shared _opinions_ (Discord plugin set, Steam millennium plugins, Zen mods,
  fish aliases) live as **overridable option defaults** inside the program
  modules. A user diverges by overriding the option in their own file — no
  shared file needs editing.
- Mutable per-user state (e.g. EasyEffects presets, written back by `micsave`)
  is intentionally duplicated per user, never shared.

## Adding Modules

New modules should be small, self-contained, and opt-in by default. The usual pattern is:

- Put Home Manager programs in `modules/home/programs/<category>/` (e.g. `gaming/`, `desktop/`, `development/`) and scripts in `modules/home/scripts/` (use `lib.custom.mkScript`).
- Put shared system-level modules in `modules/nixos/`. They are auto-imported; just define `options.custom.*` and gate config behind `lib.mkIf`.
- Put host-specific hardware, disks, persistence, and service wiring in `modules/hosts/<host>/`.
- Put user composition in `modules/users/<user>/`, usually by enabling existing `custom.*` options.

Module shape:

```nix
{
  lib,
  config,
  ...
}: let
  cfg = config.custom.programs.example;
in {
  options.custom.programs.example.enable = lib.mkEnableOption "Example program";

  config = lib.mkIf cfg.enable {
    # Program config here
  };
}
```

Conventions:

- Option leafs are camelCase (`custom.programs.discordRpc`); files keep the
  program's real name (`discord-rpc.nix`).
- Use `lib.mkIf cfg.enable` so importing a module does not automatically enable it.
- Add assertions when a module depends on another module, service, compositor, secret, or package.
- Keep shared modules host-agnostic; host names, device IDs, mount paths, and hardware quirks belong in host files.
- Do not read secrets at Nix evaluation time. Pass SOPS secret paths to runtime scripts or services instead.
- If an app needs persistent state, add it deliberately in the relevant host or user persistence module.
- After adding or moving modules, run `just format` and `just build <host>` for the affected host.

## Usage

This repo uses [`nh`](https://github.com/nix-community/nh) through the included `justfile`.

## Secrets

Secrets are managed with `sops-nix`. Encrypted host secret files live beside each host under `modules/hosts/<host>/_secrets.yaml`. The age keys themselves are not stored in this repository. Use `lib.custom.mkUserSecrets` for user-owned secret declarations.

## Maintenance & workarounds

- [MAINTENANCE.md](MAINTENANCE.md): pins that `nix flake update` will not bump (image digests, release zips, tags).
- [WORKAROUNDS.md](WORKAROUNDS.md): temporary forks, patches, overlays and pins that should be removed once upstream catches up.

Each site in the code is tagged `# MAINTENANCE:` / `# WORKAROUND:`, so `grep -rn` finds them.

## Notes

- The systems use impermanence; the shared base is `modules/nixos/persist.nix`, host deltas live in `modules/hosts/<host>/_persist.nix`.
- Some modules are convenience-first because this is a real daily-driver setup, not a minimal hardening benchmark.

## Warning

Do not apply this configuration blindly. It contains hardware-specific disk layouts, host names, users, secrets wiring, persistence paths, and personal workflow choices.
