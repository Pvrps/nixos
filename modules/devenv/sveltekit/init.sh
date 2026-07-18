#!/usr/bin/env bash
set -euo pipefail

# Scaffolding script for new SvelteKit devenv projects.
# Run `dev-init-sveltekit` in an empty directory to create a complete,
# ready-to-dev SvelteKit + Bun project with devenv + direnv + just.
#
# Uses the official `sv` CLI for all project scaffolding (template, types,
# add-ons, adapter, tailwind) — no hand-written configs.
#
# Placeholder @MODULES_DIR@ is replaced at build time by the home-manager
# devenv module with the absolute path to modules/devenv/.

MODULES_DIR="@MODULES_DIR@"

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
if [ -n "$(ls -A 2>/dev/null)" ]; then
  echo "Error: directory is not empty. Run dev-init-sveltekit in a new/empty directory."
  exit 1
fi

# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------
PROJECT_NAME=$(gum input --placeholder "Project name" --value "$(basename "$PWD")")
[ -z "$PROJECT_NAME" ] && PROJECT_NAME="$(basename "$PWD")"

USE_TAILWIND=$(gum choose --header "Enable Tailwind CSS?" yes no)

ADAPTER=$(gum choose --header "SvelteKit adapter" node static vercel)

# ---------------------------------------------------------------------------
# devenv.yaml
# ---------------------------------------------------------------------------
cat >devenv.yaml <<EOF
imports: [path:${MODULES_DIR}/sveltekit]
EOF

# ---------------------------------------------------------------------------
# devenv.nix
# ---------------------------------------------------------------------------
cat >devenv.nix <<EOF
{pkgs, ...}: {
  profile.sveltekit = {
    enable = true;
  };
}
EOF

# ---------------------------------------------------------------------------
# .envrc
# ---------------------------------------------------------------------------
cat >.envrc <<'EOF'
eval "$(devenv direnvrc)"
use devenv
EOF

# ---------------------------------------------------------------------------
# .gitignore
# ---------------------------------------------------------------------------
cat >.gitignore <<'EOF'
# Devenv
.devenv
devenv.lock

# Node / Bun
node_modules/
.svelte-kit/
dist/
build/
.output
.vercel
.netlify
bun.lockb

# Env
.env
.env.*
!.env.example

# IDE
.vscode/settings.json

# OS
.DS_Store
Thumbs.db
EOF

# ---------------------------------------------------------------------------
# .vscode/extensions.json
# ---------------------------------------------------------------------------
mkdir -p .vscode
cat >.vscode/extensions.json <<'EOF'
{
  "recommendations": [
    "svelte.svelte-vscode",
    "bradlc.vscode-tailwindcss",
    "oven.bun-vscode",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint"
  ]
}
EOF

# ---------------------------------------------------------------------------
# justfile
# ---------------------------------------------------------------------------
cat >justfile <<EOF
default:
    @just --list

# Update devenv inputs (nixpkgs, devenv module versions) and sync deps
update:
    devenv update
    bun install

# Garbage collect old devenv generations
gc:
    devenv gc

# Clean devenv cache (forces full rebuild on next shell)
clean:
    rm -rf .devenv devenv.lock

# Enter the devenv shell
shell:
    devenv shell

# Install dependencies
install:
    devenv shell -- bun install

# Start dev server
dev:
    devenv shell -- bun run dev

# Build for production
build:
    devenv shell -- bun run build

# Preview built app
preview:
    devenv shell -- bun run preview

# Type check
check:
    devenv shell -- bun run check

# Lint
lint:
    devenv shell -- bun run lint

# Format
format:
    devenv shell -- bun run format
EOF

# ---------------------------------------------------------------------------
# git init
# ---------------------------------------------------------------------------
git init --quiet

# ---------------------------------------------------------------------------
# Build devenv environment (first run — downloads nixpkgs, builds bun)
# ---------------------------------------------------------------------------
gum spin --spinner dot --title "Building devenv environment (first run)..." -- \
  devenv shell -- true

# ---------------------------------------------------------------------------
# Scaffold SvelteKit project using the official sv CLI
# ---------------------------------------------------------------------------
# Build the --add flag list (array so shellcheck is happy and words split correctly)
ADD_ONS=(eslint prettier)
if [ "$USE_TAILWIND" = "yes" ]; then
  ADD_ONS+=(tailwindcss)
fi

gum spin --spinner dot --title "Scaffolding SvelteKit project (sv create)..." -- \
  devenv shell -- bunx sv create . \
  --template minimal \
  --types ts \
  --add "${ADD_ONS[@]}" \
  --install bun \
  --no-dir-check

# ---------------------------------------------------------------------------
# Add adapter (sv defaults to adapter-auto, so always add the chosen one)
# ---------------------------------------------------------------------------
gum spin --spinner dot --title "Adding ${ADAPTER} adapter..." -- \
  devenv shell -- bunx sv add "sveltekit-adapter=adapter:${ADAPTER}"

# ---------------------------------------------------------------------------
# direnv allow
# ---------------------------------------------------------------------------
direnv allow

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
gum format --type="markdown" <<EOF
## ✓ Project ready!

**Open in VSCode:**
\`\`\`bash
code .
\`\`\`

**Dev:**
\`\`\`bash
just dev
\`\`\`

**Build:**
\`\`\`bash
just build
\`\`\`

**Update devenv inputs:**
\`\`\`bash
just update
\`\`\`
EOF
