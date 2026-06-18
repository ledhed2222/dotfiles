# Dotfiles

## Installation

`make.sh` symlinks each top-level file/dir in this repo to its `~/.<name>` counterpart. Notable result: `~/.claude` is a symlink to `claude/` in this repo, so edits to `claude/` take effect immediately without reinstalling.

## Adding files to tracked directories

Directories like `claude/`, `config/`, etc. are gitignored by default with explicit allowlist exceptions. Before adding a new file inside one of these directories, add a `!path/to/file` exception to `.gitignore` or it won't be tracked.

## Custom Claude commands

Two global commands live in `claude/commands/` and are available in any repo:

- `/new-worktree <branch>` — pulls master, creates a git worktree at `$DEVHOME/worktrees/<repo>/<branch>`, and starts a detached tmuxinator session named after the branch
- `/close-worktree <branch>` — checks merge status (prompts if unmerged), removes the worktree, deletes the branch, and kills the tmux session

## tmuxinator default layout

`mux start default` opens three windows: `nvim`, `claude`, `zsh`, rooted at the current directory. Override with env vars:

```
PROJECT_ROOT=<path> PROJECT_NAME=<name> mux start default --no-attach
```
