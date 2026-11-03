#!/bin/bash
# Claude Code Stop hook: flags the window (via tmux-flag-attention.sh) once
# Claude finishes a turn, unless you look at it within DELAY seconds or send
# another prompt first.

DELAY=3

[ -n "$TMUX_PANE" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

target=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}:#{window_index}' 2>/dev/null) || exit 0
# Cleared by tmux-clear-attention.sh and tmux-clear-flag.sh, so seeing the
# window or prompting again during the delay cancels this run.
token="$$-$(date +%s)"
tmux set-option -w -t "$target" @claude-stop "$token" 2>/dev/null

flag="$(dirname "$0")/tmux-flag-attention.sh"
(
  sleep "$DELAY"
  [ "$(tmux show-options -w -v -t "$target" @claude-stop 2>/dev/null)" = "$token" ] || exit 0
  tmux set-option -w -t "$target" -u @claude-stop 2>/dev/null
  viewed=$(tmux display-message -p -t "$target" '#{&&:#{window_active},#{session_attached}}' 2>/dev/null)
  [ "$viewed" = "1" ] && exit 0
  TMUX_PANE="$TMUX_PANE" "$flag"
) </dev/null >/dev/null 2>&1 &
