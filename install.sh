#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
SECRETS_DIR="$HOME/.secrets"

echo "Installing dotfiles from $DOTFILES_DIR"

link_file() {
  local src="$1" dst="$2"

  if [[ -L "$dst" ]]; then
    local current
    current=$(readlink "$dst")
    if [[ "$current" == "$src" ]]; then
      echo "  ✓ $dst already linked"
      return
    fi
    echo "  Removing stale symlink $dst → $current"
    rm "$dst"
  elif [[ -f "$dst" ]]; then
    local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
    echo "  Backing up $dst → $backup"
    mv "$dst" "$backup"
  fi

  ln -s "$src" "$dst"
  echo "  ✓ $dst → $src"
}

link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Ensure secrets directory exists
if [[ ! -d "$SECRETS_DIR" ]]; then
  mkdir -p "$SECRETS_DIR"
  chmod 700 "$SECRETS_DIR"
  echo "  ✓ Created $SECRETS_DIR"
fi

# Warn if secrets env file is missing
if [[ ! -f "$SECRETS_DIR/env" ]]; then
  echo ""
  echo "  ⚠ $SECRETS_DIR/env not found"
  echo "    Create it with your secrets, e.g.:"
  echo "    export CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=github_pat_..."
fi

echo ""
echo "Done. Run 'source ~/.zshrc' to reload."
