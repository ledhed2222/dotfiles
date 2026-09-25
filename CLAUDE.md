# Dotfiles

## Installation

`make.sh` is the whole install: it symlinks each top-level file/dir in this repo to its `~/.<name>` counterpart (so edits take effect immediately without reinstalling), then installs oh my zsh, the two dependency manifests, and Claude Code. Every step is skipped when already satisfied, so it stays safe and cheap to re-run — which is the normal reason to run it. Two orderings inside it are load-bearing: oh my zsh must precede the symlink loop (its installer replaces an existing `~/.zshrc`, and its own check matches symlinks too, via `-h`), and `nodenv rehash` must follow the npm install (a global's binary isn't on `PATH` until a shim exists, so a fresh package looks like a failed install).

`claude/` is the exception to the symlinking: `~/.claude` holds megabytes of local session state (history, credentials, plugin installs) alongside shared config, so rather than symlinking the whole directory, `make.sh` symlinks only `claude/{CLAUDE.md,settings.json,keybindings.json}` individually into the real `~/.claude/`. Adding another shared file under `claude/` means adding it to `make.sh`'s `claude_files` list too, not just the `.gitignore` allowlist. `~/.claude/helpers/graft-hooks.cjs` is deliberately not one of them — `graft init` generates and overwrites it in place, so it's vendored per machine, not tracked here.

`zshrc` sources every `zsh/*.zsh` in this repo, resolved relative to its own real path, so those files work without `make.sh` having run.

## Where a new dependency goes

Nothing is installed by hand. Pick the home by *how the thing updates itself*, then run `./make.sh`:

- **Homebrew formula or cask** → `Brewfile`. macOS-only entries get `if OS.mac?`; the file is shared with Linux, where `cask` doesn't exist.
- **npm global** → `npm-globals.txt`. `brew bundle` only understands formulae, casks and taps, hence the second manifest. These install into the *current* nodenv version's prefix, so switching node versions leaves them behind — re-running `make.sh` restores them.
- **Ships its own updater** (Claude Code) → a step in `make.sh`, never a manifest. A formula would install a second copy that competes with the self-updater.
- **Installs itself** (tpm, cloned by `tmux.conf`) → nothing at all.
- **Platform-specific git config** → `gitconfig_darwin` / `gitconfig_linux`, which `make.sh` links to `~/.gitconfig_os`. Git has no OS conditional; `includeIf` matches only gitdir, branch and remote url.
- **A secret** → never a tracked file. Read it at shell start from wherever it already lives: `zshrc` gets the GitHub token from `gh auth token`, so the keyring stays the only copy.
- **Machine-specific anything else** → `~/.zshrc_local_overrides` or `~/.gitconfig_local_overrides`, both untracked and applied last.
- **A project's own toolchain** (typescript, say) → that project's `package.json`, not here.

Prose describing an install is a liability; the manifest that performs it can't drift. When both exist, delete the prose.

## Adding files to tracked directories

Directories like `claude/`, `config/`, etc. are gitignored by default with explicit allowlist exceptions. Before adding a new file inside one of these directories, add a `!path/to/file` exception to `.gitignore` or it won't be tracked.

## Worktree management (`wt`)

`zsh/worktree.zsh` defines `wt`, which pairs a git worktree with a tmux session. It replaces the old `/new-worktree`, `/connect-worktree`, and `/close-worktree` Claude skills so worktree navigation doesn't require Claude.

- `wt new [-l layout] <branch>` — branches off `origin`'s default branch, creates a worktree at `$WORKTREE_HOME/<repo>/<branch-suffix>`, starts a session and switches to it. The current checkout is never touched. If graft is installed, `wt new` also refuses to run at all unless the main checkout already has a `graft/` graph (`graft/.graph/wiring.json`) for the new worktree to seed from — a worktree with no seed would cold-parse the whole repo, which on a large one runs long enough to look like `wt new` hung. Run `graft build` in the main checkout once; every worktree after that seeds fast instead of failing this check.
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

## Claude behavior across all repos

