{
  inputs,
  lib,
  ...
}: {
  nixpkgs.overlays = [
    # WORKAROUND: lix 2.95 rejects -Dmimalloc, see WORKAROUNDS.md
    (final: prev: {
      lix = prev.lix.overrideAttrs (old: {
        mesonFlags =
          if lib.versionOlder old.version "2.96"
          then lib.filter (f: !lib.hasPrefix "-Dmimalloc=" f) old.mesonFlags
          else old.mesonFlags;
      });
    })

    # WORKAROUND: xwayland-satellite 0.8.2 popup grab regression, see WORKAROUNDS.md
    (final: prev: {
      xwayland-satellite = inputs.nixpkgs-xwayland-satellite-fix.legacyPackages.${prev.stdenv.hostPlatform.system}.xwayland-satellite;
    })
  ];
}
