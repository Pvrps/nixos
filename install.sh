#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

if [ "$EUID" -ne 0 ]; then
  log_error "Please run as root (use sudo)"
  exit 1
fi

if [ -z "${1:-}" ]; then
  log_error "Usage: $0 <hostname>"
  log_info "Available hosts:"
  ls -1 modules/hosts/ | grep -v '^\.'
  exit 1
fi

HOST="$1"
HOST_DIR="modules/hosts/$HOST"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$SCRIPT_DIR/$HOST_DIR" ]; then
  log_error "Host configuration directory '$HOST_DIR' not found."
  exit 1
fi

cd "$SCRIPT_DIR"

log_info "Checking internet connectivity..."
if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
  log_error "No internet connectivity detected. Please connect to the internet first."
  log_info 'For WiFi, run: nmcli device wifi connect "SSID" password "password"'
  exit 1
fi
log_info "Internet connectivity: OK"

log_info "Running disko to partition and format the disk for host '$HOST'..."
log_warn "This will WIPE THE DISK specified in $HOST_DIR/_disko.nix!"
read -r -p "Are you sure you want to continue? (Y/n): " confirm
if [[ $confirm =~ ^[Nn] ]]; then
  log_warn "Skipping disk partitioning."
else
  log_info "Starting disk partitioning with disko..."
  if ! nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./$HOST_DIR/_disko.nix; then
    log_error "Disko failed. Please check your _disko.nix configuration."
    exit 1
  fi
  log_info "Disk partitioning completed successfully."
fi

if [ -f "$SCRIPT_DIR/$HOST_DIR/_hardware.nix" ] && grep -q "fileSystems" "$SCRIPT_DIR/$HOST_DIR/_hardware.nix"; then
  log_info "_hardware.nix already exists and seems populated; skipping generation."
else
  log_info "Generating hardware configuration..."
  if ! nixos-generate-config --no-filesystems --show-hardware-config >"$SCRIPT_DIR/$HOST_DIR/_hardware.nix"; then
    log_error "Failed to generate hardware configuration."
    exit 1
  fi
  log_info "Hardware configuration saved to $HOST_DIR/_hardware.nix"
fi

AGE_DIR="/mnt/persist/system/sops/age"
AGE_KEY_FILE="$AGE_DIR/keys.txt"
TMP_KEY_FILE="$SCRIPT_DIR/keys.txt"

mkdir -p "$AGE_DIR"

if [ -f "$AGE_KEY_FILE" ]; then
  log_info "Age key already exists at $AGE_KEY_FILE — skipping generation."
else
  read -r -p "Bring over own SOPS age key file using magic-wormhole? (y/N): " bring_key
  if [[ $bring_key =~ ^[Yy]$ ]]; then
    log_info "Setting up magic-wormhole to receive key..."
    log_info "On your other machine, run: wormhole send ~/.config/sops/age/keys.txt"
    if ! nix-shell -p magic-wormhole --run "wormhole receive -o \"$TMP_KEY_FILE\""; then
      log_error "Failed to receive key via magic-wormhole."
      exit 1
    fi
  fi

  if [ -f "$TMP_KEY_FILE" ]; then
    log_info "Using received age key."
    cp "$TMP_KEY_FILE" "$AGE_KEY_FILE"
    rm -f "$TMP_KEY_FILE"
  else
    log_info "Creating age key for sops-nix..."
    if ! nix-shell -p age --run "age-keygen -o $AGE_KEY_FILE"; then
      log_error "Failed to generate age key."
      exit 1
    fi
    log_info "Age key created at $AGE_KEY_FILE"
  fi
fi

chown -R 0:0 "/mnt/persist/system"
chmod 700 "$AGE_DIR"
chmod 600 "$AGE_KEY_FILE"

SECRETS_FILE="$SCRIPT_DIR/$HOST_DIR/_secrets.yaml"
PUBLIC_KEY=$(grep "# public key:" "$AGE_KEY_FILE" | sed 's/.*public key: //')

if [ -z "$PUBLIC_KEY" ]; then
  log_error "Failed to extract public key from age key file."
  exit 1
fi

log_info "Public key: $PUBLIC_KEY"

SOPS_YAML="$SCRIPT_DIR/.sops.yaml"

if ! grep -q "$PUBLIC_KEY" "$SOPS_YAML"; then
  log_info "Adding new host rule to .sops.yaml..."
  cat >>"$SOPS_YAML" <<EOF
  - path_regex: $HOST_DIR/_secrets\.yaml\$
    key_groups:
      - age:
          - $PUBLIC_KEY
EOF
  log_info ".sops.yaml updated successfully."
else
  log_info ".sops.yaml already contains a rule for this host."
fi

