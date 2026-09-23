# Shared Homebrew dependencies for this repo.
#
#   brew bundle --global          install everything missing
#   brew bundle check --global    report what's missing, install nothing
#
# make.sh symlinks this file to ~/.Brewfile, which is what `--global` reads,
# so both commands work from any directory once make.sh has run.
#
# Homebrew runs on Linux too, so this file is shared. The DSL is Ruby, so
# anything platform-specific is guarded with `if OS.mac?` / `if OS.linux?`:
# a guarded line is skipped entirely on the other platform, not attempted
# and failed. `cask` exists only on macOS, so every cask needs the guard.

# terminal emulator. The PragmataPro font kitty.conf asks for is paid and
# per-person licensed -- see the README, it can't be installed from here.
# On Linux, install kitty from the distro or upstream instead.
cask "kitty" if OS.mac?

# git. macOS ships an older Apple git; the formula keeps it current, and
# gitconfig's diff/merge tools shell out to nvim, declared below.
brew "git"
brew "gh"
brew "git-lfs"  # gitconfig declares the lfs filter with required = true

# search
brew "the_silver_searcher"  # provides `ag`
brew "fzf"

# editor
brew "neovim"
brew "tree-sitter-cli"

# language servers, shared by neovim's lsp config and Claude Code's *-lsp
# plugins in claude/settings.json -- one install serves both.
# clangd ships with the Xcode Command Line Tools on macOS, but has to be
# installed on Linux.
brew "typescript-language-server"
brew "elixir-ls"
brew "gopls"
brew "llvm" if OS.linux?  # clangd

# languages installed directly (the rest come from the version managers below)
brew "go"

# language version managers
brew "jenv"
brew "nodenv"
brew "pyenv"
brew "rbenv"

# tmux, plus the layout manager wt/mux drive
brew "tmux"
brew "tmuxinator"

# runtime for claude-mem's local worker service
brew "bun"

# Deliberately absent, because each ships its own updater and a formula would
# just install a second copy that competes with it:
#   claude code  -- native installer, self-updates ~/.local/share/claude/versions
#   graft        -- npm i -g @nanonets/graft
#   oh my zsh    -- its own curl installer
#   tpm          -- tmux.conf clones it on first launch
