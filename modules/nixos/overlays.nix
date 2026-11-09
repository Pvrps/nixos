{
  nixpkgs.overlays = [
    # WORKAROUND: rustdesk-flutter missing libsodium build input, see WORKAROUNDS.md
    (final: prev: {
      rustdesk-flutter = prev.rustdesk-flutter.overrideAttrs (old: {
        buildInputs = (old.buildInputs or []) ++ [final.libsodium];
      });
    })
  ];
}
