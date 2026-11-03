# gd / gds: review changes in diffview.nvim -- one nvim, a file panel to pick
# from, and :DiffviewClose (or :qa) ends the whole review. Args pass through,
# e.g. `gd HEAD~3`. oh-my-zsh's git plugin defines both as aliases first.
unalias gd gds 2>/dev/null

gd() { nvim -c "DiffviewOpen $*" }
gds() { gd --staged "$@" }
