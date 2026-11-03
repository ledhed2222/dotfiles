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

`Brewfile` and `npm-globals.txt` are the source of truth for what's installed;
`make.sh` runs both. To see what's missing without installing anything:
`brew bundle check --global` and `npm ls -g --depth=0`.

## where a new dependency goes

Nothing gets installed by hand. Add it in one place, run `./make.sh`:

| what it is | where it goes |
|---|---|
| brew formula or cask | `Brewfile` — macOS-only lines get `if OS.mac?` |
| npm global | `npm-globals.txt` |
| ships its own updater (claude code) | a step in `make.sh`, never a manifest |
| installs itself (tpm) | nowhere |
| platform-specific git config | `gitconfig_darwin` / `gitconfig_linux` |
| a secret | nowhere tracked, and not exported into every shell — let the tool read it where it lives, as `gh` reads its token from the keychain |
| machine-specific anything else | `~/.zshrc_local_overrides`, `~/.gitconfig_local_overrides` |
| a project's own toolchain | that project, not here |

One gotcha on a bare machine: `nodenv` arrives with the Brewfile but has no node
version, so `npm` is missing and the globals are skipped with a message. Run
`nodenv install <version> && nodenv global <version>`, then `./make.sh` again.

## what can't be automated

- **The PragmataPro font** — paid and per-person licensed, see below.
- **A JDK**, if you want Java. `jenv` only *manages* JDKs; unlike
  `nodenv`/`pyenv`/`rbenv` it won't build one for you.
- **Machine-specific config**, which goes in `~/.zshrc_local_overrides` and
  `~/.gitconfig_local_overrides`. Both are sourced/included last when present,
  and neither is tracked here.

## platform differences

Git has no OS conditional of its own — `includeIf` matches only on gitdir,
branch and remote url — so `make.sh` picks the fragment at install time,
symlinking `gitconfig_darwin` or `gitconfig_linux` to `~/.gitconfig_os`, which
`gitconfig` includes unconditionally. Today that's only the credential helper
(`osxkeychain` vs `libsecret`). A missing fragment is skipped silently, so an
unrecognized platform degrades to the base config rather than breaking.

The `Brewfile` guards its macOS-only entries with `if OS.mac?` the same way.
Homebrew runs on Linux, so one file covers both.

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

Plugins are managed by [lazy.nvim](https://github.com/folke/lazy.nvim), and
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
- To override per-project, run `mux new <project-name>` or place a
  `.tmuxinator.yml` in the project root and run `mux local`.
