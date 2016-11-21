#vim
* File searching best done with `ag`. On MacOS install with: `brew install ag`
* Autocompletion requires vim compiled with Lua. On MacOS install with: `brew install vim --with-lua`
* Markdown previewing in Github style requires `grip`. On MacOS install with: `brew install grip`
* Remember to install plugins via:
```vimscript
:PluginInstall
```
* Some plugins require extra compilation - see .vimrc


#shell
* For cd'ing into MacOS aliases need [getTruePath](https://github.com/shiguol/CD2Alies)
* To switch default shell from bash to zsh:
```bash
chsh -s `which zsh`
```
* To switch default shell from zsh to bash:
```zsh
chsh -s `which bash`
```

##Terminal.app configuration
* Preferences > Profiles > Shell - set 'when the shell exits' to 'close if the shell exited cleanly'
* Preferences > Profiles > Shell - set 'ask before closing' to 'only if there are processes other than the login shell and:' and add 'osascript' to that list
* Preferences > Profiles > Keyboard - map the 'home' key to \001 and the 'end' key to \005

