#!/bin/bash
# Clears the attention marker (see tmux-flag-attention.sh) from a window
# when the user actually switches into it. Invoked from tmux hooks
# (after-select-window, client-session-changed) with the target as
# "session_name:window_index".

FLAG="🔴"

target="$1"
[ -n "$target" ] || exit 0

current_name=$(tmux display-message -p -t "$target" '#{window_name}' 2>/dev/null) || exit 0

case "$current_name" in
  "$FLAG"*)
    tmux rename-window -t "$target" "${current_name#"$FLAG"}" 2>/dev/null
    # flagging had to rename the window, which disables automatic-rename for
    # good. Hand the window back to tmux if that's where it came from.
    prev_auto=$(tmux show-options -w -v -t "$target" @flag-prev-auto 2>/dev/null)
    if [ "$prev_auto" = "1" ]; then
      tmux set-option -w -t "$target" -u automatic-rename 2>/dev/null
    fi
    tmux set-option -w -t "$target" -u @flag-prev-auto 2>/dev/null
    ;;
esac
