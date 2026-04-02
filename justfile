# List all available commands
default:
    @just --list

# Update the system secrets file
secrets host=`hostname`:
    sudo SOPS_AGE_KEY_FILE=/persist/system/sops/age/keys.txt nix run nixpkgs#sops -- systems/{{host}}/secrets.yaml

# Build and set the new configuration for the next boot
boot host=`hostname`:
    sudo nixos-rebuild boot --flake .#{{host}}

# Build and switch to the new configuration
switch host=`hostname`:
    sudo nixos-rebuild switch --flake .#{{host}}

# Dry build the configuration without switching
build host=`hostname`:
    nixos-rebuild dry-build --flake .#{{host}}

# Format and lint the code
validate:
    nix run nixpkgs#alejandra -- .
    nix run nixpkgs#statix -- check .

# Delete old generations and perform garbage collection
cleanup:
    sudo nix-collect-garbage -d
    nix-collect-garbage -d

# Get the sha256 SRI hash for a given URL (useful for pkgs.fetchurl)
hash url:
    @nix store prefetch-file --json "{{url}}" | nix run nixpkgs#jq -- -r .hash
