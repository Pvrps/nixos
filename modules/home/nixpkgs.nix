{
  # home-manager uses its own nixpkgs instance (separate from the NixOS system nixpkgs,
  # because useUserPackages = true is set in flake.nix).
  # allowUnfree must be set here for HM packages, even though modules/nixos/core.nix also sets it.
  nixpkgs.config.allowUnfree = true;
}
