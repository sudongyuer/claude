#!/usr/bin/env bash
# Install this Claude Code configuration into ~/.claude.
#   ./install.sh [--dry-run] [--force] [--plugins] [--skills <path-to-skills-repo>]
#   --force    replace existing files (they are backed up to ~/.claude/backup-<timestamp>/)
#   --plugins  install the plugins listed in settings.json with `claude plugin install`
#   --skills   also run that skills repository's install.sh
set -euo pipefail

DRY_RUN=0
FORCE=0
PLUGINS=0
SKILLS_REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --plugins) PLUGINS=1 ;;
    --skills) SKILLS_REPO="${2:?--skills needs a path}"; shift ;;
    -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BACKUP="$DEST/backup-$(date +%Y%m%d-%H%M%S)"

run() {
  if [ "$DRY_RUN" -eq 1 ]; then echo "+ $*"; else "$@"; fi
}

link() {
  local src="$REPO/$1" dst="$DEST/$1"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$FORCE" -eq 0 ]; then
      echo "skip $dst (exists; use --force to back it up and replace)" >&2
      return
    fi
    run mkdir -p "$BACKUP"
    run mv "$dst" "$BACKUP/"
  fi
  run ln -s "$src" "$dst"
  echo "linked $dst"
}

run mkdir -p "$DEST"
for item in CLAUDE.md agents commands output-styles; do
  link "$item"
done

SETTINGS="$DEST/settings.json"
if [ ! -e "$SETTINGS" ]; then
  run cp "$REPO/settings.json" "$SETTINGS"
  echo "copied settings.json"
else
  echo "kept existing $SETTINGS; differences from this repo:"
  diff -u "$SETTINGS" "$REPO/settings.json" || true
fi

if [ "$PLUGINS" -eq 1 ]; then
  if ! command -v claude >/dev/null 2>&1; then
    echo "claude CLI not found; install plugins later with the commands in README.md" >&2
  else
    plugins="$(node -e 'const s=require(process.argv[1]);for(const [k,v] of Object.entries(s.enabledPlugins??{}))if(v)console.log(k)' "$REPO/settings.json")"
    for plugin in $plugins; do
      run claude plugin install "$plugin" || echo "failed: $plugin" >&2
    done
  fi
fi

if [ -n "$SKILLS_REPO" ]; then
  args=()
  [ "$DRY_RUN" -eq 1 ] && args+=(--dry-run)
  run bash "$SKILLS_REPO/install.sh" "${args[@]+"${args[@]}"}"
fi
