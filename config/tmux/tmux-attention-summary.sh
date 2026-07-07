#!/bin/bash
# Prints a compact "needs you" summary for the tmux status bar: the names of
# any sessions with a window flagged by tmux-flag-attention.sh. Empty output
# when nothing is flagged, so the segment disappears entirely.

FLAG="🔴"

flagged=$(tmux list-windows -a -F '#{session_name}	#{window_name}' 2>/dev/null \
  | awk -F'\t' -v flag="$FLAG" 'index($2, flag) == 1 { print $1 }' \
  | sort -u)

[ -n "$flagged" ] || exit 0

echo "${FLAG}$(echo "$flagged" | paste -sd, -)"
