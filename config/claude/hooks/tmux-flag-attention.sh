#!/bin/bash
# Claude Code Notification hook: flags the current tmux window as needing
# attention by prepending a marker to its name, visible in the status bar
# and window list even from a different session.

FLAG="🔴"

[ -n "$TMUX_PANE" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

target=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}:#{window_index}' 2>/dev/null) || exit 0
current_name=$(tmux display-message -p -t "$target" '#{window_name}' 2>/dev/null) || exit 0

# rename-window turns automatic-rename off for the window, and it stays off
# once the flag is cleared -- the name would freeze at whatever it was when the
# first notification landed. Record the setting so the clear script can put it
# back.
case "$current_name" in
  "$FLAG"*) ;; # already flagged
  *)
    prev_auto=$(tmux display-message -p -t "$target" '#{automatic-rename}' 2>/dev/null)
    tmux set-option -w -t "$target" @flag-prev-auto "$prev_auto" 2>/dev/null
    tmux rename-window -t "$target" "${FLAG}${current_name}" 2>/dev/null
    ;;
esac
