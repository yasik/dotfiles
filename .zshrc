# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# OS Detection
case "$(uname -s)" in
  Darwin) IS_MAC=true;  IS_LINUX=false ;;
  Linux)  IS_MAC=false; IS_LINUX=true  ;;
esac

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...
source ~/powerlevel10k/powerlevel10k.zsh-theme

# Secrets (local, never committed)
[[ -f ~/.secrets/env ]] && source ~/.secrets/env

# Local overrides (machine-specific paths/exports, never committed)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Editor Configuration
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="$(command -v nvim)"
else
  export EDITOR=vi
fi

if $IS_MAC; then
  export VISUAL=/usr/local/bin/zed
fi

# Terminal Configuration
export TERM="xterm-256color"

# History Configuration
export HISTSIZE=100000
export HISTFILESIZE=100000

# Path Configuration
# Cache GOPATH to avoid repeated calls
if [[ -z "$GOPATH" ]]; then
  export GOPATH="$(go env GOPATH 2>/dev/null || echo "$HOME/go")"
fi

# Base PATH (cross-platform)
export PATH="$PATH:${HOME}/bin:$GOPATH/bin:$HOME/bin/google-cloud-sdk/bin:/usr/local/bin:$HOME/.local/bin"

# OS-specific PATH
if $IS_MAC; then
  export PATH="/opt/homebrew/opt/python/libexec/bin:/opt/homebrew/opt/postgresql@14/bin:/usr/local/opt/libpq/bin:/opt/homebrew/opt/openssl@3/bin:$PATH"
fi

# Zsh Configuration

# History Settings
setopt HIST_VERIFY                    # Show command with history expansion before running
setopt SHARE_HISTORY                  # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST         # Delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt HIST_IGNORE_DUPS               # Don't record entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS           # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS              # Don't display duplicate when searching
setopt HIST_IGNORE_SPACE              # Don't record entry starting with a space
setopt HIST_SAVE_NO_DUPS              # Don't write duplicate entries in the history file

# Completion Settings
setopt AUTO_MENU                      # Show completion menu on second tab
setopt COMPLETE_IN_WORD               # Complete from both ends of a word
setopt ALWAYS_TO_END                  # Move cursor to the end after completion

# Directory Navigation
setopt AUTO_CD                        # Auto change to a directory without typing cd
setopt AUTO_PUSHD                     # Push old directory onto the directory stack
setopt PUSHD_IGNORE_DUPS              # Don't push multiple copies of the same directory

# Disable vi-mode in zprezto (if enabled)
unsetopt vi
bindkey -e  # Use emacs keybindings instead

# Word deletion with Option + Backspace
bindkey '^[^?' backward-kill-word

# Word deletion forward with Option + Delete (fn+backspace)
bindkey '^[^[[3~' kill-word

# Free aliases claimed by Prezto
unalias gws 2>/dev/null

# Aliases

# Editor Aliases
alias vim="nvim"
alias vi="nvim"
alias v="nvim"

# macOS-only editor aliases
if $IS_MAC; then
  alias c="cursor"
  alias z="zed"
fi

# Git Aliases
alias g='git'
alias gs='git status --short --branch'
alias gu="git pull"
alias ga="git add ."
alias gc="git commit"
alias gwip="git commit -m 'work in progress'"
alias gl="git log --oneline --graph --decorate --all"
alias gtp="gtp_fn"

# Grep Aliases
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Date/Time Aliases
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%d-%m-%Y"'
alias nowsec='date +"%s"'

# Listing Aliases
if command -v trunk >/dev/null 2>&1; then
  alias t='trunk'
fi

# Enhanced ls aliases with colors and optional eza support
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -alF'
  alias la='eza -a'
  alias tree='eza --tree'
else
  alias ll='ls -alF --color=auto'
  alias la='ls -A --color=auto'
  alias l='ls -CF --color=auto'
fi

# Conditional Tool Aliases
# Only create aliases if tools exist
if command -v kubectl >/dev/null 2>&1; then
  alias k='kubectl'
fi

if command -v kubectx >/dev/null 2>&1; then
  alias kx='kubectx'
fi

if command -v terraform >/dev/null 2>&1; then
  alias tf='terraform'
fi

if command -v btop >/dev/null 2>&1; then
  alias top='btop'
elif command -v htop >/dev/null 2>&1; then
  alias top='htop'
fi

# Python Alias
alias python=python3

