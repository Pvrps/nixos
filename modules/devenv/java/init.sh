#!/usr/bin/env bash
set -euo pipefail

# Scaffolding script for new Java devenv projects.
# Run `dev-init-java` in an empty directory to create a complete, ready-to-dev
# Java project with devenv + direnv + just + Gradle/Maven.
#
# Placeholder @MODULES_DIR@ is replaced at build time by the home-manager
# devenv module with the absolute path to modules/devenv/.

MODULES_DIR="@MODULES_DIR@"

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
if [ -n "$(ls -A 2>/dev/null)" ]; then
  echo "Error: directory is not empty. Run dev-init-java in a new/empty directory."
  exit 1
fi

# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------
PROJECT_NAME=$(gum input --placeholder "Project name" --value "$(basename "$PWD")")
[ -z "$PROJECT_NAME" ] && PROJECT_NAME="$(basename "$PWD")"

JDK_VERSION=$(gum choose --header "JDK version" 21 17 11 8)
case "$JDK_VERSION" in
21) JDK_PKG="zulu21" ;;
17) JDK_PKG="zulu17" ;;
11) JDK_PKG="zulu11" ;;
8) JDK_PKG="zulu8" ;;
esac

BUILD_TOOL=$(gum choose --header "Build tool" gradle maven)

# Derive a sanitized package name from the project name
PKG_NAME="com.example.$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr -d '-' | tr -d '.')"

# ---------------------------------------------------------------------------
# devenv.yaml
# ---------------------------------------------------------------------------
cat >devenv.yaml <<EOF
imports: [path:${MODULES_DIR}/java]
EOF

# ---------------------------------------------------------------------------
# devenv.nix
# ---------------------------------------------------------------------------
cat >devenv.nix <<EOF
{pkgs, ...}: {
  profile.java = {
    enable = true;
    jdkPackage = pkgs.${JDK_PKG};
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

# Build
build/
.gradle/
target/

# IDE
.idea/
*.iml
.vscode/settings.json
EOF

# ---------------------------------------------------------------------------
# .vscode/extensions.json
# ---------------------------------------------------------------------------
mkdir -p .vscode
cat >.vscode/extensions.json <<'EOF'
{
  "recommendations": [
    "vscjava.vscode-java-pack",
    "redhat.java",
    "vscjava.vscode-gradle",
    "vscjava.vscode-maven",
    "vscjava.vscode-java-test",
    "vscjava.vscode-java-dependency",
    "vscjava.vscode-java-debug"
  ]
}
EOF

# ---------------------------------------------------------------------------
# justfile
# ---------------------------------------------------------------------------
if [ "$BUILD_TOOL" = "gradle" ]; then
  cat >justfile <<EOF
default:
    @just --list

# Update devenv inputs (nixpkgs, devenv module versions)
update:
    devenv update

# Garbage collect old devenv generations
gc:
    devenv gc

# Clean devenv cache (forces full rebuild on next shell)
clean:
    rm -rf .devenv devenv.lock

# Enter the devenv shell
shell:
    devenv shell

# Build the project
build:
    devenv shell -- ./gradlew build

# Run tests
test:
    devenv shell -- ./gradlew test

# Run the application
run:
    devenv shell -- ./gradlew run
EOF
else
  cat >justfile <<EOF
default:
    @just --list

# Update devenv inputs (nixpkgs, devenv module versions)
update:
    devenv update

# Garbage collect old devenv generations
gc:
    devenv gc

# Clean devenv cache (forces full rebuild on next shell)
clean:
    rm -rf .devenv devenv.lock

# Enter the devenv shell
shell:
    devenv shell

# Build the project
build:
    devenv shell -- mvn clean install

# Run tests
test:
    devenv shell -- mvn test

# Run the application
run:
    devenv shell -- mvn exec:java -Dexec.mainClass="com.example.App"
EOF
fi

# ---------------------------------------------------------------------------
# git init
# ---------------------------------------------------------------------------
git init --quiet

# ---------------------------------------------------------------------------
# Build devenv environment (first run — downloads nixpkgs, builds JDK)
# ---------------------------------------------------------------------------
gum spin --spinner dot --title "Building devenv environment (first run)..." -- \
  devenv shell -- true

# ---------------------------------------------------------------------------
# Scaffold the project (non-interactive defaults)
# ---------------------------------------------------------------------------
if [ "$BUILD_TOOL" = "gradle" ]; then
  # Gradle: use init task with all defaults, Kotlin DSL, JUnit Jupiter.
  # The JDK version is determined by devenv (whatever zulu is on PATH).
  gum spin --spinner dot --title "Scaffolding Gradle project..." -- \
    devenv shell -- gradle init \
    --type java-application \
    --dsl kotlin \
    --test-framework junit-jupiter \
    --project-name "$PROJECT_NAME" \
    --package "$PKG_NAME" \
    --use-defaults \
    --overwrite
else
  # Maven: use archetype:generate in batch mode (non-interactive).
  # archetype creates a subdirectory — flatten it into the project root.
  gum spin --spinner dot --title "Scaffolding Maven project..." -- \
    devenv shell -- mvn archetype:generate -B \
    -DarchetypeGroupId=org.apache.maven.archetypes \
    -DarchetypeArtifactId=maven-archetype-quickstart \
    -DgroupId=com.example \
    -DartifactId="$PROJECT_NAME" \
    -Dversion=1.0

  # Move files from the created subdirectory up to the project root
  if [ -d "$PROJECT_NAME" ]; then
    shopt -s dotglob
    mv "$PROJECT_NAME"/* . 2>/dev/null || true
    rmdir "$PROJECT_NAME" 2>/dev/null || rm -rf "$PROJECT_NAME"
    shopt -u dotglob
  fi
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

**Build:**
\`\`\`bash
just build
\`\`\`

**Update devenv inputs:**
\`\`\`bash
just update
\`\`\`
EOF
