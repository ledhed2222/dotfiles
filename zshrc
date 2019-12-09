# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(vi-mode git bundler)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor
export EDITOR="nvim"

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
alias rm="rm -i"
alias top="top -o cpu -s 3 -stats pid,command,cpu,rprvt,rsize,vprvt,vsize,user,state,threads,ppid,pgrp,faults,cow"
alias grep="grep -E --color=always"
alias python="python3"
alias gd="git difftool"
alias gds="git difftool --staged"

# serve this directory - default port is 3000
function server {
	if [[ "${#1}" == 0 ]]
	then
		python -m SimpleHTTPServer 3000
	else
		python -m SimpleHTTPServer "${1}"
	fi
}

# fo - open the selected file with the default editor. ctrl-o open with
# default command
function fo {
  local out file key
  IFS=$'\n' out=($(fzf-tmux --select-1 --query="$1" --exit-0 --expect=ctrl-o,ctrl-e))
  key=$(head -1 <<< "$out")
  file=$(head -2 <<< "$out" | tail -1)
  if [[ -n "$file" ]]
  then
    [ "$key" = ctrl-o ] && open "$file" || ${EDITOR:-vim} "$file"
  fi
}

# fbr - fuzzy checkout git branch
function fbr {
  local branches branch
  branches=$(git branch -vv) &&
    branch=$(echo "$branches" | fzf +m) &&
    git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# MacOS specific stuff
if [[ $(uname) == "Darwin" ]]
then
	# Ability to cd into aliases
	# https://github.com/shiguol/CD2Alies
	function cd {
		if [[ "${#1}" == 0 ]]
		then
			builtin cd
		elif [[ -d "${1}" ]]
		then
			builtin cd "${1}"
		elif [[ -f "${1}" || -L "${1}" ]]
		then
			path=$(getTrueName "$1")
			builtin cd "$path"
		else
			builtin cd "${1}"
		fi
	}
  # Linux-like `exit` that kills Terminal
  # when last session ends
  # only use this if you're using Terminal instead of kitty
  #
  # function exit {
  # 	if [[ `ps -o tty | grep '[0-9]' | uniq | wc -l` -gt 1 ]]
  # 	then
  # 		builtin exit
  # 	else
  # 		osascript -e 'quit app "Terminal"'
  # 	fi
  # }
fi
# End MacOS specific stuff

# Common locations
export DEVHOME="$HOME/Dev"
export APACHEDIR="/etc/apache2" #virtual hosts in vhosts dir
export XDG_CONFIG_HOME="$HOME/.config"

# Go setup
export GOPATH="$DEVHOME/go"
export PATH="$PATH:$GOPATH/bin"

# Java setup
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
export JAVA_EXTENSION_PATH="$HOME/Library/Java/Extensions" # Just to make it easy to remember where extensions are

# Android setup
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"

# C++ setup
export BOOST_ROOT="/usr/local/$(ls /usr/local | grep --color=none "^boost" | head -1)"

# NVM setup
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" # This loads nvm
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/gregweisbrod/Documents/Dev/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/gregweisbrod/Documents/Dev/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/gregweisbrod/Documents/Dev/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/gregweisbrod/Documents/Dev/google-cloud-sdk/completion.zsh.inc'; fi
