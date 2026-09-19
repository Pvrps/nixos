{inputs, ...}: {
  nixpkgs.overlays = [
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
