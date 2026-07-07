#!/bin/bash
# Claude Code UserPromptSubmit/PreToolUse hook: clears the attention marker
# (see tmux-flag-attention.sh) from the current tmux window as soon as you
# resume engaging with it — covers the case where you never switched away
# from the flagged window (e.g. you answered inline), which the
# switch-triggered tmux-side clear (tmux-clear-flag.sh) can't catch.

FLAG="🔴"

[ -n "$TMUX_PANE" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

target=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}:#{window_index}' 2>/dev/null) || exit 0
current_name=$(tmux display-message -p -t "$target" '#{window_name}' 2>/dev/null) || exit 0

case "$current_name" in
  "$FLAG"*) tmux rename-window -t "$target" "${current_name#"$FLAG"}" 2>/dev/null ;;
esac
