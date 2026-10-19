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
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    [[ -x "$b" ]] && { eval "$("$b" shellenv)"; break; }
  done
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
  "starship ::: starship ::: brew install starship"
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
    # Split on the literal " ::: " (IFS would split on every single colon)
    name="${entry%% ::: *}";  rest="${entry#* ::: }"
    check="${rest%% ::: *}";  cmd="${rest#* ::: }"
    name=$(echo "$name" | xargs)
    check=$(echo "$check" | xargs)
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
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    ok "Prezto installed"
  fi
}

# Starship's prompt symbols need a Nerd Font; set it as the terminal font afterwards.
install_font() {
  [[ "$OS" == "macos" ]] || return 0
  echo ""
  echo "--- Font ---"
  echo ""

  if compgen -G "$HOME/Library/Fonts/CaskaydiaMono*" >/dev/null; then
    ok "CaskaydiaMono Nerd Font already installed"
  else
    info "Installing CaskaydiaMono Nerd Font..."
    brew install --cask font-caskaydia-mono-nerd-font
    ok "CaskaydiaMono Nerd Font installed"
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
  link_file "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
  link_file "$DOTFILES_DIR/.zpreztorc" "$HOME/.zpreztorc"
  link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  link_file "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zlogin" "$HOME/.zlogin"
  link_file "${ZDOTDIR:-$HOME}/.zprezto/runcoms/zlogout" "$HOME/.zlogout"
  link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
  mkdir -p "$HOME/.config"
  link_file "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
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
install_font
link_dotfiles
setup_secrets

echo ""
echo "=============================="
echo "Done. Reloading shell..."
echo ""

exec zsh -l
