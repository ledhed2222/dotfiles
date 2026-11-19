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

  # Docker Desktop
  if [[ -d "$HOME/.docker/bin" ]]; then
    export PATH="$HOME/.docker/bin:$PATH"
  fi
fi

# Homebrew, wherever this platform keeps it: /opt/homebrew on Apple silicon,
# /usr/local on an Intel mac, /home/linuxbrew on Linux. Its shellenv is what
# exports HOMEBREW_PREFIX, which everything below keys on rather than repeating
# those prefixes -- and picking the prefix by probing for the binary replaces a
# `sysctl | grep` pair that ran at every single shell start.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x $_brew ]]; then
    eval "$($_brew shellenv)"
    break
  fi
done
unset _brew

# fzf, installed from the Brewfile. This was three near-identical blocks, one
# per platform; the Linux copy pointed at ~/.fzf, which nothing installs any
# more, so its unguarded `source` failed on every Linux shell start. Guarding on
# the directory keeps the source itself unguarded, so a genuinely broken install
# still says so instead of failing silently.
if [[ -d $HOMEBREW_PREFIX/opt/fzf ]]; then
  export FZF_HOME="$HOMEBREW_PREFIX/opt/fzf"
  if [[ ! "$PATH" == *"$FZF_HOME/bin"* ]]; then
    export PATH="${PATH:+${PATH}:}$FZF_HOME/bin"
  fi
  [[ $- == *i* ]] && source "$FZF_HOME/shell/completion.zsh" 2> /dev/null
  source "$FZF_HOME/shell/key-bindings.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="agnoster"
# Hide user and host in prompt for local machine
DEFAULT_USER="$(whoami)"

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

# tmux configs
export ZSH_TMUX_AUTOSTART=true
export ZSH_TMUX_AUTOCONNECT=${ZSH_TMUX_AUTOCONNECT:-true}
export ZSH_TMUX_UNICODE=true
export ZSH_TMUX_CONFIG=~/.config/tmux/tmux.conf

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git tmux vi-mode)
# Default 0.4s Esc wait makes vi-mode feel laggy.
KEYTIMEOUT=1

source $ZSH/oh-my-zsh.sh

# The omz tmux plugin aliases `tmux` to `_zsh_tmux_plugin_run`, but Claude Code's
# shell snapshot captures aliases without the referenced function, breaking `tmux`.
# Unaliasing here lets `tmux` resolve to the real binary while keeping autostart.
unalias tmux 2>/dev/null || true

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
alias grep="grep -E --color=always"
# `clear` only erases the visible screen: no terminfo entry on this machine
# defines E3 (not screen-256color, not even kitty's own), so clear/tput never
# emit the scrollback reset. CSI 3J is that reset, and tmux implements it by
# clearing the pane's history -- so this wipes the scrollback, not just the view.
alias clear='printf "\033[H\033[2J\033[3J"'
alias mux="tmuxinator"

# Bare `claude` resumes this directory's most recent conversation. `--continue`
# exits 1 when there's no history to resume, so fall back to a fresh session.
# `--new` forces a fresh one; claude has no such flag of its own, so it is
# stripped rather than passed on. Any other args (-p, --resume, a prompt) pass
# straight through.
function claude {
  if (( ${@[(I)--new]} )); then
    command claude "${@:#--new}"
  elif (( $# == 0 )); then
    command claude --continue || command claude
  else
    command claude "$@"
  fi
}

# Common locations
export DEVHOME="$HOME/Dev"
export WORKHOME="$HOME/Documents/Work"
export APACHEDIR="/etc/apache2" #virtual hosts in vhosts dir
export XDG_CONFIG_HOME="$HOME/.config"

# Everything in the repo's zsh/ dir. Resolved relative to this file's real
# location (%x survives being read as ~/.zshrc; :A resolves the symlink), so it
# works straight out of the repo without make.sh having run. (N) skips the loop
# entirely when nothing matches.
for _zshrc_part in "${${(%):-%x}:A:h}"/zsh/*.zsh(N); do
  source "$_zshrc_part"
done
unset _zshrc_part

# Go setup
export GOPATH="$DEVHOME/go"
if [[ -a $GOPATH ]]; then
  export PATH="$PATH:$GOPATH/bin"
fi

# Elixir setup
export ERL_AFLAGS="-kernel shell_history enabled"

# node, python, ruby, java and npm CLIs, per config/mise/config.toml
if (command -v mise > /dev/null); then
  eval "$(mise activate zsh)"
fi

# Finally - allow a place per machine to override anything here in case some
# path is super specific on another machine
if [[ -a $HOME/.zshrc_local_overrides ]]; then
  source $HOME/.zshrc_local_overrides
fi

# Ensure shell starts with clean exit status
true
