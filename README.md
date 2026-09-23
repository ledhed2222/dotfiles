# install

From a fresh machine:

```zsh
# homebrew, if this machine doesn't have it yet
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

git clone git@github.com:ledhed2222/dotfiles.git ~/Dev/dotfiles
cd ~/Dev/dotfiles
./make.sh
graft init    # once per machine, see below
```

`make.sh` does the whole install, and skips every step that's already
satisfied — so it stays the thing you re-run after editing a config file,
which is its normal use. In order, it:

1. Installs **[oh my zsh](https://ohmyz.sh/)** if missing, and `chsh`es to zsh
   if that isn't your shell yet.
2. Symlinks every top-level file here to its `~/.<name>` counterpart, so edits
   take effect immediately without reinstalling.
3. Symlinks the platform git fragment to `~/.gitconfig_os` (below), and
   `claude/`'s three shared files into the real `~/.claude`.
4. Installs whatever is missing from the two manifests below.
5. Installs **claude code** if it isn't on PATH — the whole `claude/` directory
   here is inert without it, and it's kept out of the Brewfile because its
   native installer self-updates and a formula would fight that.

Ordering that matters, now handled for you: oh my zsh goes first, because
`zshrc` depends on it and its installer replaces an existing `~/.zshrc` —
including a *symlink*, which its own check tests for with `-h`. Run by hand
afterwards it would clobber the link, so pass `--keep-zshrc` if you ever do.

`graft init` is the one step `make.sh` won't take for you: it rewrites the
tracked `claude/settings.json` with this machine's absolute home path, so
running it automatically would dirty the repo every time. The script just
reminds you when graft is installed but unwired.

The two manifests are the source of truth for what gets installed. `make.sh`
runs both, and either is safe to run alone at any time — they install what's
missing and leave the rest alone:

| manifest | holds | install | check |
|---|---|---|---|
| `Brewfile` | formulae + casks | `brew bundle --global` | `brew bundle check --global` |
| `npm-globals.txt` | npm globals | `grep -v '^#' npm-globals.txt \| xargs npm i -g` | `npm ls -g --depth=0` |

To add a dependency, put it in the matching manifest and re-run `./make.sh` —
`brew "ripgrep"` in the Brewfile, or a bare package name on its own line in
`npm-globals.txt`. Homebrew reads `~/.Brewfile`, which `make.sh` symlinks, so
`--global` works from any directory; the npm line reads the file out of the
repo.

`npm-globals.txt` exists because `brew bundle` only knows about formulae, casks
and taps. Globals install into the *current* nodenv version's prefix, so
`nodenv global <new-version>` leaves them behind — re-run `./make.sh` and
they're back. On a bare machine that bites once in the other direction too:
nodenv arrives with the Brewfile but has no node version yet, so `npm` doesn't
exist and the globals are skipped with a message. Run
`nodenv install <version> && nodenv global <version>`, then `./make.sh` again.

**tpm** needs no step of its own — `tmux.conf` clones it on first launch.

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

# lsp support

- Go — [gopls](https://go.dev/gopls/)
- C/C++ — [clangd](https://clangd.llvm.org/), which ships with the Xcode
  Command Line Tools on macOS but needs `llvm` on Linux
- Elixir — [elixir-ls](https://github.com/elixir-lsp/elixir-ls)
- JavaScript/TypeScript —
  [typescript-language-server](https://github.com/typescript-language-server/typescript-language-server)

All but clangd come from the Brewfile. The `*-lsp` plugins enabled in
`claude/settings.json` spawn these same binaries, so one install serves both
neovim and Claude Code.

`typescript-language-server` drives `tsserver`, which it resolves from the
project's own `node_modules/typescript` — so a JS/TS repo needs typescript as a
local dependency, which it should be pinning anyway. There is deliberately no
global fallback: the brew formula's bundled copy is typescript 7, the native
port, which ships only `tsc` and dropped `tsserver` entirely. Outside a project
that has it locally, expect the server to complain; inside one, it's fine.

# tmux

- The [tmux plugin manager](https://github.com/tmux-plugins/tpm) needs no
  setup: `tmux.conf` clones it on first launch and installs any missing plugin
  on config reload. Adding a plugin takes two reloads — the first clones it,
  the second sources it.
- `mux start default` opens nvim, claude, and a terminal in the current
  directory.
- To override per-project, run `mux new <project-name>` or place a
  `.tmuxinator.yml` in the project root and run `mux local`.

# graft (code context graph for Claude Code)

Installed from `npm-globals.txt`; `graft init` is in the install block above.

- `graft init` wires the Claude Code integration once per machine: it merges a
  hooks stanza into `settings.json` (tracked in this repo, so the wiring itself
  is shared) and generates `~/.claude/helpers/graft-hooks.cjs`, the shim those
  hooks call. The shim is deliberately *not* tracked — `graft init`/`graft
  upgrade` overwrite it in place with whatever version ships, so committing it
  would just mean fighting graft's own updates. Those writes reach this repo
  only because `make.sh` symlinks `claude/settings.json` into the otherwise
  real, local `~/.claude`; see [CLAUDE.md](CLAUDE.md) for what else `init`
  rewrites, and why its per-repo output is gitignored here.
- Per-repo, run `graft build` (no `init`) inside any repo you want a context
  graph for. It writes a git-ignored `graft/` directory there — regenerate it
  any time, nothing under it is committed. `wt new` runs this automatically for
  every worktree it creates.
