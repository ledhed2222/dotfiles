This repo should be cloned into ~/Dev. Then do
```zsh
./make.sh
```

# shell
* Grab [oh my zsh](https://ohmyz.sh/)
* Switch default shell to `zsh`:
```zsh
chsh -s $(which zsh)
```

# emulator
```zsh
brew install kitty
```

## font
`kitty.conf` sets `font_family PragmataPro Mono Liga`. PragmataPro is a paid
font from [Fabrizio Schiavi](https://fsd.it/shop/fonts/pragmatapro/), so the
`.ttf` files are licensed per-person and are not in this repo — download them
with your license and drop them in `~/Library/Fonts`. The config wants the
`PragmataPro_Mono_*_liga_*.ttf` faces specifically: `Mono` for fixed-width
cells, `liga` for the programming ligatures that `disable_ligatures cursor`
assumes exist. Without them installed, kitty warns and falls back to Menlo.

# vim
For file searching and neovim:
```zsh
brew install ag fzf neovim tree-sitter-cli
```

## lsp support
- For Go using [gopls](https://go.dev/gopls/)
- For C++ using [clangd](https://clangd.llvm.org/)
- For Elixir using [elixir-ls](https://github.com/elixir-lsp/elixir-ls)
- For JavaScript/TypeScript using [typescript-language-server](https://github.com/typescript-language-server/typescript-language-server)

# langs
```zsh
brew install jenv nodenv pyenv rbenv
```

# tmux additional steps
- The [tmux plugin manager](https://github.com/tmux-plugins/tpm) needs no setup: `tmux.conf` clones it on first launch and installs any missing plugin on config reload. Adding a plugin takes two reloads — the first clones it, the second sources it.
- Install [tmuxinator](https://github.com/tmuxinator/tmuxinator) for workspace management:
```zsh
brew install tmuxinator
```
- The default layout (`mux start default`) opens nvim, claude, and a terminal in the current directory
- To override per-project, run `mux new <project-name>` or place `.tmuxinator.yml` in the project root and run `mux local`

# graft (code context graph for Claude Code)
```zsh
npm i -g @nanonets/graft
graft init
```
- `graft init` wires the Claude Code integration once per machine: it merges a
  hooks stanza into `settings.json` (tracked in this repo, so the wiring
  itself is shared) and generates `~/.claude/helpers/graft-hooks.cjs`, the
  shim those hooks call. The shim is deliberately *not* tracked — `graft
  init`/`graft upgrade` overwrite it in place with whatever version ships, so
  committing it would just mean fighting graft's own updates. `settings.json`
  only lands back in this repo if `~/.claude` is actually the symlink
  `make.sh` sets up — if `~/.claude` predates that (a real directory with its
  own history/plugins/etc.), merge it in and symlink it by hand first, or
  `graft init`'s writes will just go to the untracked real directory instead.
- Per-repo, run `graft build` (no `init`) inside any repo you want a context
  graph for. It writes a git-ignored `graft/` directory there — regenerate it
  any time, nothing under it is committed. `wt new` runs this automatically
  for every worktree it creates.
