#!/bin/bash
# Claude Code UserPromptSubmit/PreToolUse hook: clears the attention marker
# (see tmux-flag-attention.sh) from the current tmux window as soon as you
# resume engaging with it — covers the case where you never switched away
# from the flagged window (e.g. you answered inline), which the
# switch-triggered tmux-side clear can't catch. Same clear either way.

[ -n "$TMUX_PANE" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

target=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}:#{window_index}' 2>/dev/null) || exit 0
exec ~/.config/tmux/tmux-clear-flag.sh "$target"
