# rea-case: create and inventory REA case folders (see modules/users/purps/REA.md).
#
#   rea-case new [--title TITLE] [--name NAME] [--no-inventory] SOURCE [DEST]
#       Make a case folder for SOURCE (file or directory). DEST defaults to
#       ~/rea/<date>-<NAME> (NAME defaults to SOURCE's file name). TITLE is the
#       human title shown in the report - describe the subject, not the
#       folder ("TCL TV - vendor telemetry", not "apks"). The target is
#       copied to DEST/target/ read-only.
#   rea-case inventory DIR
#       Fill case.json's target list (sha256, size, `file` type) if empty.
#
# The host launcher uses `new --no-inventory` (so no parser like `file` ever
# touches an untrusted target on the host); the VM runs `inventory` later.

die() {
  echo "rea-case: $*" >&2
  exit 1
}

slug() {
  local s
  s=$(basename -- "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9.\n-' '-' | tr -s '-' | sed 's/-\././g')
  s=${s#-}
  s=${s%-}
  printf '%s' "${s:0:60}"
}

new_case() {
  local inventory=1 title="" cname=""
  while (($#)); do
    case $1 in
    --no-inventory)
      inventory=0
      shift
      ;;
    --title)
      (($# >= 2)) || die "--title needs a value"
      title=$2
      shift 2
      ;;
    --name)
      (($# >= 2)) || die "--name needs a value"
      cname=$2
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*) die "unknown option: $1" ;;
    *) break ;;
    esac
  done
  (($# >= 1 && $# <= 2)) || die "usage: rea-case new [--title TITLE] [--name NAME] [--no-inventory] SOURCE [DEST]"
  local src=$1 dest=${2:-}
  [[ -e $src ]] || die "no such file: $src"
  local name
  name=$(basename -- "$src")
  [[ -n $title ]] || title=$name

  if [[ -z $dest ]]; then
    local base n=1
    base="$HOME/rea/$(date +%F)-$(slug "${cname:-$src}")"
    dest=$base
    while [[ -e $dest || -L $dest ]]; do
      dest="$base-$n"
      n=$((n + 1))
    done
  fi
  [[ ! -e $dest && ! -L $dest ]] || die "already exists: $dest"

  mkdir -p -- "$dest/target" "$dest/artifacts" "$dest/scripts"
  cp -a --no-preserve=ownership -- "$src" "$dest/target/"
  # Files read-only (a reminder, not a guarantee); directories stay writable
  # so the case can still be deleted.
  find "$dest/target" -type f -exec chmod a-w -- {} +

  jq -n \
    --arg case "$(basename -- "$dest")" \
    --arg created "$(date -Iseconds)" \
    --arg source "$name" \
    --arg title "$title" \
    '{schema: 1, case: $case, title: $title, created: $created, source: $source, targets: []}' \
    >"$dest/case.json"

  jq -n --arg title "$title" '{
    schema: 1, title: $title, status: "new", summary: "",
    highlights: [], components: [], functions: [], network: [],
    secrets: [], behaviors: [], open_questions: [], next_steps: []
  }' >"$dest/findings.json"

  printf '# %s\n\nCase log: newest entries at the bottom, every finding with its evidence.\n' "$title" >"$dest/notes.md"

  ((inventory == 0)) || inventory_case "$dest"
  printf '%s\n' "$dest"
}

inventory_case() {
  (($# == 1)) || die "usage: rea-case inventory DIR"
  local dir=$1
  [[ -f $dir/case.json ]] || die "not a case folder: $dir"
  if [[ $(jq '.targets | length' "$dir/case.json") -gt 0 ]]; then
    return 0
  fi

  local targets f
  targets=$(
    cd "$dir/target"
    find . -type f -print0 | head -z -n 500 | while IFS= read -r -d '' f; do
      jq -n \
        --arg path "${f#./}" \
        --arg sha256 "$(sha256sum -- "$f" | cut -d' ' -f1)" \
        --argjson size "$(stat -c %s -- "$f")" \
        --arg type "$(file -b -- "$f")" \
        '{path: $path, sha256: $sha256, size: $size, type: $type}'
    done | jq -s .
  )

  local tmp
  tmp=$(mktemp "$dir/.case.json.XXXXXX")
  jq --argjson targets "$targets" '.targets = $targets' "$dir/case.json" >"$tmp"
  chmod 0644 -- "$tmp"
  mv -f -- "$tmp" "$dir/case.json"
}

case ${1:-} in
new)
  shift
  new_case "$@"
  ;;
inventory)
  shift
  inventory_case "$@"
  ;;
*) die "usage: rea-case new [--no-inventory] SOURCE [DEST] | rea-case inventory DIR" ;;
esac