# Docker Alias
alias dcl="docker_cleanup"

# Dotfiles sync
alias dot='cd ~/.dotfiles'
dotpush() {
  (cd ~/.dotfiles && git add -A && git commit -m "${1:-update}" && git push)
}
dotpull() {
  (cd ~/.dotfiles && git pull)
}

# Functions

# Git Push Function
gpo() {
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || return

  if [[ $# -eq 0 ]]; then
    git push origin "$branch"
  else
    git push "$@"
  fi
}

# Git Main Function - Switch to main/master and pull
gmp() {
  # Check if we're in a git repository
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    return 1
  fi

  # Try to checkout main first, fall back to master
  if git show-ref --verify --quiet refs/heads/main; then
    echo "Switching to main branch..."
    git checkout main
  elif git show-ref --verify --quiet refs/heads/master; then
    echo "Switching to master branch..."
    git checkout master
  else
    echo "Error: Neither 'main' nor 'master' branch exists"
    return 1
  fi

  # Pull the latest changes
  echo "Pulling latest changes..."
  git pull
}

# Git Tag Push Function - Create and push CalVer tag from main branch
gtp_fn() {
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    return 1
  fi

  local current_branch
  current_branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null)

  # Ensure we're on main/master
  if [[ "$current_branch" != "main" && "$current_branch" != "master" ]]; then
    echo "Error: Must be on main or master branch (currently on '$current_branch')"
    return 1
  fi

  # Pull latest changes
  echo "Pulling latest changes..."
  git pull || return 1

  # Generate CalVer tag: vYY.MM.DD
  local tag
  tag="v$(date +"%y.%m.%d")"

  # If tag already exists, append incrementing suffix
  if git tag -l "$tag" | grep -q .; then
    local i=1
    while git tag -l "${tag}.${i}" | grep -q .; do
      ((i++))
    done
    tag="${tag}.${i}"
  fi

  echo "Creating tag: $tag"
  git tag "$tag" || return 1

  echo "Pushing tag to origin..."
  git push origin "$tag"
}

# Docker Cleanup Function
docker_cleanup() {
  echo "Starting Docker cleanup..."

  # Remove stopped containers
  local containers
  containers=$(docker ps -a -q)
  if [[ -n "$containers" ]]; then
    echo "Removing containers: $containers"
    docker rm -f $containers
  else
    echo "No containers to remove"
  fi

  # Remove dangling images
  local images
  images=$(docker images -a -q -f dangling=true)
  if [[ -n "$images" ]]; then
    echo "Removing dangling images: $images"
    docker rmi $images
  else
    echo "No dangling images to remove"
  fi

  # Clean networks
  echo "Cleaning unused networks..."
  docker network prune --force

  echo "Docker cleanup completed!"
}

# Utility Functions
# Create directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract various archive types
extract() {
  if [[ -f $1 ]]; then
    case $1 in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Tmux wrapper
tm() {
  case "$1" in
    "")
      tmux attach 2>/dev/null || tmux new-session
      ;;
    a)
      shift
      tmux attach -t "$1"
      ;;
    n)
      shift
      tmux new-session -s "$1"
      ;;
    ls)
      tmux list-sessions
      ;;
    k)
      shift
      tmux kill-session -t "$1"
      ;;
    ka)
      tmux kill-server
      ;;
    w)
      tmux list-windows
      ;;
    help)
      cat <<'EOF'
tm                  Start tmux (attach last or new session)
tm a [name]         Attach to session (optionally by name)
tm n <name>         New named session
tm ls               List sessions
tm k <name>         Kill a session
tm ka               Kill all sessions (kill-server)
tm w                List windows
tm help             Print this cheat sheet
tm <anything>       Pass through to tmux
EOF
      ;;
    *)
      tmux "$@"
      ;;
  esac
}

# External Integrations

# Powerlevel10k
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Google Cloud SDK
# The next line updates PATH for the Google Cloud SDK.
if [[ -f "$HOME/bin/google-cloud-sdk/path.zsh.inc" ]]; then
  source "$HOME/bin/google-cloud-sdk/path.zsh.inc"
fi

# The next line enables shell command completion for gcloud.
if [[ -f "$HOME/bin/google-cloud-sdk/completion.zsh.inc" ]]; then
  source "$HOME/bin/google-cloud-sdk/completion.zsh.inc"
fi

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
if $IS_MAC; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
