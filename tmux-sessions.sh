#!/usr/bin/env bash
# Renders tmux session list for the status bar.
# Attached session: bold blue. Others: dim gray.
tmux list-sessions -F '#{session_name}:#{session_attached}' | awk -F: '{
  if ($2 > 0) printf "#[fg=#7aa2f7,bold] [%s]#[nobold]", $1
  else printf "#[fg=#565f89] [%s]", $1
}'
