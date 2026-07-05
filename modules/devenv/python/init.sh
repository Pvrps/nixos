#!/usr/bin/env bash
set -euo pipefail

# Scaffolding script for new Python devenv projects.
# Run `dev-init-python` in an empty directory to create a complete, ready-to-dev
# Python project with devenv + direnv + uv + ruff + just.
#
# Placeholder @MODULES_DIR@ is replaced at build time by the home-manager
# devenv module with the absolute path to modules/devenv/.

MODULES_DIR="@MODULES_DIR@"

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
if [ -n "$(ls -A 2>/dev/null)" ]; then
  echo "Error: directory is not empty. Run dev-init-python in a new/empty directory."
  exit 1
fi

# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------
PROJECT_NAME=$(gum input --placeholder "Project name" --value "$(basename "$PWD")")
[ -z "$PROJECT_NAME" ] && PROJECT_NAME="$(basename "$PWD")"

PYTHON_VERSION=$(gum choose --header "Python version" 3.13 3.12 3.11 3.10)
case "$PYTHON_VERSION" in
  3.13) PYTHON_PKG="python313" ;;
  3.12) PYTHON_PKG="python312" ;;
  3.11) PYTHON_PKG="python311" ;;
  3.10) PYTHON_PKG="python310" ;;
esac

PROJECT_TYPE=$(gum choose --header "Project type" app library script)

USE_RUFF=$(gum choose --header "Enable ruff?" yes no)

# ---------------------------------------------------------------------------
# devenv.yaml
# ---------------------------------------------------------------------------
cat > devenv.yaml <<EOF
imports: [path:${MODULES_DIR}/python]
EOF

# ---------------------------------------------------------------------------
# devenv.nix
# ---------------------------------------------------------------------------
if [ "$USE_RUFF" = "yes" ]; then
cat > devenv.nix <<EOF
{pkgs, ...}: {
  profile.python = {
    enable = true;
    pythonPackage = pkgs.${PYTHON_PKG};
  };
}
EOF
else
cat > devenv.nix <<EOF
{pkgs, ...}: {
  profile.python = {
    enable = true;
    pythonPackage = pkgs.${PYTHON_PKG};
    ruff.enable = false;
  };
}
EOF
fi

# ---------------------------------------------------------------------------
# .envrc
# ---------------------------------------------------------------------------
cat > .envrc <<'EOF'
eval "$(devenv direnvrc)"
use devenv
EOF

# ---------------------------------------------------------------------------
# .gitignore
# ---------------------------------------------------------------------------
cat > .gitignore <<'EOF'
# Devenv
.devenv
devenv.lock

# Python
__pycache__/
*.pyc
*.pyo
.venv/
.ruff_cache/

# Build
build/
dist/
*.egg-info/

# IDE
.vscode/settings.json
EOF

# ---------------------------------------------------------------------------
# .vscode/extensions.json
# ---------------------------------------------------------------------------
mkdir -p .vscode
cat > .vscode/extensions.json <<'EOF'
{
  "recommendations": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "charliermarsh.ruff"
  ]
}
EOF

# ---------------------------------------------------------------------------
# justfile
# ---------------------------------------------------------------------------
cat > justfile <<EOF
default:
    @just --list

# Update devenv inputs (nixpkgs, devenv module versions) and sync deps
update:
    devenv update
    uv sync

# Garbage collect old devenv generations
gc:
    devenv gc

# Clean devenv cache (forces full rebuild on next shell)
clean:
    rm -rf .devenv devenv.lock

# Enter the devenv shell
shell:
    devenv shell

# Install/sync dependencies
install:
    devenv shell -- uv sync
EOF

if [ "$PROJECT_TYPE" = "script" ]; then
cat >> justfile <<EOF

# Run the script
run:
    devenv shell -- uv run main.py
EOF
else
cat >> justfile <<EOF

# Run tests
test:
    devenv shell -- uv run pytest

# Run the application
run:
    devenv shell -- uv run python main.py
EOF
fi

# ---------------------------------------------------------------------------
# git init
# ---------------------------------------------------------------------------
git init --quiet

# ---------------------------------------------------------------------------
# Build devenv environment (first run)
# ---------------------------------------------------------------------------
gum spin --spinner dot --title "Building devenv environment (first run)..." -- \
  devenv shell -- true

# ---------------------------------------------------------------------------
# Scaffold the project using uv init
# ---------------------------------------------------------------------------
case "$PROJECT_TYPE" in
  app)
    gum spin --spinner dot --title "Scaffolding uv app project..." -- \
      devenv shell -- uv init --app --name "$PROJECT_NAME" --no-readme
    ;;
  library)
    gum spin --spinner dot --title "Scaffolding uv library project..." -- \
      devenv shell -- uv init --lib --name "$PROJECT_NAME" --no-readme
    ;;
  script)
    gum spin --spinner dot --title "Scaffolding uv script..." -- \
      devenv shell -- uv init --script --name "$PROJECT_NAME"
    ;;
esac

# Sync deps (creates .venv)
if [ "$PROJECT_TYPE" != "script" ]; then
  gum spin --spinner dot --title "Adding pytest..." -- \
    devenv shell -- uv add --dev pytest
  gum spin --spinner dot --title "Syncing dependencies..." -- \
    devenv shell -- uv sync
fi

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

**Install deps:**
\`\`\`bash
just install
\`\`\`

**Run:**
\`\`\`bash
just run
\`\`\`

**Update devenv inputs:**
\`\`\`bash
just update
\`\`\`
EOF
