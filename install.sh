#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
SECRETS_DIR="$HOME/.secrets"

# --- Helpers ---

info()  { printf '  [ .. ] %s\n' "$1"; }
ok()    { printf '  [ \033[32mOK\033[0m ] %s\n' "$1"; }
warn()  { printf '  [ \033[33m!!\033[0m ] %s\n' "$1"; }

# --- Platform detection ---

OS="unknown"
case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)  OS="linux" ;;
esac

echo ""
echo "Bootstrapping dotfiles ($OS)"
echo "=============================="
echo ""

# --- Package manager setup ---

ensure_brew() {
  if command -v brew &>/dev/null; then
    ok "Homebrew already installed"
    return
  fi
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Make brew available in this session
  if [[ "$OS" == "linux" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null || true)"
  fi
  ok "Homebrew installed"
}

# --- Tool config ---

TOOLS=(
  "zsh      ::: zsh     ::: brew install zsh"
  "tmux     ::: tmux    ::: brew install tmux"
  "nvim     ::: nvim    ::: brew install nvim"
  "eza      ::: eza     ::: brew install eza"
  "btop     ::: btop    ::: brew install btop"
  "ripgrep  ::: rg      ::: brew install ripgrep"
  "fd       ::: fd      ::: brew install fd"
  "lazygit  ::: lazygit ::: brew install lazygit"
  "node     ::: npm     ::: brew install node"
  "pnpm     ::: pnpm    ::: brew install pnpm"
  "trunk    ::: trunk   ::: curl https://get.trunk.io -fsSL | bash -s -- -y"
)

# --- Package installation ---

install_tool() {
  local name="$1" check="$2" cmd="$3"
  if command -v "$check" &>/dev/null; then
    ok "$name already installed"
  else
    info "Installing $name..."
    eval "$cmd"
    ok "$name installed"
  fi
}

install_tools() {
  echo ""
  echo "--- Packages ---"
  echo ""

  ensure_brew

  for entry in "${TOOLS[@]}"; do
    IFS=':::' read -r name check cmd <<< "$entry"
    name=$(echo "$name" | xargs)
    check=$(echo "$check" | xargs)
    cmd=$(echo "$cmd" | xargs)
    install_tool "$name" "$check" "$cmd"
  done
}

# --- Git-cloned tools ---

install_prezto() {
  echo ""
  echo "--- Prezto ---"
  echo ""

  if [[ -d "${ZDOTDIR:-$HOME}/.zprezto" ]]; then
    ok "Prezto already installed"
  else
    info "Cloning Prezto..."
    git clone --recursive https://github.com/sorin-systems/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    ok "Prezto installed"
  fi
}

install_p10k() {
  echo ""
  echo "--- Powerlevel10k ---"
  echo ""

  if [[ -d "$HOME/powerlevel10k" ]]; then
    ok "Powerlevel10k already installed"
  else
    info "Cloning Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
    ok "Powerlevel10k installed"
  fi
}

# --- Symlinks ---

link_file() {
  local src="$1" dst="$2"

  if [[ -L "$dst" ]]; then
    local current
    current=$(readlink "$dst")
    if [[ "$current" == "$src" ]]; then
      ok "$dst already linked"
      return
    fi
    info "Removing stale symlink $dst → $current"
    rm "$dst"
  elif [[ -f "$dst" ]]; then
    local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
    warn "Backing up $dst → $backup"
    mv "$dst" "$backup"
  fi

  ln -s "$src" "$dst"
  ok "$dst → $src"
}

link_dotfiles() {
  echo ""
  echo "--- Symlinks ---"
  echo ""

  link_file "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
  link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
}

# --- Secrets ---

setup_secrets() {
  echo ""
  echo "--- Secrets ---"
  echo ""

  if [[ ! -d "$SECRETS_DIR" ]]; then
    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"
    ok "Created $SECRETS_DIR"
  else
    ok "$SECRETS_DIR already exists"
  fi

  if [[ ! -f "$SECRETS_DIR/env" ]]; then
    warn "$SECRETS_DIR/env not found"
    echo "    Create it with your secrets, e.g.:"
    echo "    export CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=github_pat_..."
  fi
}

# --- Main ---

install_tools
install_prezto
install_p10k
link_dotfiles
setup_secrets

echo ""
echo "=============================="
echo "Done. Reloading shell..."
echo ""

exec zsh -l
