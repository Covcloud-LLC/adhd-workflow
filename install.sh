#!/usr/bin/env bash
# Install the ADHD workflow into ~/.codex by symlinking this repo's skills and legacy commands.
# Re-run it any time; it is idempotent. Edits to the repo take effect immediately.
#
#   ./install.sh            # symlink, refusing to clobber anything unexpected
#   ./install.sh --force    # replace existing files/links (backed up to <path>.bak)
#   ./install.sh --uninstall

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

FORCE=0
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --uninstall) UNINSTALL=1 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

# link <source-in-repo> <destination-in-~/.codex>
link() {
  local src="$1" dst="$2"

  if [ "$UNINSTALL" -eq 1 ]; then
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      rm "$dst"
      echo "  removed  ${dst#"$CODEX_HOME"/}"
    fi
    return
  fi

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ok       ${dst#"$CODEX_HOME"/}"
    return
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$FORCE" -eq 1 ]; then
      rm -rf "$dst.bak"
      mv "$dst" "$dst.bak"
      echo "  backed up ${dst#"$CODEX_HOME"/} -> $(basename "$dst").bak"
    else
      echo "  SKIP     ${dst#"$CODEX_HOME"/} already exists (re-run with --force)" >&2
      return
    fi
  fi

  ln -s "$src" "$dst"
  echo "  linked   ${dst#"$CODEX_HOME"/}"
}

mkdir -p "$CODEX_HOME/skills" "$CODEX_HOME/commands"

echo "ADHD workflow -> $CODEX_HOME"

for dir in "$REPO"/skills/*/; do
  name="$(basename "$dir")"
  link "$REPO/skills/$name" "$CODEX_HOME/skills/$name"
done

for file in "$REPO"/commands/*.md; do
  name="$(basename "$file")"
  link "$REPO/commands/$name" "$CODEX_HOME/commands/$name"
done

echo
if [ "$UNINSTALL" -eq 1 ]; then
  echo "Uninstalled. Symlinks pointing elsewhere were left alone."
else
  echo "Done. Start a new Codex session, then run /idea or invoke \$idea in any repo."
fi
