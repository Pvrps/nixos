# TODO

## Security Later

- [ ] Revisit Secure Boot / Lanzaboote (input now at v1.1.0; module dormant on
      navi/mickey — `#secureboot.enable` comments mark the switch).
- [ ] Replace Mickey password SSH with pubkey auth.
- [ ] Revisit Bluetooth hardening without breaking 8BitDo Pro 2 pairing.
- [ ] Revisit input/uinput permissions after testing Steam Input and controller mapping.
- [ ] Consider git commit signing.

## Intentionally Kept

- Shared _opinions_ (Discord plugins, Steam millennium plugins, Zen mods, fish
  aliases) are **option defaults** in the program modules. Per-user divergence
  is a single override in the user's own file; no shared file needs editing.
- EasyEffects presets are intentionally **mutable and per-user**: the
  activation script copies the preset out of the store so it can be tweaked
  live, and `micsave` commits the live preset back to the repo. Sharing one
  preset file between users would let one user's `micsave` clobber the
  other's. Do not "fix" either property.
- RustDesk writes the server address + key into `RustDesk2.toml` (a file the
  app then owns). The key/address come from sops files read at
  activation/first boot, not from argv. Accepted on these mostly single-user
  hosts.
- Keep browser extension pinning ignored for now (`latest.xpi` URLs).
- Keep ActivityWatch behavior unchanged.
- Dormant-but-kept modules (ghostty, termfilepickers, secureboot,
  dragonwilds, linux-wallpaperengine's GUI): option-gated, cost nothing while
  disabled.
- The `dockerVolumeDir` let-binding in each windwaker service file is for
  volume path interpolation, not duplication of mkContainer's default.

## Resolved

- [x] Restructure (2026-07): auto-imported option-gated modules, host
      profiles (workstation/remote-admin/portals/persist base), home module
      defaults + desktop profile, mkUserSecrets, shared disko layout,
      camelCase option names, mkScript everywhere, windwaker
      hashedPasswordFile bug, stale pins refreshed, wallpaper vendored.
      Dendritic conversion evaluated and rejected: for 4 hosts / 3 users it
      adds indirection without payoff.
- [x] Pin SSH host identity for SSHFS mounts — `knownHostKey` option on the sshfs
      module; navi pins windwaker's ed25519 key (StrictHostKeyChecking=yes).
- [x] RustDesk module semantics and secret handling — `server` → `serverFile`
      (read at runtime) for both the system daemon and the home program, via
      the shared `lib.custom.mkRustdeskConfigScript`.
- [x] Replace deprecated `@modelcontextprotocol/server-brave-search` — removed
      entirely; context7 passes its key via `CONTEXT7_API_KEY` env.