Coding style and behavior preferences that apply everywhere, not just this repo, live in [`claude/CLAUDE.md`](claude/CLAUDE.md) (symlinked to `~/.claude/CLAUDE.md`) rather than here.

## graft rewrites tracked settings on every `init`

`graft init` does not only write the untracked per-machine shim documented in
the README. It also rewrites the hook commands in `claude/settings.json`,
replacing `$HOME` with the absolute home directory of whichever machine it ran
on (`node "/Users/<you>/.claude/helpers/graft-hooks.cjs" ...`). That file is
tracked and shared, so the rewrite pins it to one machine and the hooks break
everywhere else. After any `graft init`, put `$HOME` back and confirm `git diff
claude/settings.json` is empty before committing. (`graft upgrade` only bumps
the npm package and rewrites nothing; it is re-running `init` afterwards that
does.)

`init` is also repo-scoped, not just global: run in a repo it writes
`.claude/settings.json`, `.claude/helpers/*.cjs`, `.claude/skills/graft/` and
`.mcp.json` there. Those duplicate the user-level wiring rather than adding to
it, so every graft hook then fires twice in that repo — once from
`claude/settings.json`, once from the project copy. They are gitignored here
for that reason. Keeping the project copy for its one unique feature, graft's
statusline, would also mean tracking `.claude/helpers/graft-statusline.cjs`,
the same vendored shim this repo deliberately does not track.

For a repo that just needs a graph, `graft build` alone is enough — `init` is
the once-per-machine wiring step.

## typescript-language-server has no global fallback, on purpose

`typescript-language-server` is a wrapper: the actual work is done by
`tsserver`, which it resolves from the *project's* `node_modules/typescript`.
A JS/TS repo therefore needs typescript as a local dependency -- which it
should be pinning anyway, so the editor and CI agree on a compiler version.

Outside such a project -- this repo, a scratch `.ts` file -- there is nothing
to fall back to, and the server will complain. That is expected, not a broken
install. Homebrew's `typescript-language-server` bundles a `typescript` that is
a symlink to brew's `typescript` formula, now at 7.x: the native port, whose
only binary is `tsc`. TypeScript 7 dropped `tsserver` entirely, so the bundled
copy cannot drive the server, and `typescript@latest` on npm is the same 7.x.
The last release carrying `tsserver` is 5.9.3.

Installing `typescript@5` globally was tried and reverted: it only serves repos
that would never ask for it, and the brew-installed server looks in its own
`node_modules` (the 7.x symlink) before anything global, so it isn't reliably
picked up anyway. Fix it in the project, not here.

## Repo-specific Neovim config without touching the repo

`init.lua` sets `opt.exrc = true` / `opt.secure = true`, so Neovim auto-sources a `.nvim.lua` (or `.nvimrc`/`.exrc`) found in the cwd on startup, prompting `:trust` the first time. Use this for config that only makes sense in one repo (e.g. a clangd `--query-driver` glob pointing at a project's custom compiler wrapper) instead of adding repo-specific logic to this dotfiles repo.

To keep the file out of a shared repo you don't want to commit to: add it to `.git/info/exclude` (the local, untracked sibling of `.gitignore` — lives inside `.git/`, never part of the working tree, never seen by anyone else who clones the repo) rather than editing the repo's tracked `.gitignore`. For a repo used via multiple git worktrees, `.git/info/exclude` lives in the shared common git dir, so one entry covers every worktree — but `.nvim.lua` itself is a real file in the working tree, so it has to exist (or be symlinked in) per worktree, and gets `:trust`ed separately per path.

To make new worktrees pick it up automatically without touching `wt` (which is repo-agnostic) or anything tracked: keep the real file in the main worktree and drop a `.git/hooks/post-checkout` in that repo that symlinks it into `$(pwd)` whenever `$(pwd)` isn't the main worktree. `git worktree add` runs `post-checkout` in the worktree it just created (as does an ordinary branch checkout), and `.git/hooks/` — like `info/exclude` — lives in the shared common git dir, so installing the hook once covers every worktree, present and future. Symlink the file into any worktrees that already existed before the hook went in; the hook only fires on checkouts from that point on.
