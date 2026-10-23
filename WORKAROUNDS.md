# Workarounds, forks & overrides

Custom packages, patches, pins and overlays that exist only because something
upstream is missing, broken or unmerged. Each entry says **why** it exists and
**when it can be removed**, so the list can be reviewed periodically or handed
to an LLM ("resolve entries in WORKAROUNDS.md whose removal condition is met").

Every site in the code carries a `# WORKAROUND: ... see WORKAROUNDS.md`
comment, so `grep -rn WORKAROUND` lists them all. Pins that are not workarounds
(image digests, release zips, tags) live in [MAINTENANCE.md](MAINTENANCE.md).

When adding a workaround: tag the site, add an entry here. When removing one:
delete both.

## Kernel modules

### v4l2loopback `modules.*` index files

- **Where:** `modules/hosts/navi/_hardware.nix` (`extraModulePackages`)
- **Why:** Kernel 7.3's `modules_install` runs `depmod` itself, so the package
  ships `modules.*` files that collide with the kernel's in `buildEnv`
  (NixOS/nixpkgs#575851).
- **Remove when:** nixpkgs includes PR #575861 (merged 2026-10-21). Replace the
  `overrideAttrs` with `with config.boot.kernelPackages; [ v4l2loopback ]`.

## Forked or patched packages

### nvidia-x11 binaries re-patched in two patchelf calls

- **Where:** `modules/nixos/nvidia.nix` (`hardware.nvidia.package`)
- **Why:** patchelf 0.19.2 produces overlapping `LOAD` segments when the
  interpreter and rpath are set in one call, so `nvidia-smi` (and the other
  `bin/` tools) segfault in `ld.so` on start (NixOS/nixpkgs#576412). The Beszel
  agent runs `nvidia-smi` every 5 s, flooding the journal and coredump dir.
  `postFixup` re-patches the originals from `origBin/` with rpath and
  interpreter set separately.
- **Remove when:** the locked nixpkgs includes PR #576397 (merged 2026-10-21,
  merge commit `ae9ba0c0ab39`). Drop the `package` override.

### niri tearing fork (`urayde/niri`)

- **Where:** `flake.nix` (`niri-tearing`), `modules/hosts/navi/session.nix`,
  option `custom.niri.tearingFork`
- **Why:** screen tearing (wp-tearing-control, `allow-tearing` window rule) plus
  explicit sync, rebased on upstream main periodically. Tracks the fork's
  latest commit via the nightly `flake update`. Built locally against our
  nixpkgs through the fork's overlay (tests skipped), with no binary cache.
- **Remove when:** upstream niri gets tearing (blocked on
  https://github.com/Smithay/smithay/pull/1948).

### arrpc (OpenAsar/arrpc PR #143)

- **Where:** `modules/home/programs/communication/arrpc.nix`,
  `modules/home/patches/arrpc.patch`
- **Why:** the PR #143 branch drastically improves Linux/Proton game detection:
  - `ARRPC_BRIDGE_HOST` support (binds the WebSocket bridge to 127.0.0.1 by
    default)
  - broader path-segment matching for non-Steam Linux native game detection
  - Steam reaper detection: parses `AppId=` from Steam's reaper wrapper process
    and cross-references `third_party_skus` in the detectable DB, fixing games
    like Forza Horizon 6 that have no `executables[]` entry
- **Remove when:** PR #143 lands in nixpkgs' `arrpc`. Drop the whole override.
- **Bump:** `rev` is pinned to the head of `refs/pull/143/head`. Update rev and
  hash together:
  `git ls-remote https://github.com/OpenAsar/arrpc refs/pull/143/head` and
  `nix-prefetch-github OpenAsar arrpc --rev <rev>`.

### chatterino7-kick fork

- **Where:** `modules/home/programs/communication/chatterino.nix`
- **Why:** upstream chatterino2 has no Kick support (only the IRC `/kick`
  command). This is the only fork with real Kick.com chat integration while
  keeping all 7TV features (paints, personal emotes, animated avatars). The
  fork's CMake `find_package()`s `Qt6::WebSockets`, which is absent from
  nixpkgs' `common.nix` buildInputs, hence the added `qtwebsockets`.
- **Remove when:** Kick support lands in upstream chatterino2.
- **Bump:** `rev` is pinned to the head of the `002-polish-kick-integration`
  branch. Update rev and hash together:
  `git ls-remote https://github.com/sambegui/chatterino7 002-polish-kick-integration`
  and
  `nix run nixpkgs#nix-prefetch -- --unpack https://github.com/sambegui/chatterino7/archive/<rev>.tar.gz`.

### yazi Sixel alpha patch

- **Where:** `modules/home/programs/files/yazi.nix`,
  `modules/home/patches/yazi-sixel-alpha.patch`
- **Why:** yazi's Sixel encoder composites RGBA images onto black before
  palette-quantising, making dark content on transparent backgrounds invisible
  (black-on-black). Specific to Sixel (foot); KGP terminals like Ghostty are
  unaffected. The patch alpha-composites onto a neutral grey checkerboard
  instead. Only applied when `custom.programs.foot` is enabled, so other hosts
  keep the cached, unmodified `pkgs.yazi`.
- **Remove when:** upstream yazi fixes Sixel alpha compositing.

### wallpaperengine-gui from a pinned commit

- **Where:** `modules/home/programs/desktop/linux-wallpaperengine.nix`
- **Why:** not packaged in nixpkgs.
- **Remove when:** nixpkgs adds `wallpaperengine-gui`. Check nixpkgs first.
- **Bump:** update `rev` and `hash` together.

### CUDA onnxruntime for OBS background removal

- **Where:** `modules/home/programs/media/obs.nix`
- **Why:** `obs-backgroundremoval` uses onnxruntime, which is overridden with a
  CUDA build on NVIDIA systems so inference runs on the GPU. onnxruntime
  `dlopen()`s `libonnxruntime_providers_cuda.so` without listing its deps in
  `NEEDED`, so inside the Flatpak sandbox the load needs both:
  1. `LD_LIBRARY_PATH`, so the CUDA toolkit libs (cublas, cudart, ...) are
     found transitively when the provider is opened.
  2. `LD_PRELOAD` of `libnvrtc.so.12` and `libonnxruntime_providers_shared.so`,
     which must be in the global symbol table before the provider is
     `dlopen()`ed, since the provider has undefined references to both.
- **Remove when:** the plugin or nixpkgs ships a working CUDA provider, or the
  Flatpak sandbox loads it without the preload hack.
