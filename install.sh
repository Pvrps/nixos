#!/usr/bin/env bash
set -euo pipefail

# NixOS Automated Install Script
# This script automates the complete fresh NixOS installation process

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Step 1: Check for internet connectivity
log_info "Checking internet connectivity..."
if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    log_error "No internet connectivity detected. Please connect to the internet first."
    log_info "For WiFi, run: nmcli device wifi connect \"SSID\" password \"password\""
    exit 1
fi
log_info "Internet connectivity: OK"

# Get the script directory (where the config files are)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Step 2: Run disko to partition and format the disk
log_info "Running disko to partition and format the disk..."
log_warn "This will WIPE THE DISK specified in systems/desktop/disko.nix!"
read -r -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    log_error "Installation aborted by user."
    exit 1
fi

log_info "Starting disk partitioning with disko..."
if ! nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./systems/desktop/disko.nix; then
    log_error "Disko failed. Please check your disko.nix configuration."
    exit 1
fi
log_info "Disk partitioning completed successfully."

# Step 3: Generate hardware config
log_info "Generating hardware configuration..."
if ! nixos-generate-config --no-filesystems --show-hardware-config > "$SCRIPT_DIR/systems/desktop/hardware.nix"; then
    log_error "Failed to generate hardware configuration."
    exit 1
fi
log_info "Hardware configuration saved to systems/desktop/hardware.nix"

# Step 4: Create age key for sops-nix
log_info "Creating age key for sops-nix..."
AGE_DIR="/mnt/persist/system/sops/age"
AGE_KEY_FILE="$AGE_DIR/keys.txt"

mkdir -p "$AGE_DIR"

if ! nix-shell -p age --run "age-keygen -o $AGE_KEY_FILE"; then
    log_error "Failed to generate age key."
    exit 1
fi

chown -R 0:0 "/mnt/persist/system"
chown 700 "$AGE_DIR"
chown 600 "$AGE_KEY_FILE"

# Set correct ownership (UID 1000 for purps user)
mkdir -p /mnt/persist/home/purps
chown -R 1000:1000 /mnt/persist/home/purps
log_info "Age key created at $AGE_KEY_FILE"

# Extract public key (everything after "public key: ")
PUBLIC_KEY=$(grep "# public key:" "$AGE_KEY_FILE" | sed 's/.*public key: //')
if [ -z "$PUBLIC_KEY" ]; then
    log_error "Failed to extract public key from age key file."
    exit 1
fi
log_info "Public key: $PUBLIC_KEY"

# Step 5: Update .sops.yaml with the generated public key
log_info "Updating .sops.yaml with the generated public key..."
SOPS_YAML="$SCRIPT_DIR/.sops.yaml"

# Create a backup of the original .sops.yaml
cp "$SOPS_YAML" "$SOPS_YAML.backup"

# Update .sops.yaml with the new public key
cat > "$SOPS_YAML" <<EOF
creation_rules:
  - path_regex: systems/desktop/secrets\.yaml\$
    key_groups:
      - age:
          - $PUBLIC_KEY
EOF

log_info ".sops.yaml updated successfully."

# Step 6: Prompt for and create encrypted password
log_info "Creating encrypted password for user purps..."

# Prompt for password
echo -n "Enter password for user purps: "
read -s USER_PASSWORD
echo
echo -n "Confirm password: "
read -s USER_PASSWORD_CONFIRM
echo

if [ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]; then
    log_error "Passwords do not match."
    exit 1
fi

if [ -z "$USER_PASSWORD" ]; then
    log_error "Password cannot be empty."
    exit 1
fi

# Create hashed password and encrypt it with sops
log_info "Creating and encrypting secrets.yaml..."
SECRETS_FILE="$SCRIPT_DIR/systems/desktop/secrets.yaml"

# Generate password hash and create secrets.yaml
PASSWORD_HASH=$(echo -n "$USER_PASSWORD" | nix-shell -p mkpasswd --run "mkpasswd -m sha-512 --stdin" | tr -d '\n')
printf "purps-password: |\n %s\n" "$PASSWORD_HASH" > "$SECRETS_FILE"

# Clear password variables from memory
unset USER_PASSWORD
unset USER_PASSWORD_CONFIRM

# Encrypt the secrets file
if ! nix-shell -p sops --run "SOPS_AGE_KEY_FILE=$AGE_KEY_FILE sops -e -i $SECRETS_FILE"; then
    log_error "Failed to encrypt secrets.yaml."
    exit 1
fi

log_info "Password created and encrypted successfully."

# Step 7: Copy config to persistent location
log_info "Copying configuration to /mnt/persist/etc/nixos/..."
PERSISTENT_CONFIG="/mnt/persist/etc/nixos"

mkdir -p "$PERSISTENT_CONFIG"
cp -r "$SCRIPT_DIR/." "$PERSISTENT_CONFIG/"
chown -R 1000:100 "$PERSISTENT_CONFIG"

log_info "Configuration copied to $PERSISTENT_CONFIG"

# Step 8: Run nixos-install from persistent location
log_info "Preparing Git repository in persistent location..."

git config --global --add safe.directory "$PERSISTENT_CONFIG"

git -C "$PERSISTENT_CONFIG" add -A

git -C "$PERSISTENT_CONFIG" -c "user.name=purps" -c "user.email=github@purps.ca" commit -m "Install: automated hardware and secrets generation" || true




log_info "Running nixos-install from persistent location..."
log_warn "This may take a while..."

if ! nixos-install --flake "$PERSISTENT_CONFIG#desktop" --no-root-passwd; then
    log_error "nixos-install failed. Please check the error messages above."
    exit 1
fi

log_info "NixOS installation completed successfully!"

# Display completion message
cat <<EOF

${GREEN}==========================================================
Installation completed successfully!
==========================================================${NC}

${GREEN}Your age key is stored at:${NC} $AGE_KEY_FILE
${GREEN}Configuration is at:${NC} $PERSISTENT_CONFIG
${GREEN}Backup .sops.yaml saved at:${NC} $SOPS_YAML.backup

${YELLOW}Optional configuration edits:${NC}
   - Timezone: $PERSISTENT_CONFIG/systems/desktop/default.nix
   - Git config: $PERSISTENT_CONFIG/home/programs/git.nix

${YELLOW}To complete installation:${NC}
   reboot

EOF
