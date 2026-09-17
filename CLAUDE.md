# Dotfiles

## Installation

`make.sh` symlinks each top-level file/dir in this repo to its `~/.<name>` counterpart. Notable result: `~/.claude` is a symlink to `claude/` in this repo, so edits to `claude/` take effect immediately without reinstalling.

`zshrc` sources every `zsh/*.zsh` in this repo, resolved relative to its own real path, so those files work without `make.sh` having run.

## Adding files to tracked directories

Directories like `claude/`, `config/`, etc. are gitignored by default with explicit allowlist exceptions. Before adding a new file inside one of these directories, add a `!path/to/file` exception to `.gitignore` or it won't be tracked.

## Worktree management (`wt`)

`zsh/worktree.zsh` defines `wt`, which pairs a git worktree with a tmux session. It replaces the old `/new-worktree`, `/connect-worktree`, and `/close-worktree` Claude skills so worktree navigation doesn't require Claude.

- `wt new [-l layout] <branch>` — branches off `origin`'s default branch, creates a worktree at `$WORKTREE_HOME/<repo>/<branch-suffix>`, starts a session and switches to it. The current checkout is never touched.
- `wt open [-l layout] [branch]` — opens (or jumps to) the session for an existing worktree
- `wt close [branch]` — removes the worktree, deletes the branch, kills the session. Prompts if the branch is unmerged or the tree is dirty.

`open` and `close` accept an exact branch (full name, suffix, or worktree directory name), a fuzzy fragment, or nothing at all. Exact matches are used directly; anything else goes to `fzf` with the argument as the starting query. `open` auto-accepts a single fuzzy hit, `close` never does — it always makes you confirm the selection, so a typo can't delete the wrong worktree.
- `wt ls` — lists worktrees, marking those with a live session

Sessions are named after the branch suffix (everything after the last `/`). `WORKTREE_HOME` defaults to `$DEVHOME/.worktrees` (`~/.worktrees` if `DEVHOME` is unset) — hidden so the duplicate checkouts stay out of `fd`/`rg`/fzf runs over the dev dir. `zshrc` exports the common-location vars before it sources `zsh/*.zsh` so `DEVHOME` is visible there.

## tmuxinator layouts

`mux start default` opens three windows: `nvim`, `claude`, `zsh`, rooted at the current directory. Override with env vars:

```
PROJECT_ROOT=<path> PROJECT_NAME=<name> mux start default --no-attach
```

`wt` uses `default` unless the repo sets another layout from `config/tmuxinator/`:

```
git config wt.layout personalsite     # this repo
git config --global wt.layout <name>  # personal default everywhere
```

Local git config lives in `.git/config`, so this never gets committed to a shared repo and needs no `.gitignore` entry, and every worktree of the repo reads the same value. Resolution order is `wt -l <layout>` → local → global → `default`. Any layout `wt` drives has to read `PROJECT_ROOT`/`PROJECT_NAME` the way `default.yml` does.

## Repo-specific Neovim config without touching the repo

`init.lua` sets `opt.exrc = true` / `opt.secure = true`, so Neovim auto-sources a `.nvim.lua` (or `.nvimrc`/`.exrc`) found in the cwd on startup, prompting `:trust` the first time. Use this for config that only makes sense in one repo (e.g. a clangd `--query-driver` glob pointing at a project's custom compiler wrapper) instead of adding repo-specific logic to this dotfiles repo.

To keep the file out of a shared repo you don't want to commit to: add it to `.git/info/exclude` (the local, untracked sibling of `.gitignore` — lives inside `.git/`, never part of the working tree, never seen by anyone else who clones the repo) rather than editing the repo's tracked `.gitignore`. For a repo used via multiple git worktrees, `.git/info/exclude` lives in the shared common git dir, so one entry covers every worktree — but `.nvim.lua` itself is a real file in the working tree, so it has to exist (or be symlinked in) per worktree, and gets `:trust`ed separately per path.

To make new worktrees pick it up automatically without touching `wt` (which is repo-agnostic) or anything tracked: keep the real file in the main worktree and drop a `.git/hooks/post-checkout` in that repo that symlinks it into `$(pwd)` whenever `$(pwd)` isn't the main worktree. `git worktree add` runs `post-checkout` in the worktree it just created (as does an ordinary branch checkout), and `.git/hooks/` — like `info/exclude` — lives in the shared common git dir, so installing the hook once covers every worktree, present and future. Symlink the file into any worktrees that already existed before the hook went in; the hook only fires on checkouts from that point on.
