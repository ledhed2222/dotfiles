# Change the prompt
export PS1="[\W]Bro? "

# Use vim for all editing
export EDITOR="vim"

# Alias common commands that are not already their own bin
# or for which we want to default options
alias top="top -o cpu -s 3 -stats pid,command,cpu,rprvt,rsize,vprvt,vsize,user,state,threads,ppid,pgrp,faults,cow"
alias clojure="java -cp clojure-1.7.0.jar clojure.main"
alias rm="rm -i"

# MacOS specific stuff
if [[ `uname` == "Darwin" ]]
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
	function exit {
		if [[ `ps -o tty | grep '[0-9]' | uniq | wc -l` -gt 1 ]]
		then
			builtin exit
		else
			osascript -e 'quit app "Terminal"'
		fi
	}
fi
# End MacOS specific stuff

# Common locations
export DEVHOME="$HOME/Documents/Dev"
export APACHEDIR="/etc/apache2" # virtual hosts in vhosts dir

# Binaries in /usr/local/bin take precedence over /usr/local
export PATH="/usr/local/bin:${PATH}"

# Go setup
export GOPATH=$HOME/Documents/Dev/go
export PATH=$PATH:$GOPATH/bin

# RVM setup
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

# Android setup
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# NVM setup
export NVM_DIR=$HOME/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

# Java setup
export JAVA_HOME=`/usr/libexec/java_home`
export JAVA_EXTENSION_PATH=$HOME/Library/Java/Extensions # Just to make it easy to remember where extensions are

# Git setup
source "/usr/local/etc/bash_completion.d/git-completion.bash"

