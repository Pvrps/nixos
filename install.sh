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
	ls -1 systems/ | grep -v '^\.'
	exit 1
fi

HOST="$1"
HOST_DIR="systems/$HOST"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -d "$SCRIPT_DIR/$HOST_DIR" ]; then
	log_error "Host configuration directory '$HOST_DIR' not found."
	exit 1
fi

cd "$SCRIPT_DIR"

log_info "Checking internet connectivity..."
if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
	log_error "No internet connectivity detected. Please connect to the internet first."
	log_info "For WiFi, run: nmcli device wifi connect \"SSID\" password \"password\""
	exit 1
fi
log_info "Internet connectivity: OK"

log_info "Running disko to partition and format the disk for host '$HOST'..."
log_warn "This will WIPE THE DISK specified in $HOST_DIR/disko.nix!"
read -r -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
	log_error "Installation aborted by user."
	exit 1
fi

log_info "Starting disk partitioning with disko..."
if ! nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko ./$HOST_DIR/disko.nix; then
	log_error "Disko failed. Please check your disko.nix configuration."
	exit 1
fi
log_info "Disk partitioning completed successfully."

if [ -f "$SCRIPT_DIR/$HOST_DIR/hardware.nix" ] && grep -q "fileSystems" "$SCRIPT_DIR/$HOST_DIR/hardware.nix"; then
	log_info "hardware.nix already exists and seems populated; skipping generation."
else
	log_info "Generating hardware configuration..."
	if ! nixos-generate-config --no-filesystems --show-hardware-config >"$SCRIPT_DIR/$HOST_DIR/hardware.nix"; then
		log_error "Failed to generate hardware configuration."
		exit 1
	fi
	log_info "Hardware configuration saved to $HOST_DIR/hardware.nix"
fi

AGE_DIR="/mnt/persist/system/sops/age"
AGE_KEY_FILE="$AGE_DIR/keys.txt"
TMP_KEY_FILE="$SCRIPT_DIR/keys.txt"

mkdir -p "$AGE_DIR"

if [ -f "$TMP_KEY_FILE" ]; then
	log_info "Using existing age key at $TMP_KEY_FILE"
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

chown -R 0:0 "/mnt/persist/system"
chmod 700 "$AGE_DIR"
chmod 600 "$AGE_KEY_FILE"

SECRETS_FILE="$SCRIPT_DIR/$HOST_DIR/secrets.yaml"
PUBLIC_KEY=$(grep "# public key:" "$AGE_KEY_FILE" | sed 's/.*public key: //')

if [ -z "$PUBLIC_KEY" ]; then
	log_error "Failed to extract public key from age key file."
	exit 1
fi

log_info "Public key: $PUBLIC_KEY"

SOPS_YAML="$SCRIPT_DIR/.sops.yaml"

if ! grep -q "$HOST_DIR/secrets\.yaml" "$SOPS_YAML"; then
	log_info "Adding new host rule to .sops.yaml..."
	cat >>"$SOPS_YAML" <<EOF
  - path_regex: $HOST_DIR/secrets\.yaml\$
    key_groups:
      - age:
          - $PUBLIC_KEY
EOF
	log_info ".sops.yaml updated successfully."
else
	log_info ".sops.yaml already contains a rule for this host."
fi

# Always prompt to create or update secrets if file doesn't exist or is empty/dummy
if [ ! -s "$SECRETS_FILE" ] || ! grep -q "ENC\[AES256_GCM" "$SECRETS_FILE"; then
	log_info "Generating initial secrets for host '$HOST'..."

	read -r -p "Enter comma-separated list of users to create passwords for (e.g., purps,michel): " USERS_LIST
	IFS=',' read -ra USERS <<<"$USERS_LIST"

	TMP_SECRETS=$(mktemp)

	for INSTALL_USER in "${USERS[@]}"; do
		INSTALL_USER=$(echo "$INSTALL_USER" | xargs) # Trim whitespace
		if [ -z "$INSTALL_USER" ]; then continue; fi

		# Pre-create home directory for user
		log_info "Pre-creating home directory for $INSTALL_USER at /mnt/persist/home/$INSTALL_USER"
		mkdir -p "/mnt/persist/home/$INSTALL_USER"
		# Note: we let systemd-sysusers and NixOS handle correct UID/GID chown on boot,
		# but we can do a generic chown here if we know the user is the first. We'll skip it to be safe.

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

		PASSWORD_HASH=$(echo -n "$USER_PASSWORD" | nix-shell -p mkpasswd --run "mkpasswd -m sha-512 --stdin" | tr -d '\n')
		printf "%s-password: |\n  %s\n" "$INSTALL_USER" "$PASSWORD_HASH" >>"$TMP_SECRETS"
	done

	if [ -s "$TMP_SECRETS" ]; then
		log_info "Encrypting secrets.yaml..."
		cat "$TMP_SECRETS" >"$SECRETS_FILE"
		if ! nix-shell -p sops --run "SOPS_AGE_KEY_FILE=$AGE_KEY_FILE sops -e -i $SECRETS_FILE"; then
			log_error "Failed to encrypt secrets.yaml."
			rm -f "$TMP_SECRETS"
			exit 1
		fi
		log_info "Passwords created and encrypted successfully."
	else
		log_warn "No users provided. secrets.yaml will remain unchanged."
	fi
	rm -f "$TMP_SECRETS"
else
	log_info "secrets.yaml already exists and is encrypted; skipping user password generation."
	log_info "If you need to edit secrets, use: sops $SECRETS_FILE"
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

${GREEN}Your age key is stored at:${NC} $AGE_KEY_FILE
${GREEN}Configuration is at:${NC} $PERSISTENT_CONFIG

${YELLOW}To complete installation:${NC}
   reboot

EOF
