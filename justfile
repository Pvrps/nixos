# List all available commands
default:
    @just --list

# Update flake inputs and pinned OpenCode MCP tools
update:
    nix flake update
    nix shell nixpkgs#nodejs nixpkgs#prefetch-npm-deps -c scripts/update-opencode-tools

# Edit a sops-encrypted secrets file
# Optionally override the age key path (e.g. during install from live USB)
#   just secrets                                                → _secrets.yaml
#   just secrets services/_docker-secrets                       → services/_docker-secrets.yaml
#   just secrets services/_docker-secrets windwaker             → override host
#   just secrets services/_docker-secrets windwaker /path/key   → override host + key
secrets secretsfile="_secrets" host=`hostname` keyfile="/persist/system/sops/age/keys.txt" age="age1cvx2v7vcmf0y9vmsq3nhkxuwkvgdmwa00e44p7zn2cdq7mgs79qq5ej46s":
    sudo SOPS_AGE_KEY_FILE={{keyfile}} nix --extra-experimental-features "nix-command flakes" run nixpkgs#sops -- --age {{age}} modules/hosts/{{host}}/{{secretsfile}}.yaml

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
