# install

From a fresh machine:

```zsh
# homebrew, if this machine doesn't have it yet
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

git clone git@github.com:ledhed2222/dotfiles.git ~/Dev/dotfiles
cd ~/Dev/dotfiles
./make.sh
```

`make.sh` does the whole install, and skips every step that's already
satisfied — so it stays the thing you re-run after editing a config file,
which is its normal use. In order, it:

1. Installs **[oh my zsh](https://ohmyz.sh/)** if missing, and `chsh`es to zsh
   if that isn't your shell yet.
2. Symlinks every top-level file here to its `~/.<name>` counterpart, so edits
   take effect immediately without reinstalling. `config/` is the exception:
   `~/.config` stays a real directory, since every app writes its state there,
   and only each tracked `config/<dir>` is symlinked into it.
3. Symlinks the platform git fragment to `~/.gitconfig_os` (below), and
   `claude/CLAUDE.md` and `claude/keybindings.json` into the real `~/.claude`.
4. Installs whatever is missing from the two manifests below.
5. Installs **claude code** if it isn't on PATH — the whole `claude/` directory
   here is inert without it, and it's kept out of the Brewfile because its
   native installer self-updates and a formula would fight that.
6. Generates `~/.claude/settings.json` from `claude/settings.json` (every
   machine) and `~/.claude/settings.machine.json` (this one, untracked) — see
   [CLAUDE.md](CLAUDE.md).

Ordering that matters, now handled for you: oh my zsh goes first, because
`zshrc` depends on it and its installer replaces an existing `~/.zshrc` —
including a *symlink*, which its own check tests for with `-h`. Run by hand
afterwards it would clobber the link, so pass `--keep-zshrc` if you ever do.

`Brewfile` and `config/mise/config.toml` are the source of truth for what's
installed; `make.sh` runs both. To see what's missing without installing
anything: `brew bundle check --global` and `mise ls --missing`. The other
direction -- installed by hand but not in the Brewfile -- is `brew-audit`,
which `make.sh` also runs at the end. `brew leaves --installed-on-request` is
the full list of top-level formulae, and `brew uses --installed <formula>`
says why a dependency is there.

## where a new dependency goes

Nothing gets installed by hand. Add it in one place, run `./make.sh`:

| what it is | where it goes |
|---|---|
| a language runtime (node, python, ruby, go, elixir…) | `config/mise/config.toml`, via `mise use -g <tool>@<version>` |
| a tool from a language's registry (`npm:`, `pipx:`, `gem:`, `go:`) or that runs on a mise runtime (elixir-ls) | `config/mise/config.toml` too, even if brew has a formula — so a repo can pin its version and brew doesn't add a second runtime |
| any other brew formula or cask | `Brewfile` — macOS-only lines get `if OS.mac?` |
| ships its own updater (claude code) | a step in `make.sh`, never a manifest |
| installs itself (tpm; nvim plugins, via lazy.nvim) | nowhere — but commit `config/nvim/lazy-lock.json` when it changes |
| platform-specific git config | `gitconfig_darwin` / `gitconfig_linux` |
| a secret | nowhere tracked, and not exported into every shell — let the tool read it where it lives, as `gh` reads its token from the keychain |
| machine-specific anything else | `~/.zshrc_local_overrides`, `~/.gitconfig_local_overrides` |
| a project's own toolchain | that project, not here |

## what can't be automated

- **The PragmataPro font** — paid and per-person licensed, see below.
- **Machine-specific config** — see
  [machine-specific config](#machine-specific-config) below.

## platform differences

Git has no OS conditional of its own — `includeIf` matches only on gitdir,
branch and remote url — so `make.sh` picks the fragment at install time,
symlinking `gitconfig_darwin` or `gitconfig_linux` to `~/.gitconfig_os`, which
`gitconfig` includes unconditionally. Today that's only the credential helper
(`osxkeychain` vs `libsecret`). A missing fragment is skipped silently, so an
unrecognized platform degrades to the base config rather than breaking.

The `Brewfile` guards its macOS-only entries with `if OS.mac?` the same way.
Homebrew runs on Linux, so one file covers both.

Docker on macOS needs **Docker Desktop** (the `docker-desktop` cask), not the
`docker` formula: containers need a Linux kernel, so the engine runs in a VM
that only Docker Desktop provides, and the formula is a CLI with no engine to
talk to. On Linux the engine runs natively as a systemd daemon, which Homebrew
can't manage, so nothing here installs it: once per machine, install Docker's
apt packages (`curl -fsSL https://get.docker.com | sh` adds the repo and
installs `docker-ce`, `docker-ce-cli`, `containerd.io` and
`docker-compose-plugin`), then `sudo usermod -aG docker "$USER"` and log in
again to run `docker` without sudo. apt keeps it updated from there.

# machine-specific config

Everything here is shared by every machine, which is the point — but some
things can't be. A work laptop needs a different git email. A Linux box has
different paths. One machine has a licensed tool the others don't, or work
plugins that have no business on a personal machine. One machine is slow and
wants a lighter setup.

So each layer has exactly one untracked escape hatch, loaded last so it wins:

| file | read by | what belongs in it |
|---|---|---|
| `~/.zshrc_local_overrides` | `zshrc`, sourced last | PATH entries, env vars, a function this machine needs. It loads *after* `zsh/*.zsh`, so it can redefine anything they define. |
| `~/.gitconfig_local_overrides` | `gitconfig`, its last `[include]` | a work email, a different signing key, a per-machine `url.insteadOf` |
| `~/.config/nvim/local_overrides.lua` | `init.lua`, `dofile` as its last act | a language server that only exists here, a local-only plugin path |
| `~/.config/tmux/local_overrides.conf` | `tmux.conf`, via `if-shell` | a binding or status item that differs on this machine |
| `~/.claude/settings.machine.json` | `make.sh`, deep-merged into the generated `~/.claude/settings.json` | work plugins, private marketplaces, machine-only hooks and permissions |
| a file `@`-imported by `claude/CLAUDE.md` (`@RTK.md` is one) | Claude Code, every session | instructions that only make sense on this machine |

All six are optional and none is tracked here. Every loader tests for the file
first, so a machine without one behaves exactly as if the mechanism didn't
exist — which is why `make.sh` can be the whole install on a fresh box.

Two things to know:

- The tmux hook is sourced *before* the plugin block, so anything `tmux.conf`
  sets after it — including `tmux-sensible`'s defaults — wins over it. Put
  overrides that lose this fight in a `set-hook` instead.
- **Secrets don't belong in any of them.** `~/.zshrc_local_overrides` is
  untracked, which makes it tempting, but an exported variable reaches every
  process the shell starts — Claude Code and everything it runs included.
  Have the tool read the secret where it already lives, the way `gh` reads its
  token from the keychain. See [CLAUDE.md](CLAUDE.md).

A machine-only *package* has no equivalent hook: install it by hand, and
expect `brew-audit` to report it as installed-but-not-in-the-Brewfile on every
`make.sh`. That listing is the intended outcome, not a warning to silence.

# shell

`zshrc` sources every `zsh/*.zsh` in this repo, resolved relative to its own
real path, so those files work even without `make.sh` having run.

# emulator

kitty, from the Brewfile.

## font

`kitty.conf` sets `font_family PragmataPro Mono Liga`. PragmataPro is a paid
font from [Fabrizio Schiavi](https://fsd.it/shop/fonts/pragmatapro/), so the
`.ttf` files are licensed per-person and are not in this repo — download them
with your license and drop them in `~/Library/Fonts`. The config wants the
`PragmataPro_Mono_*_liga_*.ttf` faces specifically: `Mono` for fixed-width
cells, `liga` for the programming ligatures that `disable_ligatures cursor`
assumes exist. Without them installed, kitty warns and falls back to Menlo.

# neovim

Plugins need no setup, the same way tpm doesn't: `init.lua` clones
[lazy.nvim](https://github.com/folke/lazy.nvim) on first launch if it's
missing, and lazy installs every plugin `init.lua` asks for. Nothing about
them belongs in the `Brewfile` or the mise config.

They install under `~/.local/share/nvim`, outside this repo, and
`config/nvim/lazy-lock.json` pins the exact commit of each one, so every
machine runs the same versions.

- To upgrade: `:Lazy update` in nvim, which updates the plugins and rewrites
  the lockfile, then commit `lazy-lock.json`.
- On another machine, after pulling: `:Lazy restore`, which installs exactly
  the versions in the lockfile. (`:Lazy update` there would upgrade past them.)

# tmux

- The [tmux plugin manager](https://github.com/tmux-plugins/tpm) needs no
  setup: `tmux.conf` clones it on first launch and installs any missing plugin
  on config reload. Adding a plugin takes two reloads — the first clones it,
  the second sources it.
- `mux start default` opens nvim, claude, and a terminal in the current
  directory.
- For a repo with its own window layout, run `wt layout` in it (below) rather
  than `mux new` — `mux new`'s template hardcodes the session name, which `wt`
  needs to set per worktree. A `.tmuxinator.yml` in a project root works too,
  via `mux local`, but `wt` can't drive that one.

# worktrees

`wt` pairs a git worktree with a tmux session, so each branch gets its own
checkout and its own set of windows. It lives in `zsh/worktree.zsh`.

| | |
|---|---|
| `wt new [-b base] <branch>` | branch off `origin`'s default branch (or `base`), make a worktree, start a session, switch to it |
| `wt open [branch]` | jump to an existing worktree's session, starting it if it isn't up |
| `wt close [branch]` | remove the worktree, delete the branch, kill the session |
| `wt ls` | list worktrees, `●` marking those with a live session |
| `wt prune` | delete every branch whose remote branch is gone — i.e. whose PR merged — with its worktree and session |
| `wt layout [name]` | give this repo its own tmuxinator layout, and remember the choice |

You never have to type a full branch name. `open`, `close` and `-b` take a
fragment and hand it to `fzf` — `wt open pl1a` finds `plat-1-alpha` — or take
nothing at all and let you pick from the list. `open` accepts a single match on
its own; `close` always makes you confirm, so a typo can't delete the wrong
worktree. `<TAB>` completes worktrees, refs and layout names.

`wt new` never touches your current checkout: no stashing, no switching
branches first.

Worktrees go in `$WORKTREE_HOME/<repo>/<branch-suffix>`, which defaults to
`~/Dev/.worktrees` — hidden, so duplicate checkouts stay out of `fd`/`rg`/fzf
runs over your dev dir. Sessions are named after whatever follows the last `/`
in the branch.

`wt layout` writes `config/tmuxinator/<name>.yml`, points the repo at it with
`git config wt.layout`, and opens it in `$EDITOR`. One call covers every
worktree of that repo, present and future, because the setting lives in
`.git/config` — which also means it never ends up committed to a repo you
share. `wt -l <name>` overrides it for a single command, and `git config
--global wt.layout <name>` sets your default everywhere. Commit the new `.yml`
here to get it on your other machines.

Prefer `wt prune` to the `/clean_gone` slash command, which doesn't work — see
[CLAUDE.md](CLAUDE.md).
