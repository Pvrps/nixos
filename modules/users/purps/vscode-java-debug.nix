{
  pkgs,
}:
# vscode-java-debug tries to mkdir ".noConfigDebugAdapterEndpoints" inside its
# own extension directory at activation time.  On NixOS the extension dir is a
# read-only store path, so the mkdir fails with ENOENT and the extension never
# activates (no Run/Debug/Test CodeLens buttons appear).
#
# Fix: redirect the socket-endpoint directory to $TMPDIR so the extension can
# write there freely.
pkgs.vscode-extensions.vscjava.vscode-java-debug.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    substituteInPlace $out/share/vscode/extensions/vscjava.vscode-java-debug/dist/extension.js \
      --replace 'v=o.join(t,".noConfigDebugAdapterEndpoints")' \
                'v=o.join(require("os").tmpdir(),".noConfigDebugAdapterEndpoints")'
  '';
})
