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
# just secrets services/_docker-secrets windwaker /path/key   → override host + key
secrets secretsfile="_secrets" host=`hostname` keyfile="/persist/system/sops/age/keys.txt":
    @sudo SOPS_AGE_KEY_FILE={{ keyfile }} nix --extra-experimental-features "nix-command flakes" run nixpkgs#sops -- modules/hosts/{{ host }}/{{ secretsfile }}.yaml

# Build and set the new configuration for the next boot
boot host=`hostname`:
    nh os boot . -H {{ host }}

# Build and switch to the new configuration
switch host=`hostname`:
    nh os switch . -H {{ host }}
    @{{ just_executable() }} reactivate

# home-manager activation lives entirely in home-manager-<user>.service, and
# switch-to-configuration only restarts a unit whose *unit file* changed. That
# file embeds the generation store path, so when the home-manager closure is
# unchanged the unit is left alone and no activation script runs — silently
# skipping the ones that reconcile app-owned files (bolt, easyeffects,
# rustdesk, obs, osu). Restarting the unit is the only way to force them.
#
# Running this from a logged-in session is also strictly better than the
# activation that happens at boot: hm-setup-env imports DBUS_SESSION_BUS_ADDRESS,
# DISPLAY, WAYLAND_DISPLAY and XDG_RUNTIME_DIR from the live session, so
# reloadSystemd actually reloads user units instead of logging
# "User systemd daemon not running. Skipping reload."
[doc("Re-run home-manager activation, even when nothing has changed")]
reactivate user=`whoami`:
    sudo systemctl restart home-manager-{{ user }}.service
    @journalctl _SYSTEMD_INVOCATION_ID="$(systemctl show -p InvocationID --value home-manager-{{ user }}.service)" --no-pager -o cat

# Dry build the configuration without switching
build host=`hostname`:
    nh os build . -H {{ host }}

# Analyze build errors with full trace and formatted output
analyze host=`hostname`:
    @scripts/analyze {{ host }}

# Delete old generations and perform garbage collection
cleanup:
    nh clean all -k 3

# Get the sha256 SRI hash for a given URL (useful for pkgs.fetchurl)
hash url:
    @nix store prefetch-file --json "{{ url }}" | nix run nixpkgs#jq -- -r .hash

# Format Nix/Shell/YAML/JSON/Markdown files
format:
    nix fmt
