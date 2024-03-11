# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="agnoster"
# Hide user and host in prompt for local machine
DEFAULT_USER="$(whoami)$(prompt_context(){})"

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
alias gd="git difftool"
alias gds="git difftool --staged"
if (echo $TERM | grep -q kitty); then
  alias ssh="kitty +kitten ssh"
fi

# serve this directory - default port is 3000
function server {
	if [[ "${#1}" == 0 ]]; then
		python2 -m SimpleHTTPServer 3000
	else
		python2 -m SimpleHTTPServer "${1}"
	fi
}

# fo - open the selected file with the default editor. ctrl-o open with
# default command
function fo {
  local out file key
  IFS=$'\n' out=($(fzf-tmux --select-1 --query="$1" --exit-0 --expect=ctrl-o,ctrl-e))
  key=$(head -1 <<< "$out")
  file=$(head -2 <<< "$out" | tail -1)
  if [[ -n "$file" ]]; then
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

# MacOS-specific stuff
if [[ $(uname) == "Darwin" ]]; then
	# Ability to cd into aliases
	# https://github.com/shiguol/CD2Alies
	function cd {
		if [[ "${#1}" == 0 ]]; then
			builtin cd
		elif [[ -d "${1}" ]]; then
			builtin cd "${1}"
		elif [[ -f "${1}" || -L "${1}" ]]; then
			path=$(getTrueName "$1")
			builtin cd "$path"
		else
			builtin cd "${1}"
		fi
	}

  # Different things depending on Apple or Intel
  if [[ $(sysctl -n machdep.cpu.brand_string | grep Apple) ]]; then
    # Homebrew setup
    eval "$(/opt/homebrew/bin/brew shellenv)"

    # Setup fzf
    # ---------
    if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
      PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
    fi
    
    # Auto-completion
    # ---------------
    [[ $- == *i* ]] && source "/opt/homebrew/opt/fzf/shell/completion.zsh" 2> /dev/null
    
    # Key bindings
    # ------------
    source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
    export FZF_HOME=/opt/homebrew/opt/fzf
  else
    # Homebrew setup
    export PATH="$PATH:/usr/local/sbin"

    # fzf setup (assumes installed with homebrew)
    if [[ ! "$PATH" == */usr/local/opt/fzf/bin* ]]; then
      export PATH="${PATH:+${PATH}:}/usr/local/opt/fzf/bin"
    fi
    ## auto-completion
    [[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.zsh" 2> /dev/null
    ## key bindings
    source "/usr/local/opt/fzf/shell/key-bindings.zsh"
    export FZF_HOME=/usr/local/opt/fzf
  fi
fi

# Linux-specific stuff
if [[ $(uname) == "Linux" ]]; then
  # fzf setup (assumes installed in ~/.fzf)
  ##
  ## add to path
  if [[ ! "$PATH" == *"$HOME/.fzf/bin"* ]]; then
    export PATH="${PATH:+${PATH}:}/$HOME/.fzf/bin"
  fi
  ## auto-completion
  [[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.zsh" 2> /dev/null
  ## key bindings
  source "$HOME/.fzf/shell/key-bindings.zsh"
fi

# Common locations
export DEVHOME="$HOME/Dev"
export WORKHOME="$HOME/Documents/Work"
export APACHEDIR="/etc/apache2" #virtual hosts in vhosts dir
export XDG_CONFIG_HOME="$HOME/.config"

# Go setup
export GOPATH="$DEVHOME/go"
if [[ -a $GOPATH ]]; then
  export PATH="$PATH:$GOPATH/bin"
fi

# Elixir setup
export ERL_AFLAGS="-kernel shell_history enabled"

# Java/jenv setup
if (command -v jenv > /dev/null); then
  export PATH="$HOME/.jenv/bin:$PATH"
  eval "$(jenv init -)"
fi

# Android setup
export ANDROID_HOME="$HOME/Library/Android/sdk"
if [[ -a $ANDROID_HOME ]]; then
  export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"
fi

# Docker setup
export PATH="$HOME/.docker/bin:$PATH"

# load pyenv
if (command -v pyenv > /dev/null); then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

# Ruby/rbenv setup
if (command -v brew > /dev/null); then
  export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
fi

if (command -v rbenv > /dev/null); then
  eval "$(rbenv init -)"
fi

# load nodenv
if (command -v nodenv > /dev/null); then
  eval "$(nodenv init -)"
fi

# Finally - allow a place per machine to override anything here in case some
# path is super specific on another machine
if [[ -a $HOME/.zshrc_local_overrides ]]; then
  source $HOME/.zshrc_local_overrides
fi
