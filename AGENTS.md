## Workarounds and pins

- When adding a workaround for something broken or missing upstream (overlay, `overrideAttrs`, patch, pinned nixpkgs input, forked package, `mkForce` to dodge a bug):
  1. Put a one-line `# WORKAROUND: <short reason>, see WORKAROUNDS.md` comment at the site. Keep long explanations out of the code.
  2. Add an entry to `WORKAROUNDS.md` with: Where, Why, and Remove when. Add a Bump line if it pins a rev.
- When adding a pin that `nix flake update` won't bump (image digest or tag, release zip, tag-pinned input), put `# MAINTENANCE: see MAINTENANCE.md` at the site and add an entry to `MAINTENANCE.md`. If the pin is also a workaround, document it in `WORKAROUNDS.md` only.
- When removing either, delete the doc entry and the code comment.
- Writing `WORKAROUNDS.md` / `MAINTENANCE.md` is an exception to "don't commit documentation".
- Plain preference options and ordinary `mkForce` overrides are not workarounds; don't log them.
