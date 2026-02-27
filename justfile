# Update the system secrets file
secrets:
    sudo SOPS_AGE_KEY_FILE=/persist/system/sops/age/keys.txt nix run nixpkgs#sops -- systems/desktop/secrets.yaml

# Build and switch to the new configuration
switch:
    sudo nixos-rebuild switch --flake .#desktop

# Dry build the configuration without switching
build:
    nixos-rebuild dry-build --flake .#desktop

# Format and lint the code
validate:
    nix run nixpkgs#alejandra -- .
    nix run nixpkgs#statix -- check .
