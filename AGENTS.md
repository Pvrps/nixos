# Agent Instructions for NixOS Configuration

## Hard constraints

- **New file?** Run `git add <file>` BEFORE any `nix` command — Nix ignores untracked files and outputs a silent `error: path '…' does not exist`
- **NEVER** run `nixos-rebuild switch` or `nixos-rebuild boot` — deploys to the live system
- **NEVER** commit cleartext secrets or read/print `secrets.yaml` contents
- Shell writes outside `/persist` are wiped on next boot — all changes must be made declaratively in this repo
- `modules/` must stay generic: no hardcoded usernames, paths, or hardware IDs; expose them via `custom.*` options and set values only in `home/users/<user>/default.nix`

## Commands

```bash
# Validate (run in this order before finishing)
nix run nixpkgs#statix -- check .
nix run nixpkgs#alejandra -- .
nix flake check
nixos-rebuild dry-build --flake .#desktop

# Session bookends
td usage --new-session          # start
td review <id>                  # end — NEVER td done / td close / td handoff

# Missing tool
nix-shell -p <package>
```

## Configuring programs

Use `programs.<name>.settings` / `programs.<name>.extraConfig` (Home Manager module) when one exists. Fall back to `xdg.configFile."<app>/config".text` only if no HM module exists.

Secrets: declare in `modules/nixos/users.nix`, pass path via `custom.*`:
```nix
passwordFile = config.sops.secrets."user-password".path;
```

Theming: configure only in `home/users/<user>/stylix.nix` — never hardcode hex colors or font names in modules.

## New Home Manager module

```nix
{lib, config, ...}: let
  cfg = config.custom.programs.<name>;
in {
  options.custom.programs.<name>.enable = lib.mkEnableOption "<description>";

  config = lib.mkIf cfg.enable {
    # program config here
  };
}
```

- Import it in `home/users/<user>/default.nix` and set `.enable = true;` there
- Declare any new `custom.*` options directly in the module they configure
- Hardware IDs and user-specific values → `custom.*` option + value in `home/users/<user>/default.nix`
- Compositor keybinds → append to `custom.programs.niri.keybinds`; window/layer rules → `custom.programs.niri.windowRules` / `custom.programs.niri.layerRules`
- Default terminal → `custom.programs.niri.defaultTerminal = lib.mkDefault "<cmd>";` (not in `keybinds`)

Mutual exclusion between conflicting modules (e.g. `dankmaterialshell`/`noctalia`):
```nix
assertions = [{
  assertion = !config.custom.programs.<other>.enable;
  message = "<name> and <other> cannot both be enabled (conflict: <reason>).";
}];
```

Single-selection class (e.g. terminal emulator): both modules set `custom.programs.niri.defaultTerminal = lib.mkDefault "<cmd>";` — Nix raises a merge conflict at eval time, no assertion needed.

Dependency on another module:
```nix
assertions = [{
  assertion = config.custom.programs.<dep>.enable;
  message = "<name> requires custom.programs.<dep>.enable = true.";
}];
```

Checklist:
- [ ] `mkEnableOption` + `mkIf cfg.enable` skeleton
- [ ] No hardcoded user values or hardware identifiers
- [ ] Compositor keybinds/rules via `custom.programs.niri.*`
- [ ] Mutual exclusion asserted if conflicting
- [ ] Dependencies asserted
- [ ] Imported and enabled in `home/users/<user>/default.nix`
- [ ] New `custom.*` options declared directly in the module they configure

## Error reference

| Error | Cause | Fix |
|-------|-------|-----|
| `error: path '…' does not exist` | New file not git-tracked | `git add <file>` then re-run |
| `Read-only file system` | Attempted write to `/nix/store` | Edit source files in the project dir |
| `File exists` conflict during build | Nix already manages that path | Ask user before overriding |
| `hash mismatch` on `buildGoModule` | Upstream changed | Follow hash re-derivation steps above |

## Option lookup

Don't guess — options change between releases. Use https://mynixos.com or https://search.nixos.org/options.
