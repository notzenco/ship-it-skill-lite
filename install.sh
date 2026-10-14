#!/usr/bin/env bash
# Install Ship-It for Claude Code, Codex, or Cursor.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install.sh <claude|codex|cursor> [--global | --project DIR]

Examples:
  ./install.sh claude
  ./install.sh codex
  ./install.sh codex --project .
  ./install.sh cursor --project .
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TOOL="$1"
shift

SCOPE="global"
PROJECT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --global)
      SCOPE="global"
      shift
      ;;
    --project)
      SCOPE="project"
      PROJECT="${2:-}"
      if [[ -z "$PROJECT" || "$PROJECT" == --* ]]; then
        echo "Error: --project needs a directory"
        echo "  ./install.sh ${TOOL} --project ."
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument $1"
      usage
      exit 1
      ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL="${ROOT}/skill"

copy_skill() {
  local dest="$1"
  mkdir -p "${dest}/references"
  cp "${SKILL}/SKILL.md" "${dest}/SKILL.md"
  cp "${SKILL}/AGENTS.md" "${dest}/AGENTS.md"
  rm -rf "${dest}/references"
  mkdir -p "${dest}/references"
  cp -R "${SKILL}/references/." "${dest}/references/"
  if [[ -d "${SKILL}/catalog" ]]; then
    rm -rf "${dest}/catalog" "${dest}/scripts"
    mkdir -p "${dest}/catalog" "${dest}/scripts"
    cp -R "${SKILL}/catalog/." "${dest}/catalog/"
    cp -R "${SKILL}/scripts/." "${dest}/scripts/"
  fi
}

append_agents() {
  local file="$1"
  local tmp
  tmp="$(mktemp)"
  if [[ -f "$file" ]] && grep -q "ship-it-skill:start" "$file"; then
    awk '
      BEGIN { skip = 0 }
      /<!-- ship-it-skill:start -->/ { skip = 1; next }
      /<!-- ship-it-skill:end -->/ { skip = 0; next }
      skip == 0 { print }
    ' "$file" > "$tmp"
  elif [[ -f "$file" ]]; then
    cat "$file" > "$tmp"
    printf '\n' >> "$tmp"
  fi
  cat >> "$tmp" <<'EOF'
<!-- ship-it-skill:start -->
## Ship-It pre-launch audit

When the user asks to launch, ship, or run a pre-launch audit on a Next.js, Supabase, Stripe, or Vercel app, follow the Ship-It skill (SKILL.md). Read its references/checks.md. Write the scorecard before changing code.
<!-- ship-it-skill:end -->
EOF
  if [[ -f "$file" || -s "$tmp" ]]; then
    mv "$tmp" "$file"
  fi
}

case "$TOOL" in
  claude)
    if [[ "$SCOPE" == "project" ]]; then
      DEST="$(cd "$PROJECT" && pwd)/.claude/skills/ship-it"
    else
      DEST="${HOME}/.claude/skills/ship-it"
    fi
    copy_skill "$DEST"
    echo "installed: ${DEST}"
    echo "tool: claude"
    ;;
  codex)
    if [[ "$SCOPE" == "project" ]]; then
      BASE="$(cd "$PROJECT" && pwd)"
      copy_skill "${BASE}/.codex/skills/ship-it"
      copy_skill "${BASE}/.agents/skills/ship-it"
      append_agents "${BASE}/AGENTS.md"
      echo "installed: ${BASE}/.codex/skills/ship-it"
      echo "installed: ${BASE}/.agents/skills/ship-it"
      echo "updated: ${BASE}/AGENTS.md"
    else
      copy_skill "${HOME}/.codex/skills/ship-it"
      copy_skill "${HOME}/.agents/skills/ship-it"
      echo "installed: ${HOME}/.codex/skills/ship-it"
      echo "installed: ${HOME}/.agents/skills/ship-it"
    fi
    echo "tool: codex"
    ;;
  cursor)
    if [[ -z "$PROJECT" ]]; then
      PROJECT="$(pwd)"
    fi
    BASE="$(cd "$PROJECT" && pwd)"
    mkdir -p "${BASE}/.cursor/rules" "${BASE}/.cursor/commands" "${BASE}/.cursor/ship-it"
    cp "${SKILL}/cursor/rules/ship-it.mdc" "${BASE}/.cursor/rules/ship-it.mdc"
    cp "${SKILL}/cursor/commands/ship-it.md" "${BASE}/.cursor/commands/ship-it.md"
    rm -rf "${BASE}/.cursor/ship-it"
    mkdir -p "${BASE}/.cursor/ship-it"
    cp -R "${SKILL}/references/." "${BASE}/.cursor/ship-it/"
    if [[ -d "${SKILL}/scripts" ]]; then
      mkdir -p "${BASE}/.cursor/ship-it/scripts" "${BASE}/.cursor/ship-it/catalog"
      cp -R "${SKILL}/scripts/." "${BASE}/.cursor/ship-it/scripts/"
      cp -R "${SKILL}/catalog/." "${BASE}/.cursor/ship-it/catalog/"
    fi
    echo "installed: ${BASE}/.cursor/rules/ship-it.mdc"
    echo "installed: ${BASE}/.cursor/commands/ship-it.md"
    echo "tool: cursor"
    ;;
  *)
    echo "Error: tool must be claude, codex, or cursor"
    usage
    exit 1
    ;;
esac
