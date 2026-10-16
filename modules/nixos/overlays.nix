{
  inputs,
  lib,
  ...
}: {
  nixpkgs.overlays = [
    # nixpkgs passes -Dmimalloc to every Lix version, but the option only
    # exists from 2.96, so lix 2.95.x fails in configurePhase (and is thus
    # uncached). Fixed upstream in NixOS/nixpkgs@8d8ca25b2e; drop this once
    # nixos-unstable includes it (the filter is a no-op from then on).
    (final: prev: {
      lix = prev.lix.overrideAttrs (old: {
        mesonFlags =
          if lib.versionOlder old.version "2.96"
          then lib.filter (f: !lib.hasPrefix "-Dmimalloc=" f) old.mesonFlags
          else old.mesonFlags;
      });
    })

    # xwayland-satellite 0.8.2 broke X11 override-redirect popup pointer
    # grabs, causing Steam's context/friends menus (and similar XWayland
    # popups) to close almost instantly under niri. Pin to 0.8.1 until
    # fixed upstream.
    # https://github.com/Supreeeme/xwayland-satellite/issues/468
    (final: prev: {
      xwayland-satellite = inputs.nixpkgs-xwayland-satellite-fix.legacyPackages.${prev.stdenv.hostPlatform.system}.xwayland-satellite;
    })
  ];
}
