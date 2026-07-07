#!/bin/bash
# Claude Code Notification hook: flags the current tmux window as needing
# attention by prepending a marker to its name, visible in the status bar
# and window list even from a different session.

FLAG="🔴"

[ -n "$TMUX_PANE" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

target=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}:#{window_index}' 2>/dev/null) || exit 0
current_name=$(tmux display-message -p -t "$target" '#{window_name}' 2>/dev/null) || exit 0

case "$current_name" in
  "$FLAG"*) ;; # already flagged
  *) tmux rename-window -t "$target" "${FLAG}${current_name}" 2>/dev/null ;;
esac