# =========================================================================
# 1. DISCOVER USERS & CREATE PERSISTENT DIRECTORIES (Runs Every Time)
# =========================================================================
log_info "Discovering users from NixOS configuration for host '$HOST'..."
# We extract both the username and their UID (defaulting to 1000 if not set) as "user:uid"
USERS_STR=$(nix --experimental-features "nix-command flakes" eval --json ".#nixosConfigurations.$HOST.config.users.users" | nix-shell -p jq --run 'jq -r "to_entries | map(select(.value.isNormalUser)) | map(\"\(.key):\(.value.uid // 1000)\") | join(\" \")"')

if [ -z "$USERS_STR" ]; then
  log_error "Could not automatically determine users for host '$HOST'. Check your configuration."
  exit 1
fi

read -ra USERS <<<"$USERS_STR"

for USER_ENTRY in "${USERS[@]}"; do
  # Parse the string splitting by the colon (e.g. "purps:1000")
  INSTALL_USER="${USER_ENTRY%%:*}"
  USER_UID="${USER_ENTRY##*:}"

  if [ -z "$INSTALL_USER" ] || [ "$INSTALL_USER" == "root" ]; then continue; fi

  if [ -d "/mnt/persist/home/$INSTALL_USER" ]; then
    log_info "Persistent home for $INSTALL_USER already exists — skipping."
  else
    log_info "Pre-creating persistent home directory for $INSTALL_USER (UID: $USER_UID)..."
    mkdir -p "/mnt/persist/home/$INSTALL_USER"
    # Set correct ownership right away so Impermanence doesn't cause Permission Denied errors
    # 100 is the default GID for the 'users' group in NixOS
    chown "$USER_UID:100" "/mnt/persist/home/$INSTALL_USER"
  fi
done

# =========================================================================
# 2. GENERATE SECRETS (Only runs if secrets.yaml is missing or empty)
# =========================================================================

SECRETS_FILE_PERSISTENT_EARLY="/mnt/persist/etc/nixos/modules/hosts/$HOST/_secrets.yaml"
# Check both the working copy and the persistent copy — on a re-run the
# working copy may still be the unencrypted placeholder from git.
SECRETS_ALREADY_ENCRYPTED=false
if grep -q "ENC\[AES256_GCM" "$SECRETS_FILE" 2>/dev/null; then
  SECRETS_ALREADY_ENCRYPTED=true
elif grep -q "ENC\[AES256_GCM" "$SECRETS_FILE_PERSISTENT_EARLY" 2>/dev/null; then
  log_info "Found encrypted secrets in persistent location — copying to working copy."
  cp "$SECRETS_FILE_PERSISTENT_EARLY" "$SECRETS_FILE"
  SECRETS_ALREADY_ENCRYPTED=true
fi

if [ "$SECRETS_ALREADY_ENCRYPTED" = "false" ]; then
  # Detect whether this host disables password authentication (SSH-key-only hosts).
  # If PasswordAuthentication is false, offer to auto-generate random passwords
  # instead of prompting — the user will never need to type them.
  SSH_PASSWORD_AUTH=$(nix --experimental-features "nix-command flakes" eval --json \
    ".#nixosConfigurations.$HOST.config.services.openssh.settings.PasswordAuthentication" 2>/dev/null || echo "true")

  if [ "$SSH_PASSWORD_AUTH" = "false" ]; then
    log_info "SSH PasswordAuthentication is disabled on this host (SSH-key-only)."
    read -r -p "Auto-generate random passwords for all users? (Y/n): " auto_pass
    auto_pass="${auto_pass:-Y}"
  else
    auto_pass="n"
  fi
  log_info "Generating initial secrets for host '$HOST'..."

  TMP_SECRETS=$(mktemp)

  for USER_ENTRY in "${USERS[@]}"; do
    INSTALL_USER="${USER_ENTRY%%:*}"
    if [ -z "$INSTALL_USER" ] || [ "$INSTALL_USER" == "root" ]; then continue; fi

    if [[ $auto_pass =~ ^[Yy]$ ]]; then
      log_info "Auto-generating random password for $INSTALL_USER..."
      USER_PASSWORD=$(nix-shell -p openssl --run "openssl rand -base64 32" | tr -d '\n')
    else
      echo -n "Enter password for user $INSTALL_USER: "
      read -s USER_PASSWORD
      echo
      echo -n "Confirm password for $INSTALL_USER: "
      read -s USER_PASSWORD_CONFIRM
      echo

      if [ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]; then
        log_error "Passwords do not match for $INSTALL_USER. Aborting."
        rm -f "$TMP_SECRETS"
        exit 1
      fi

      if [ -z "$USER_PASSWORD" ]; then
        log_error "Password cannot be empty for $INSTALL_USER. Aborting."
        rm -f "$TMP_SECRETS"
        exit 1
      fi
    fi

    PASSWORD_HASH=$(echo -n "$USER_PASSWORD" | nix-shell -p mkpasswd --run "mkpasswd -m sha-512 --stdin" | tr -d '\n')
    printf "%s-password: |\n  %s\n" "$INSTALL_USER" "$PASSWORD_HASH" >>"$TMP_SECRETS"
  done

  if [ -s "$TMP_SECRETS" ]; then
    log_info "Encrypting secrets.yaml..."
    cat "$TMP_SECRETS" >"$SECRETS_FILE"
    if ! nix-shell -p sops --run "SOPS_AGE_KEY_FILE='$AGE_KEY_FILE' sops -e -i '$SECRETS_FILE'"; then
      log_error "Failed to encrypt secrets.yaml."
      rm -f "$TMP_SECRETS"
      exit 1
    fi
    log_info "Passwords created and encrypted successfully."
  else
    log_warn "No users found. secrets.yaml will remain unchanged."
  fi
  rm -f "$TMP_SECRETS"
