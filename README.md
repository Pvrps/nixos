# NixOS Configuration

This repository is public, but it is primarily written for my own machines. It may still be useful as a reference for structuring a multi-host NixOS/Home Manager setup.

## Layout

```text
flake.nix                  # Flake inputs and host definitions
justfile                   # Common maintenance commands
modules/hosts/             # Host-specific system configuration
modules/nixos/             # Shared NixOS modules
modules/home/              # Shared Home Manager program/script modules
modules/users/             # User profiles and per-user composition
```

Most programs and scripts are defined as small Home Manager modules under `modules/home`. User files then compose those modules into higher-level profiles. Host files handle machine-specific hardware, persistence, networking, services, and boot setup.

## Adding Modules

New modules should be small, self-contained, and opt-in by default. The usual pattern is:

- Put Home Manager programs in `modules/home/programs/` and scripts in `modules/home/scripts/`.
- Put shared system-level modules in `modules/nixos/`.
- Put host-specific hardware, disks, persistence, and service wiring in `modules/hosts/<host>/`.
- Put user composition in `modules/users/<user>/`, usually by enabling existing `custom.*` options from a profile file.

Home Manager modules under `modules/home` are imported globally, so they should define options and only apply config when enabled. Prefer this shape:

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

Things to watch for:

- Use `lib.mkIf cfg.enable` so importing a module does not automatically enable it.
- Add assertions when a module depends on another module, service, compositor, secret, or package.
- Keep shared modules host-agnostic; host names, device IDs, mount paths, and hardware quirks belong in host files.
- Do not read secrets at Nix evaluation time. Pass SOPS secret paths to runtime scripts or services instead.
- If an app needs persistent state, add it deliberately in the relevant host or user persistence module.
- Prefer adding integration points through options rather than hardcoding cross-module assumptions.
- After adding or moving modules, run `just format` and `just build <host>` for the affected host.

## Usage

This repo uses [`nh`](https://github.com/nix-community/nh) through the included `justfile`.

Build the current host without switching:

```sh
just build
```

Build and switch the current host:

```sh
just switch
```

Build a specific host:

```sh
just build ${HOST}
```

Update flake inputs:

```sh
just update
```

Format the repository:

```sh
just format
```

Edit host secrets with SOPS:

```sh
just secrets ${HOST}
```

## Secrets

Secrets are managed with `sops-nix`. Encrypted host secret files live beside each host under `modules/hosts/<host>/_secrets.yaml`. The age keys themselves are not stored in this repository.

## Notes

- The systems use impermanence, so persistent state is intentionally listed in host and user persistence modules.
- Some modules are convenience-first because this is a real daily-driver setup, not a minimal hardening benchmark.
- `TODO.md` tracks known follow-ups, deferred hardening work, and intentional tradeoffs.

## Warning

Do not apply this configuration blindly. It contains hardware-specific disk layouts, host names, users, secrets wiring, persistence paths, and personal workflow choices.
