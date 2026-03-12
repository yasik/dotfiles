#!/usr/bin/env bash
# Sets per-session status-left so each session highlights itself.
# Called via tmux hooks on session-created, session-closed, client-session-changed.

sessions=$(tmux list-sessions -F '#{session_name}')

for current in $sessions; do
  left=""
  for s in $sessions; do
    if [ "$s" = "$current" ]; then
      left+="#[fg=#1a1b26,bg=#7aa2f7,bold] $s #[default,fg=#565f89]"
    else
      left+="#[fg=#565f89,dim] $s #[default,fg=#565f89]"
    fi
  done
  left+=" #[fg=#3b4261]│#{?client_prefix,#[fg=#e0af68] PREFIX ,}"
  tmux set -t "$current" status-left "$left"
done
