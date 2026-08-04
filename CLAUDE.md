# Dotfiles

## Installation

`make.sh` symlinks each top-level file/dir in this repo to its `~/.<name>` counterpart. Notable result: `~/.claude` is a symlink to `claude/` in this repo, so edits to `claude/` take effect immediately without reinstalling.

`zshrc` sources every `zsh/*.zsh` in this repo, resolved relative to its own real path, so those files work without `make.sh` having run.

## Adding files to tracked directories

Directories like `claude/`, `config/`, etc. are gitignored by default with explicit allowlist exceptions. Before adding a new file inside one of these directories, add a `!path/to/file` exception to `.gitignore` or it won't be tracked.

## Worktree management (`wt`)

`zsh/worktree.zsh` defines `wt`, which pairs a git worktree with a tmux session. It replaces the old `/new-worktree`, `/connect-worktree`, and `/close-worktree` Claude skills so worktree navigation doesn't require Claude.

- `wt new [-l layout] <branch>` — branches off `origin`'s default branch, creates a worktree at `$WORKTREE_HOME/<repo>/<branch-suffix>`, starts a session and switches to it. The current checkout is never touched.
- `wt open [-l layout] [branch]` — opens (or jumps to) the session for an existing worktree; no argument gives an fzf picker
- `wt close [branch]` — removes the worktree, deletes the branch, kills the session. Prompts if the branch is unmerged or the tree is dirty.
- `wt ls` — lists worktrees, marking those with a live session

Sessions are named after the branch suffix (everything after the last `/`). `WORKTREE_HOME` defaults to `~/worktrees`.

## tmuxinator layouts

`mux start default` opens three windows: `nvim`, `claude`, `zsh`, rooted at the current directory. Override with env vars:

```
PROJECT_ROOT=<path> PROJECT_NAME=<name> mux start default --no-attach
```

`wt` uses `default` unless a repo commits a `.tmuxinator-layout` file naming another layout in `config/tmuxinator/`. It must be committed — `wt new` checks out a fresh tree, so untracked files don't reach new worktrees. Any layout `wt` drives has to read `PROJECT_ROOT`/`PROJECT_NAME` the way `default.yml` does.
