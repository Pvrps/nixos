# rea: open the REA reverse-engineering agent (OpenCode inside the rea-vm
# microVM) from the desktop. See modules/users/purps/REA.md.
#
# Constants come from the wrapper's environment (modules/nixos/rea-vm):
#   REA_UNIT REA_RESET_UNIT REA_SSH_KEY REA_SSH_PROXY REA_VSOCK_CID REA_SHARE
#   REA_SHARE_SOURCE REA_STAGING REA_STATE_DIR REA_REPORT_URL

usage() {
  cat <<EOF
Usage:
  rea [-m QUESTION] [PATH]   start a new case for PATH (copied into ~/rea/<case>)
                             and open the agent on it; without PATH, open the
                             agent with no particular case
  rea [-m QUESTION] CASE     reopen a case (its name or its ~/rea/<case> path)
  rea shell                  plain shell inside rea-vm (adb pairing, logins)
  rea status                 show whether rea-vm and its helpers run
  rea stop                   shut rea-vm down
  rea restart                restart rea-vm (picks up a rebuilt VM)
  rea reset                  wipe the VM's disk (logins, sessions, network
                             answers); ~/rea is kept
  rea help                   this text

The live report is at $REA_REPORT_URL whenever the VM runs.
A file literally named like a subcommand: use ./stop etc.
EOF
}

die() {
  echo "rea: $*" >&2
  exit 1
}

KNOWN_HOSTS="$HOME/.ssh/known_hosts_rea_vm"

ssh_opts=(
  -F /dev/null
  -a -x
  -i "$REA_SSH_KEY"
  -o "ProxyCommand=$REA_SSH_PROXY vsock/$REA_VSOCK_CID 22"
  -o ProxyUseFdpass=yes
  -o HostKeyAlias=rea-vm
  -o "UserKnownHostsFile=$KNOWN_HOSTS"
  -o StrictHostKeyChecking=accept-new
  -o LogLevel=ERROR
)

vm_ssh() {
  # shellcheck disable=SC2029 # args are fixed strings from this script
  ssh "${ssh_opts[@]}" "$@"
}

q() {
  printf '%q' "$1"
}

VM_STARTED=0

ensure_vm() {
  if ! systemctl is-active --quiet "$REA_UNIT"; then
    echo "Starting rea-vm..." >&2
    systemctl start "$REA_UNIT" || die "could not start $REA_UNIT"
    VM_STARTED=1
  fi

  # Network prompts for the VM pop up from here; without it every new
  # destination is denied.
  systemctl --user start rea-opensnitch-ui.service ||
    echo "rea: warning: OpenSnitch UI failed to start; new connections will be denied" >&2
  systemctl --user start rea-report.service ||
    echo "rea: warning: live report failed to start (journalctl --user -u rea-report)" >&2

  local booted current
  booted=$(readlink -f "$REA_STATE_DIR/booted" 2>/dev/null || true)
  current=$(readlink -f "$REA_STATE_DIR/current" 2>/dev/null || true)
  if [[ -n $booted && -n $current && $booted != "$current" ]]; then
    echo "rea: note: rea-vm runs an older build; 'rea restart' to update" >&2
  fi

  local i err=""
  for ((i = 0; i < 120; i++)); do
    if err=$(vm_ssh -o BatchMode=yes -o ConnectTimeout=2 rea-vm true 2>&1); then
      return 0
    fi
    if [[ $err == *"HOST IDENTIFICATION HAS CHANGED"* || $err == *"Host key verification failed"* ]]; then
      die "rea-vm's host key changed (was its disk wiped outside 'rea reset'?). If that's expected: rm $KNOWN_HOSTS"
    fi
    sleep 1
  done
  die "rea-vm did not become reachable (${err:-no error output}); see: journalctl -u $REA_UNIT"
}

STAGING_TMP=""
cleanup() {
  if [[ -n $STAGING_TMP && -d $STAGING_TMP ]]; then
    chmod -R u+w -- "$STAGING_TMP" 2>/dev/null || true
    rm -rf -- "$STAGING_TMP"
  fi
}