else
  log_info "secrets.yaml already encrypted — skipping user password generation."
fi

log_info "Copying configuration to /mnt/persist/etc/nixos/..."
PERSISTENT_CONFIG="/mnt/persist/etc/nixos"

mkdir -p "$PERSISTENT_CONFIG"
cp -r "$SCRIPT_DIR/." "$PERSISTENT_CONFIG/"
# Ensure we own the copied config folder (assuming main user is 1000)
chown -R 1000:100 "$PERSISTENT_CONFIG" 2>/dev/null || true

log_info "Preparing Git repository in persistent location..."
git config --global --add safe.directory "$PERSISTENT_CONFIG"

# If this is a fresh install, we want to add any newly generated hardware.nix and secrets.yaml
git -C "$PERSISTENT_CONFIG" add -A
git -C "$PERSISTENT_CONFIG" -c "user.name=Automated Install" -c "user.email=install@localhost" commit -m "Install: automated hardware and secrets generation for $HOST" || true

# =========================================================================
# 3. INJECT EXTRA SECRETS via wormhole before nixos-install
# =========================================================================
# For each known secret key that requires a file (not a password), offer to
# receive it via magic-wormhole and inject it directly into _secrets.yaml.

SECRETS_FILE_PERSISTENT="$PERSISTENT_CONFIG/modules/hosts/$HOST/_secrets.yaml"

inject_secret_via_wormhole() {
  local secret_name="$1"
  local tmp_file
  tmp_file=$(mktemp)

  read -r -p "Receive '$secret_name' via magic-wormhole? (y/N): " do_wormhole
  if [[ ! $do_wormhole =~ ^[Yy]$ ]]; then
    rm -f "$tmp_file"
    return
  fi

  log_info "On your other machine run: wormhole send <path/to/key>"
  if ! nix-shell -p magic-wormhole --run "wormhole receive -o '$tmp_file'"; then
    log_error "Failed to receive '$secret_name' via magic-wormhole."
    rm -f "$tmp_file"
    return
  fi

  # Build the YAML block: first line is the key, subsequent lines indented
  local secret_yaml
  secret_yaml=$(printf '%s: |\n' "$secret_name"; sed 's/^/  /' "$tmp_file")
  rm -f "$tmp_file"

  # Append to a plaintext temp file, re-encrypt the whole secrets file
  local tmp_plain
  tmp_plain=$(mktemp)

  # Decrypt current secrets into plaintext, append new secret, re-encrypt
  nix-shell -p sops --run \
    "SOPS_AGE_KEY_FILE='$AGE_KEY_FILE' sops -d '$SECRETS_FILE_PERSISTENT'" >"$tmp_plain"
  printf '\n%s\n' "$secret_yaml" >>"$tmp_plain"
  cat "$tmp_plain" >"$SECRETS_FILE_PERSISTENT"
  nix-shell -p sops --run \
    "SOPS_AGE_KEY_FILE='$AGE_KEY_FILE' sops -e -i '$SECRETS_FILE_PERSISTENT'"
  rm -f "$tmp_plain"

  log_info "'$secret_name' injected and encrypted successfully."
}

# Only prompt if the secret isn't already in the encrypted file
if nix-shell -p sops --run "SOPS_AGE_KEY_FILE='$AGE_KEY_FILE' sops -d '$SECRETS_FILE_PERSISTENT'" 2>/dev/null | grep -q "github-ssh-key"; then
  log_info "github-ssh-key already present in secrets — skipping."
else
  inject_secret_via_wormhole "github-ssh-key"
fi

log_info "Activating swap to prevent OOM during nixos-install..."
SWAPFILE="/mnt/.swap/swapfile"
if [ -f "$SWAPFILE" ]; then
  swapon "$SWAPFILE" 2>/dev/null && log_info "Swap activated at $SWAPFILE." || log_info "Swap already active or skipped (non-fatal)."
else
  log_warn "Swapfile not found at $SWAPFILE — OOM may occur on low-RAM machines."
fi

log_info "Running nixos-install from persistent location..."
log_warn "This may take a while..."

if ! nixos-install --flake "$PERSISTENT_CONFIG#$HOST" --no-root-passwd; then
  log_error "nixos-install failed. Please check the error messages above."
  exit 1
fi

cat <<EOF

${GREEN}==========================================================
Installation completed successfully for host $HOST!
==========================================================${NC}

${YELLOW}To complete installation:${NC}
   reboot

EOF
