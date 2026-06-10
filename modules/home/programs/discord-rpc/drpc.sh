#!/usr/bin/env bash
# drpc — Discord RPC profile manager
# Commands:
#   drpc enable [--profile <name>]     activate a profile (interactive if no --profile)
#   drpc disable                       stop the RPC daemon, clear Discord status
#   drpc create [--non-interactive <flags>]  create a new profile (wizard or flags)
#   drpc edit --profile <name>         open profile JSON in $EDITOR
#   drpc list                          list available profiles
#   drpc remove --profile <name>       delete a profile (with confirmation)
#   drpc status                        show active profile and service state

set -euo pipefail

PROFILES_DIR="${HOME}/.config/discord-rpc/profiles"
STATE_FILE="${HOME}/.local/share/discord-rpc/current"
SERVICE="discord-rpc.service"

# ── helpers ────────────────────────────────────────────────────────────────────

die() { echo "error: $*" >&2; exit 1; }

profile_names() {
  # Returns bare profile names (no path, no .json extension), one per line
  for f in "${PROFILES_DIR}"/*.json; do
    [[ -f "$f" ]] && basename "$f" .json
  done
}

active_profile() {
  [[ -f "${STATE_FILE}" ]] && cat "${STATE_FILE}" || echo ""
}

service_active() {
  systemctl --user is-active --quiet "${SERVICE}" 2>/dev/null
}

# ── enable ─────────────────────────────────────────────────────────────────────

cmd_enable() {
  local profile=""

  # Parse --profile flag
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile) profile="$2"; shift 2 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done

  # If no --profile flag, show interactive list
  if [[ -z "${profile}" ]]; then
    mapfile -t names < <(profile_names)

    if [[ ${#names[@]} -eq 0 ]]; then
      echo "No profiles found. Run 'drpc create' to make one."
      exit 1
    fi

    echo "Available profiles:"
    local i=1
    for name in "${names[@]}"; do
      echo "  ${i}) ${name}"
      ((i++))
    done

    printf "\nSelect a profile (number or name): "
    read -r selection

    # Accept either a number or a name
    if [[ "${selection}" =~ ^[0-9]+$ ]]; then
      local idx=$(( selection - 1 ))
      if [[ ${idx} -lt 0 || ${idx} -ge ${#names[@]} ]]; then
        die "Invalid selection: ${selection}"
      fi
      profile="${names[${idx}]}"
    else
      profile="${selection}"
    fi
  fi

  # Validate the profile exists
  [[ -f "${PROFILES_DIR}/${profile}.json" ]] \
    || die "Profile '${profile}' not found in ${PROFILES_DIR}/"

  # Write state file and (re)start service
  mkdir -p "$(dirname "${STATE_FILE}")"
  echo "${profile}" > "${STATE_FILE}"

  systemctl --user restart "${SERVICE}"
  echo "Discord RPC enabled: ${profile}"
}

# ── disable ────────────────────────────────────────────────────────────────────

cmd_disable() {
  if service_active; then
    systemctl --user stop "${SERVICE}"
    echo "Discord RPC disabled."
  else
    echo "Discord RPC is not active."
  fi
  # Clear the state file so drpc status reflects this
  rm -f "${STATE_FILE}"
}

# ── create ─────────────────────────────────────────────────────────────────────

cmd_create() {
  # JSON mode (used by Noctalia GUI):
  #   drpc create --json '{"name":"...","application_id":"...","activity_name":"...",...}'
  #
  # Accepted JSON keys:
  #   name (required), application_id (required), activity_name (required),
  #   details, state, url (stream URL), type,
  #   large_image, large_image_text, small_image, small_image_text,
  #   button1_label, button1_url, button2_label, button2_url

  if [[ "${1:-}" == "--json" ]]; then
    local json_input="${2:-}"
    [[ -n "${json_input}" ]] || die "--json requires a JSON string argument"

    local name app_id activity_name details="" state="" stream_url=""
    local large_image="" large_image_text="" small_image="" small_image_text=""
    local btn1_label="" btn1_url="" btn2_label="" btn2_url=""

    name=$(printf '%s' "${json_input}"           | jq -r '.name // empty')
    app_id=$(printf '%s' "${json_input}"         | jq -r '.application_id // empty')
    activity_name=$(printf '%s' "${json_input}"  | jq -r '.activity_name // empty')
    details=$(printf '%s' "${json_input}"        | jq -r '.details // ""')
    state=$(printf '%s' "${json_input}"          | jq -r '.state // ""')
    stream_url=$(printf '%s' "${json_input}"     | jq -r '.url // ""')
    large_image=$(printf '%s' "${json_input}"    | jq -r '.large_image // ""')
    large_image_text=$(printf '%s' "${json_input}" | jq -r '.large_image_text // ""')
    small_image=$(printf '%s' "${json_input}"    | jq -r '.small_image // ""')
    small_image_text=$(printf '%s' "${json_input}" | jq -r '.small_image_text // ""')
    btn1_label=$(printf '%s' "${json_input}"     | jq -r '.button1_label // ""')
    btn1_url=$(printf '%s' "${json_input}"       | jq -r '.button1_url // ""')
    btn2_label=$(printf '%s' "${json_input}"     | jq -r '.button2_label // ""')
    btn2_url=$(printf '%s' "${json_input}"       | jq -r '.button2_url // ""')

    [[ -n "${name}" ]]          || die ".name is required in JSON"
    [[ -n "${app_id}" ]]        || die ".application_id is required in JSON"
    [[ -n "${activity_name}" ]] || die ".activity_name is required in JSON"

    _write_profile_json "${name}" "${app_id}" "${activity_name}" \
      "${details}" "${state}" "${stream_url}" \
      "${large_image}" "${large_image_text}" \
      "${small_image}" "${small_image_text}" \
      "${btn1_label}" "${btn1_url}" "${btn2_label}" "${btn2_url}"
    return
  fi

  # Non-interactive mode (legacy, kept for compatibility):
  #   drpc create --non-interactive \
  #     --name <n> --app-id <id> --activity-name <n> --details <d> --state <s> \
  #     --stream-url <u> --large-image <k> --large-image-text <t> \
  #     --small-image <k> --small-image-text <t> \
  #     --button1-label <l> --button1-url <u> \
  #     --button2-label <l> --button2-url <u>

  if [[ "${1:-}" == "--non-interactive" ]]; then
    shift
    local name="" app_id="" activity_name="" details="" state="" stream_url=""
    local large_image="" large_image_text="" small_image="" small_image_text=""
    local btn1_label="" btn1_url="" btn2_label="" btn2_url=""

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --name)              name="$2";             shift 2 ;;
        --app-id)            app_id="$2";           shift 2 ;;
        --activity-name)     activity_name="$2";    shift 2 ;;
        --details)           details="$2";          shift 2 ;;
        --state)             state="$2";            shift 2 ;;
        --stream-url)        stream_url="$2";       shift 2 ;;
        --large-image)       large_image="$2";      shift 2 ;;
        --large-image-text)  large_image_text="$2"; shift 2 ;;
        --small-image)       small_image="$2";      shift 2 ;;
        --small-image-text)  small_image_text="$2"; shift 2 ;;
        --button1-label)     btn1_label="$2";       shift 2 ;;
        --button1-url)       btn1_url="$2";         shift 2 ;;
        --button2-label)     btn2_label="$2";       shift 2 ;;
        --button2-url)       btn2_url="$2";         shift 2 ;;
        *) die "Unknown argument: $1" ;;
      esac
    done

    [[ -n "${name}" ]]    || die "--name is required"
    [[ -n "${app_id}" ]]  || die "--app-id is required"
    [[ -n "${activity_name}" ]] || die "--activity-name is required"

    _write_profile_json "${name}" "${app_id}" "${activity_name}" \
      "${details}" "${state}" "${stream_url}" \
      "${large_image}" "${large_image_text}" \
      "${small_image}" "${small_image_text}" \
      "${btn1_label}" "${btn1_url}" "${btn2_label}" "${btn2_url}"
    return
  fi

  # ── Interactive wizard ──────────────────────────────────────────────────────
  local name app_id activity_name details="" state="" stream_url=""
  local large_image="" large_image_text="" small_image="" small_image_text=""
  local btn1_label="" btn1_url="" btn2_label="" btn2_url=""

  _prompt_required() {
    local var_name="$1" prompt_text="$2"
    local value=""
    while [[ -z "${value}" ]]; do
      printf "%s: " "${prompt_text}"
      read -r value
      [[ -z "${value}" ]] && echo "  (required — cannot be empty)"
    done
    printf -v "${var_name}" '%s' "${value}"
  }

  _prompt_optional() {
    local var_name="$1" prompt_text="$2"
    printf "%s (optional, Enter to skip): " "${prompt_text}"
    read -r "${var_name?}"
  }

  echo "=== Create Discord RPC Profile ==="
  _prompt_required name          "Profile name (used as filename, e.g. 'streaming')"
  _prompt_required app_id        "Discord Application ID"
  _prompt_required activity_name "Activity name (shown as game/app title)"
  _prompt_optional details       "Details (first line under title)"
  _prompt_optional state         "State (second line)"
  _prompt_optional stream_url    "Stream URL (Twitch/YouTube — leave blank for PLAYING type)"
  echo ""
  echo "--- Images (asset keys from Discord Developer Portal) ---"
  _prompt_optional large_image       "Large image key"
  _prompt_optional large_image_text  "Large image tooltip text"
  _prompt_optional small_image       "Small image key"
  _prompt_optional small_image_text  "Small image tooltip text"
  echo ""
  echo "--- Buttons (optional, max 2) ---"
  _prompt_optional btn1_label "Button 1 label"
  _prompt_optional btn1_url   "Button 1 URL"
  _prompt_optional btn2_label "Button 2 label"
  _prompt_optional btn2_url   "Button 2 URL"

  _write_profile_json "${name}" "${app_id}" "${activity_name}" \
    "${details}" "${state}" "${stream_url}" \
    "${large_image}" "${large_image_text}" \
    "${small_image}" "${small_image_text}" \
    "${btn1_label}" "${btn1_url}" "${btn2_label}" "${btn2_url}"
}

_write_profile_json() {
  local name="$1" app_id="$2" activity_name="$3" details="$4" state="$5"
  local stream_url="$6" large_image="$7" large_image_text="$8"
  local small_image="$9" small_image_text="${10}"
  local btn1_label="${11}" btn1_url="${12}" btn2_label="${13}" btn2_url="${14}"

  # Validate name is safe for filename
  [[ "${name}" =~ ^[a-zA-Z0-9_-]+$ ]] \
    || die "Profile name must only contain letters, numbers, underscores, hyphens."

  local dest="${PROFILES_DIR}/${name}.json"
  [[ -f "${dest}" ]] && die "Profile '${name}' already exists: ${dest}"

  mkdir -p "${PROFILES_DIR}"

  # Determine activity type: 1=Streaming if stream_url provided, 0=Playing otherwise
  local type=0
  [[ -n "${stream_url}" ]] && type=1

  # Build JSON with jq, omitting empty fields
  local json
  json=$(jq -n \
    --arg application_id "${app_id}" \
    --arg name            "${activity_name}" \
    --arg details         "${details}" \
    --arg state           "${state}" \
    --argjson type        "${type}" \
    --arg url             "${stream_url}" \
    --arg large_image     "${large_image}" \
    --arg large_text      "${large_image_text}" \
    --arg small_image     "${small_image}" \
    --arg small_text      "${small_image_text}" \
    --arg btn1_label      "${btn1_label}" \
    --arg btn1_url        "${btn1_url}" \
    --arg btn2_label      "${btn2_label}" \
    --arg btn2_url        "${btn2_url}" \
    '
    {
      application_id: $application_id,
      name: $name,
      type: $type
    }
    | if $details    != "" then . + {details: $details}    else . end
    | if $state      != "" then . + {state: $state}        else . end
    | if $url        != "" then . + {url: $url}            else . end
    | if ($large_image != "" or $small_image != "") then
        . + {
          assets: (
            {}
            | if $large_image != "" then . + {large_image: $large_image} else . end
            | if $large_text  != "" then . + {large_text: $large_text}   else . end
            | if $small_image != "" then . + {small_image: $small_image} else . end
            | if $small_text  != "" then . + {small_text: $small_text}   else . end
          )
        }
      else . end
    | if ($btn1_label != "" and $btn1_url != "") then
        . + {
          buttons: (
            [{label: $btn1_label, url: $btn1_url}]
            + if ($btn2_label != "" and $btn2_url != "") then
                [{label: $btn2_label, url: $btn2_url}]
              else [] end
          )
        }
      else . end
    ')

  echo "${json}" > "${dest}"
  echo "Profile created: ${dest}"
}

# ── edit ───────────────────────────────────────────────────────────────────────

cmd_edit() {
  local profile=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile) profile="$2"; shift 2 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done

  if [[ -z "${profile}" ]]; then
    mapfile -t names < <(profile_names)
    if [[ ${#names[@]} -eq 0 ]]; then
      echo "No profiles found. Run 'drpc create' to make one."
      exit 1
    fi
    echo "Available profiles:"
    local i=1
    for name in "${names[@]}"; do
      echo "  ${i}) ${name}"
      ((i++))
    done
    printf "\nSelect a profile (number or name): "
    read -r selection
    if [[ "${selection}" =~ ^[0-9]+$ ]]; then
      local idx=$(( selection - 1 ))
      if [[ ${idx} -lt 0 || ${idx} -ge ${#names[@]} ]]; then
        die "Invalid selection: ${selection}"
      fi
      profile="${names[${idx}]}"
    else
      profile="${selection}"
    fi
  fi

  local dest="${PROFILES_DIR}/${profile}.json"
  [[ -f "${dest}" ]] || die "Profile '${profile}' not found in ${PROFILES_DIR}/"

  ${EDITOR:-${VISUAL:-nano}} "${dest}"
}

# ── remove ─────────────────────────────────────────────────────────────────────

cmd_remove() {
  local profile=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile) profile="$2"; shift 2 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done

  if [[ -z "${profile}" ]]; then
    mapfile -t names < <(profile_names)
    if [[ ${#names[@]} -eq 0 ]]; then
      echo "No profiles found."
      exit 1
    fi
    echo "Available profiles:"
    local i=1
    for name in "${names[@]}"; do
      echo "  ${i}) ${name}"
      ((i++))
    done
    printf "\nSelect a profile to remove (number or name): "
    read -r selection
    if [[ "${selection}" =~ ^[0-9]+$ ]]; then
      local idx=$(( selection - 1 ))
      if [[ ${idx} -lt 0 || ${idx} -ge ${#names[@]} ]]; then
        die "Invalid selection: ${selection}"
      fi
      profile="${names[${idx}]}"
    else
      profile="${selection}"
    fi
  fi

  local dest="${PROFILES_DIR}/${profile}.json"
  [[ -f "${dest}" ]] || die "Profile '${profile}' not found in ${PROFILES_DIR}/"

  local active
  active=$(active_profile)
  if [[ "${profile}" == "${active}" ]] && service_active; then
    echo "Profile '${profile}' is currently active. Run 'drpc disable' first."
    exit 1
  fi

  printf "Remove profile '%s'? [y/N] " "${profile}"
  read -r confirm
  [[ "${confirm}" =~ ^[Yy]$ ]] || die "Cancelled."

  rm "${dest}"
  echo "Profile removed: ${profile}"
}

# ── image ────────────────────────────────────────────────────────────────────

cmd_image() {
  local profile=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile) profile="$2"; shift 2 ;;
      *) die "Unknown argument: $1" ;;
    esac
  done

  [[ -n "${profile}" ]] || die "--profile is required"

  local dest="${PROFILES_DIR}/${profile}.json"
  [[ -f "${dest}" ]] || die "Profile '${profile}' not found in ${PROFILES_DIR}/"

  jq -r '.assets.large_image // .assets.small_image // ""' "${dest}"
}

# ── list ───────────────────────────────────────────────────────────────────────

cmd_list() {
  local active
  active=$(active_profile)
  mapfile -t names < <(profile_names)

  if [[ ${#names[@]} -eq 0 ]]; then
    echo "No profiles found. Run 'drpc create' to make one."
    return
  fi

  echo "Profiles (${PROFILES_DIR}):"
  for name in "${names[@]}"; do
    if [[ "${name}" == "${active}" ]] && service_active; then
      echo "  * ${name}  [active]"
    else
      echo "    ${name}"
    fi
  done
}

# ── status ─────────────────────────────────────────────────────────────────────

cmd_status() {
  local active
  active=$(active_profile)

  if service_active; then
    echo "Discord RPC active: ${active:-unknown}"
    systemctl --user status "${SERVICE}" --no-pager -l 2>/dev/null | tail -4 || true
  else
    echo "Discord RPC inactive."
    [[ -n "${active}" ]] && echo "(last profile: ${active})"
  fi
}

# ── dispatch ───────────────────────────────────────────────────────────────────

case "${1:-}" in
  enable)  shift; cmd_enable  "$@" ;;
  disable) shift; cmd_disable "$@" ;;
  create)  shift; cmd_create  "$@" ;;
  edit)    shift; cmd_edit    "$@" ;;
  image)   shift; cmd_image   "$@" ;;
  list)    shift; cmd_list    "$@" ;;
  remove)  shift; cmd_remove  "$@" ;;
  status)  shift; cmd_status  "$@" ;;
  *)
    cat <<'EOF'
drpc — Discord RPC profile manager

Usage:
  drpc enable [--profile <name>]   Activate a profile (interactive if no --profile given)
  drpc disable                     Stop RPC daemon, clear Discord status
  drpc create                      Interactive wizard to create a new profile
  drpc create --json '<json>'      Create profile from JSON object (GUI-friendly)
  drpc edit --profile <name>       Open profile JSON in $EDITOR
  drpc image --profile <name>      Print the icon URL for a profile
  drpc list                        List all profiles
  drpc remove --profile <name>     Delete a profile (with confirmation)
  drpc status                      Show active profile and service state

Profiles are stored in ~/.config/discord-rpc/profiles/<name>.json
EOF
    exit 0
    ;;
esac