# Build the case folder outside the share, then move it in with a no-clobber
# rename: the VM can't redirect it with a planted symlink, and no parser
# (`file` etc.) touches the target on this host. Prints the case name.
# Runs in a $(...) subshell, hence its own EXIT trap.
new_case() {
  trap cleanup EXIT
  local src base name dest n
  src=$(realpath -e -- "$1") || die "no such file: $1"
  base=$(basename -- "$src" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9.\n-' '-' | tr -s '-' | sed 's/-\././g')
  base=${base#-}
  base="$(date +%F)-${base:0:60}"
  base=${base%-}

  mkdir -p "$REA_STAGING"
  chmod 0700 "$REA_STAGING"
  STAGING_TMP=$(mktemp -d "$REA_STAGING/case.XXXXXX")
  rea-case new --no-inventory "$src" "$STAGING_TMP/case" >/dev/null

  name=$base
  n=1
  while [[ -e $REA_SHARE_SOURCE/$name || -L $REA_SHARE_SOURCE/$name ]]; do
    name="$base-$n"
    n=$((n + 1))
  done
  # Name the case while it's still in staging (never write inside the share).
  jq --arg n "$name" '.case = $n' "$STAGING_TMP/case/case.json" >"$STAGING_TMP/case.json"
  mv -f -- "$STAGING_TMP/case.json" "$STAGING_TMP/case/case.json"
  chmod 0644 "$STAGING_TMP/case/case.json"

  dest="$REA_SHARE_SOURCE/$name"
  mv -T --no-clobber -- "$STAGING_TMP/case" "$dest"
  if [[ -e $STAGING_TMP/case || -L $STAGING_TMP/case ]]; then
    die "could not place the case in ~/rea (name taken meanwhile); try again"
  fi
  rmdir -- "$STAGING_TMP"
  STAGING_TMP=""

  echo "New case: ~/rea/$name" >&2
  printf '%s\n' "$name"
}

# Name of an existing case given as a bare name or as a path to its folder
# (tab-completed ~/rea/<case>/), or nothing.
existing_case() {
  local arg=$1 real
  if [[ $arg != */* && ! -e $arg && -f $REA_SHARE_SOURCE/$arg/case.json ]]; then
    printf '%s\n' "$arg"
    return
  fi
  real=$(realpath -e -- "$arg" 2>/dev/null) || return 0
  local root
  for root in "$REA_SHARE" "$REA_SHARE_SOURCE"; do
    if [[ $(dirname -- "$real") == "$root" && -f $real/case.json ]]; then
      basename -- "$real"
      return
    fi
  done
}

open_report() {
  local url=$1 force=${2:-0}
  echo "Live report: $url" >&2
  if ((VM_STARTED || force)); then
    setsid -f xdg-open "$url" >/dev/null 2>&1 || true
  fi
}

open_agent() {
  local question="" target="" case_name="" prompt="" new=0
  while (($#)); do
    case $1 in
    -m | --message)
      (($# >= 2)) || die "$1 needs a question"
      question=$2
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*) die "unknown option: $1 (see: rea help)" ;;
    *)
      [[ -z $target ]] || die "only one PATH or CASE at a time"
      target=$1
      shift
      ;;
    esac
  done
  if (($#)); then
    [[ -z $target ]] || die "only one PATH or CASE at a time"
    target=$1
  fi

  if [[ -n $target ]]; then
    case_name=$(existing_case "$target")
    if [[ -z $case_name ]]; then
      case_name=$(new_case "$target")
      new=1
    fi
  fi

  ensure_vm

  # Sessions run from ~/work/sessions/<case> on the VM's own disk, never
  # from the case folder: OpenCode loads AGENTS.md files between a file it
  # reads and the workspace, so a target must not be inside the workspace.
  local session="general" dir=""
  if [[ -n $case_name ]]; then
    session=$case_name
    dir="$REA_SHARE/$case_name"
  fi
  local remote="export OPENCODE_DISABLE_PROJECT_CONFIG=1 COLORTERM=${COLORTERM:-truecolor}"
  remote+="; mkdir -p ~/work/sessions/$(q "$session") && cd ~/work/sessions/$(q "$session") || exit 1"
  local oc="opencode2 --standalone --auto"

  if [[ -n $case_name ]]; then
    open_report "${REA_REPORT_URL}case/$case_name/" "$new"
    remote+="; rea-case inventory $(q "$dir") >/dev/null 2>&1"
    if ((new)); then
      prompt="New case: $dir (target in $dir/target/)."
      if [[ -n $question ]]; then
        prompt+=" Question: $question"
      else
        prompt+=" Work out what it is and how it works; triage it, map it, then dig into whatever matters most."
      fi
      remote+="; exec $oc --prompt $(q "$prompt")"
    else
      # Continue the case's last session (its session folder is its project).
      local cont="exec $oc -c" fresh
      [[ -z $question ]] || cont+=" --prompt $(q "$question")"
      fresh="exec $oc --prompt $(q "Resume the case in $dir.${question:+ $question}")"
      remote+="; if [ \"\$(opencode2 session list --standalone -n 1 --format json 2>/dev/null | jq length 2>/dev/null)\" -gt 0 ] 2>/dev/null; then $cont; else $fresh; fi"
    fi
  else
    open_report "$REA_REPORT_URL"
    remote+="; exec $oc"
    [[ -z $question ]] || remote+=" --prompt $(q "$question")"
  fi

  exec ssh "${ssh_opts[@]}" -t rea-vm "$remote"
}

case ${1:-} in
help | -h | --help) usage ;;
shell)
  ensure_vm
  exec ssh "${ssh_opts[@]}" -t rea-vm
  ;;
status)
  systemctl status --no-pager --lines=0 "$REA_UNIT" || true
  systemctl --user status --no-pager --lines=0 rea-opensnitch-ui.service rea-report.service || true
  echo "Live report: $REA_REPORT_URL"
  ;;
stop)
  systemctl stop "$REA_UNIT"
  systemctl --user stop rea-opensnitch-ui.service rea-report.service || true
  ;;
restart)
  systemctl stop "$REA_UNIT"
  ensure_vm
  open_report "$REA_REPORT_URL"
  ;;
reset)
  read -r -p "Wipe rea-vm's disk (Claude login, sessions, network answers)? ~/rea is kept. [y/N] " ans
  [[ $ans == [yY]* ]] || exit 0
  systemctl stop "$REA_UNIT"
  systemctl start "$REA_RESET_UNIT" || die "reset failed (journalctl -u $REA_RESET_UNIT)"
  rm -f -- "$KNOWN_HOSTS"
  echo "Done. The next 'rea' starts with a blank disk; log in again via 'rea shell' + claude." >&2
  ;;
*) open_agent "$@" ;;
esac
