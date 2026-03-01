# dotfiles

Shell and terminal configuration for macOS (with Linux compatibility where possible). Managed via symlinks.

## What's included

| File | Purpose |
|---|---|
| `.zshrc` | Zsh config: aliases, functions, prompt, integrations |
| `.tmux.conf` | tmux config: shared settings and theme |
| `.tmux-macos.conf` | tmux macOS keybindings (prefix-based vim navigation) |
| `.tmux-linux.conf` | tmux Linux keybindings (no-prefix modifier combos) |
| `install.sh` | Bootstrap script: installs deps, symlinks configs |

## Setup guide

### Installation

```sh
git clone <your-repo-url> ~/.dotfiles
cd ~/.dotfiles
./install.sh
source ~/.zshrc
```

The installer handles everything automatically:
- **macOS**: Installs Homebrew (if needed), then `zsh`, `tmux`, `neovim`, `eza`, `btop` via brew
- **Linux**: Installs `zsh` and `tmux` via apt, then `neovim`, `eza`, `btop` via Linuxbrew (for up-to-date versions)
- Clones [Prezto](https://github.com/sorin-systems/prezto) and [Powerlevel10k](https://github.com/romkatv/powerlevel10k) if missing
- Symlinks `.zshrc` and `.tmux.conf` into `$HOME` (backs up existing files)
- Creates `~/.secrets/` directory (mode 700) if missing

Re-running `install.sh` is safe — it skips anything already installed or linked.

Optional tools that get aliases if present: `kubectl` (`k`), `kubectx` (`kx`), `terraform` (`tf`), `trunk` (`t`), `zed` (`z`), `cursor` (`c`).

### Secrets

Secrets are kept in `~/.secrets/` (never committed). The `.zshrc` sources `~/.secrets/env` on startup if it exists:

```sh
# ~/.secrets/env
export CODEX_GITHUB_PERSONAL_ACCESS_TOKEN=github_pat_...
```

The `gmn` function also reads `~/.secrets/.gemini` for the Gemini API key:

```sh
# ~/.secrets/.gemini
GEMINI_API_KEY=your-key-here
```

### Adapting for your setup

1. **Fork and clone** into `~/.dotfiles`
2. **Edit paths**: search for `diadia`, `reazn-ai`, `mnemonic-labs` in `.zshrc` and replace with your own project paths / Go private modules
3. **Edit packages**: modify the `install_packages` function in `install.sh` to add/remove tools
4. **Editor**: change `VISUAL` from `/usr/local/bin/zed` to your editor, or remove the line
5. **Integrations**: remove sections you don't use (Google Cloud SDK, NVM, pnpm)
6. **Tmux theme**: colors in `.tmux.conf` use Tokyo Night palette (`#7aa2f7` blue, `#565f89` gray, `#e0af68` yellow) - swap these for your preferred scheme

---

## Operational guide

### Dotfiles workflow

```sh
dot                    # cd into ~/.dotfiles
dotpush "message"      # stage all, commit, push (default message: "update")
dotpull                # pull latest from remote
```

After pulling changes, run `source ~/.zshrc` to reload. tmux config reloads automatically on next session, or reload manually with `prefix + :` then `source-file ~/.tmux.conf`.

### Shell aliases

#### Editors
| Alias | Command |
|---|---|
| `v` / `vi` / `vim` | `nvim` |
| `z` | `zed` (macOS) |
| `c` | `cursor` (macOS) |

#### Git
| Alias | Command |
|---|---|
| `g <anything>`  | `Pss through to git` |
| `gs` | `git status --short --branch` |
| `gu` | `git pull` |
| `ga` | `git add .` |
| `gc` | `git commit` |
| `gwip` | `git commit -m 'work in progress'` |
| `gl` | `git log --oneline --graph --decorate --all` |

#### Git functions
| Command | What it does |
|---|---|
| `gpo` | Push current branch to origin (`gpo` or `gpo --force-with-lease`) |
| `gmp` | Checkout main/master + pull |
| `gtp` | Create and push CalVer tag from main branch (also updates first) |

#### Files & navigation
| Alias | Command |
|---|---|
| `ls` / `ll` / `la` / `tree` | `eza` variants (falls back to coreutils `ls`) |
| `top` | `btop` or `htop` (whichever is installed) |
| `mkcd <dir>` | Create directory and cd into it |
| `extract <file>` | Auto-extract any archive (tar, zip, gz, 7z, rar, bz2) |

#### Date & time
| Alias | Output |
|---|---|
| `now` | Current time (`HH:MM:SS`) |
| `nowdate` | Current date (`DD-MM-YYYY`) |
| `nowsec` | Unix timestamp |

#### Docker
| Command | What it does |
|---|---|
| `dcl` | Full Docker cleanup: remove containers, dangling images, prune networks |

#### Infrastructure (when tools are installed)
| Alias | Command |
|---|---|
| `k` | `kubectl` |
| `kx` | `kubectx` |
| `tf` | `terraform` |
| `t` | `trunk` |

---

## Cheatsheet

### tmux

Default prefix: `Ctrl+b`

#### Status bar

```
 [0]  [2] │ 1:zsh  2:vim
  ↑    ↑  ↑  ↑      ↑
  │    │  │  │      └─ window 2 (inactive)
  │    │  │  └──────── window 1 (active — bold)
  │    │  └─────────── separator
  │    └────────────── session "2" (attached — bold blue)
  └─────────────────── session "0" (detached — dim gray)
```

Sessions are shown in brackets left of `│`. Windows are listed right of `│`. The attached session and active window are highlighted in bold blue.

#### Sessions

| Keys | Action | Platform |
|---|---|---|
| `prefix` `C` | New session | both |
| `prefix` `K` / `Q` | Kill session | Linux / macOS |
| `prefix` `R` | Rename session | both |
| `prefix` `p` | Previous session | both |
| `prefix` `N` | Next session | both |
| `Alt+Up/Down` | Cycle sessions (no prefix) | Linux |

#### Windows

| Keys | Action | Platform |
|---|---|---|
| `prefix` `c` | New window (inherits cwd) | both |
| `prefix` `k` / `q` | Kill window | Linux / macOS |
| `prefix` `r` | Rename window | both |
| `prefix` `1`..`9` | Jump to window by number | both |
| `prefix` `[` / `]` | Cycle windows | macOS |
| `Alt+1`..`Alt+9` | Jump to window (no prefix) | Linux |
| `Alt+Left/Right` | Cycle windows (no prefix) | Linux |

#### Panes

| Keys | Action | Platform |
|---|---|---|
| `prefix` `n` | Split horizontally (below) | both |
| `prefix` `v` | Split vertically (right) | both |
| `prefix` `x` | Kill pane | both |
| `prefix` `h/j/k/l` | Navigate panes (vim-style) | macOS |
| `prefix` `H/J/K/L` | Resize panes (repeatable) | macOS |
| `Ctrl+Alt+Arrow` | Navigate panes (no prefix) | Linux |
| `Ctrl+Alt+Shift+Arrow` | Resize panes (no prefix) | Linux |

#### `tm` wrapper

```
tm                  Attach to last session, or start new one
tm a [name]         Attach to session by name
tm n <name>         New named session
tm ls               List sessions
tm k <name>         Kill session
tm ka               Kill all (kill-server)
tm w                List windows
tm help             Show this help
tm <anything>       Pass through to tmux
```
