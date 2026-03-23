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
- Install the [tmux plugin manager](https://github.com/tmux-plugins/tpm)
- Use [tmuxinator](https://github.com/tmuxinator/tmuxinator) for workspace management
