# vim
* File searching best done with `ag`. On MacOS install with: `brew install ag`
* Editor is `nvim`. On MacOS install with:
```zsh
brew install neovim
```
* Markdown previewing in Github style requires `grip`. On MacOS install with: `brew install grip`

# shell
* To switch default shell from bash to zsh:
```bash
chsh -s $(which zsh)
```

## Kitty emulator
```zsh
brew cask install kitty
```

## Terminal.app configuration
* Preferences > Profiles > Shell - set 'when the shell exists' to 'close if
  the shell exited cleanly'
* Preferences > Profiles > Shell - set 'ask before closing' to 'only if there
  are processes other than the login shell and:' and add 'osascript' to that
  list
* Preferences > Profiles > Keyboard - map the 'home' key to \001 and the 'end'
  key to \005
* Preferences > Profiles > Advanced - uncheck 'Allow VT100 application keypad
  mode"

