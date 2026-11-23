# Maintenance: things `nix flake update` will NOT bump

The nightly CI updates branch-tracking flake inputs only. These pins need
manual attention. Each site in the code carries a
`# MAINTENANCE: ... see MAINTENANCE.md` comment, so
`grep -rn MAINTENANCE` lists them all.

Pins that are also workarounds (arrpc, chatterino, wallpaperengine-gui,
xwayland-satellite) are documented, with their bump commands, in
[WORKAROUNDS.md](WORKAROUNDS.md).

When adding a pin that won't be auto-bumped: tag the site, add an entry here.
When removing one: delete both.

| Pin                               | Where                                                     | How to bump                                                                                                                                                                                             |
| --------------------------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Millennium plugin zips            | `modules/home/programs/gaming/steam.nix`                  | new release URL + `just hash <url>` (nix32 via `nix-prefetch-url`); bump url and sha256 together                                                                                                        |
| OpenCode npm tools (context7)     | `modules/home/programs/development/opencode/package.json` | `just update` handles it                                                                                                                                                                                |
| REA npm release (`rea-agents`)    | `modules/home/programs/development/rea/_package.nix`      | `just update` handles it (version + integrity); afterwards rebuild and `rea restart`, then run `rea doctor` inside the VM                                                                               |
| REA's JADX engine jar             | `modules/home/programs/development/rea/_package.nix`      | only when REA changes its pin (`src/android/JadxRelease.ts` upstream; `just update` prints a reminder): new URL + `just hash <url>`                                                                     |
| Nuvio AppImage                    | `modules/home/programs/media/nuvio/_package.nix`          | set `version` to the new NuvioDesktop release tag and `hash` to `nix hash to-sri --type sha256 <hex>` of the `.AppImage` line in that release's `SHA256SUMS.txt`                                        |
| Valkey image digest               | `modules/hosts/windwaker/services/immich.nix`             | update digest manually                                                                                                                                                                                  |
| Skyrim Together server image tag  | `modules/hosts/windwaker/services/skyrim-together.nix`    | exact tag (so podman-auto-update leaves it alone); must match the clients' STR version; list tags with `nix shell nixpkgs#skopeo -c skopeo list-tags docker://docker.io/tiltedphoques/st-reborn-server` |
| `noctalia` input on `cachix`      | `flake.nix`                                               | deliberate (guarantees a cached build, see docs.noctalia.dev/noctalia/getting-started/nixos#binary-cache); `nix flake update` still auto-bumps within the branch                                        |
| `nix-flatpak` / `lanzaboote` tags | `flake.nix`                                               | bump tag when upstream releases                                                                                                                                                                         |
