# TODO

## Security Later

- [ ] Revisit Secure Boot / Lanzaboote issues and document previous failure.
- [ ] Replace Mickey password SSH with pubkey auth.
- [ ] Revisit Bluetooth hardening without breaking 8BitDo Pro 2 pairing.
- [ ] Revisit input/uinput permissions after testing Steam Input and controller mapping.
- [ ] Consider git commit signing.

## Dendritic Conversion (future)

The repo has been refactored (Option A) to be dendritic-ready. A later switch to
the full [dendritic pattern](https://github.com/mightyiam/dendritic) (every file a
flake-parts module via `flake.modules.<class>.<aspect>`, whole-tree `import-tree`,
hosts as feature-tag lists) would be a plumbing flip rather than a rewrite.

Prerequisites already satisfied:

- [x] `lib.custom` helpers (`modules/lib/`) — mkScript, mkContainer,
      mkTerminalPalette, mkRequireWayland, mkRustdeskConfigScript.
- [x] Generic, option-driven `custom.programs.*` / `custom.scripts.*` /
      `custom.theme` modules (auto-imported). Behaviour lives in the program
      module; each user declares only their own choices in their entry file.
- [x] Host base injected in `mkHost` (core/common/tailscale + `hostName`).

Remaining for a true dendritic conversion:

- [ ] Introduce `flake.modules.{nixos,homeManager}.<aspect>` wiring and run
      `import-tree` over the whole `modules/` tree (hosts included), replacing the
      manual `../../../modules/nixos/...` imports and the explicit `nixosSystem`
      module lists.
- [ ] Merge genuinely cross-layer reusable features into single aspect files that
      contribute to both NixOS and home-manager: - `nvidia` (system nvidia + the home-side VAAPI env in `discord.nix`) - `gnome-keyring` (currently home-only; could own the system bits too) - `rustdesk` client (system daemon + home program already share
      `lib.custom.mkRustdeskConfigScript`; one aspect file could own both) - Note: `beszel` and `tailscale` are already clean single NixOS modules with
      no home-side fragment — nothing to merge.
- [ ] Convert hosts to feature-tag lists.
- [ ] Non-goal: do NOT fold the windwaker host-specific containers under
      `modules/hosts/windwaker/services/` into shared cross-layer features. They
      are windwaker-only and stay services (they already use `lib.custom.mkContainer`
      for the shared unit boilerplate).

## Intentionally Kept

- The home-manager layer deliberately has **no shared `profiles/` aggregation
  layer**. Each `custom.programs.*` module is generic and reusable; every
  _opinion_ (which programs, which Zen extensions, which Discord plugins, zed
  vs vscode, persistence dirs, niri layout) is declared explicitly in the
  owning user's entry file (`modules/users/<user>/<host>.nix`). This is more
  verbose than a profile bundle, but it means one user can diverge freely
  without editing anything another user consumes — adding a program is
  `custom.programs.<x>.enable = true` in your own file, nothing else. Do not
  reintroduce a `profiles/` layer that bakes personal choices into shared files.
- Keep browser extension pinning ignored for now.
- Keep ActivityWatch behavior unchanged.
- EasyEffects preset is intentionally **mutable**: the activation script copies
  the preset out of the store so it can be tweaked live, and `micsave` commits
  the live preset back to the repo. Do not "fix" this into a read-only symlink.
- RustDesk writes the server address + key into `RustDesk2.toml` (a file the app
  then owns). The key/address come from sops files read at activation/first boot,
  not from argv. Accepted on these mostly single-user hosts.

## Resolved

- [x] Pin SSH host identity for SSHFS mounts — `knownHostKey` option on the sshfs
      module; navi pins windwaker's ed25519 key (StrictHostKeyChecking=yes).
- [x] RustDesk module semantics and secret handling — fixed the bug where the
      server **path** was written into `RustDesk2.toml` instead of the address;
      `server` → `serverFile` (read at runtime) for both the system daemon and the
      home program, via the shared `lib.custom.mkRustdeskConfigScript`.
- [x] Replace deprecated `@modelcontextprotocol/server-brave-search` — removed
      entirely (archived upstream; Brave free API tier ended Feb 2026). context7
      now passes its key via `CONTEXT7_API_KEY` env instead of `--api-key` in argv.
