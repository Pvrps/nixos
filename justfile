# List all available commands
default:
    @just --list

# Uses upstream CppNix instead of Lix to update flake.lock.
# Lix errors on `shallow` git inputs (used by millenium's sub-inputs), CppNix silently ignores them.
# Lix will still handle all builds normally.
# Required until Lix adds support for the `shallow` attribute on `github:` inputs.
update:
    nix run nixpkgs#nixVersions.latest -- flake update

# Update the system secrets file
secrets host=`hostname`:
    sudo SOPS_AGE_KEY_FILE=/persist/system/sops/age/keys.txt nix run nixpkgs#sops -- modules/hosts/{{host}}/_secrets.yaml

# Build and set the new configuration for the next boot
boot host=`hostname`:
    nh os boot . -H {{host}}

# Build and switch to the new configuration
switch host=`hostname`:
    nh os switch . -H {{host}}

# Dry build the configuration without switching
build host=`hostname`:
    nh os build . -H {{host}}

# Delete old generations and perform garbage collection
cleanup:
    nh clean all -k 3
    nh clean all -k 3

# Get the sha256 SRI hash for a given URL (useful for pkgs.fetchurl)
hash url:
    @nix store prefetch-file --json "{{url}}" | nix run nixpkgs#jq -- -r .hash

# Format Nix/Shell/YAML/JSON/Markdown files
format:
    nix fmt
