#!/bin/bash
# make.sh
# Creates symlinks from ~ to any desired dotfiles
dir=`pwd`
olddir=~/dotfiles_backup
# files in this repo that should NOT be symlinked into ~
# - claude: handled below, per-file, alongside the real ~/.claude
# - graft: this repo's own `graft build` output (like any repo's), not a
#   dotfile -- ~/.graft is graft the CLI's unrelated global state dir
#   (telemetry, update-check), and the two must never become the same path
# - gitconfig_darwin/linux: picked by platform below, not symlinked by name
# - npm-globals.txt: a manifest read by npm, not a dotfile
ignore=(make.sh README.md CLAUDE.md claude graft gitconfig_darwin gitconfig_linux npm-globals.txt)
ignore_pattern=$(IFS='|'; echo "^(${ignore[*]})$")
files=`ls | grep -Ev "$ignore_pattern"`

# Every install step below is skipped when it's already satisfied, so this
# stays cheap to re-run after editing a config file -- which is the normal
# reason to run it.

# oh my zsh has to come BEFORE the symlinks: zshrc depends on it, and its
# installer replaces an existing ~/.zshrc, testing with -h so it clobbers a
# symlink too. Running it after the loop below would undo the .zshrc link.
# --unattended keeps it from ending in `exec zsh -l` and taking this script
# down with it; it also suppresses the installer's own chsh, handled below.
if [ -d ~/.oh-my-zsh ]; then
	echo "oh my zsh already installed"
else
	echo "Installing oh my zsh"
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# chsh prompts for a password, so only when it would actually change something.
case "$SHELL" in
	*/zsh) ;;
	*) echo "Switching default shell to zsh"; chsh -s "$(which zsh)" ;;
esac

echo "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
echo "...done"

echo "Moving any existing dotfiles from ~ to $olddir"
for file in $files; do
	target=~/.$file
	# Only back up a REAL file: a symlink is either ours already or stale, and
	# replacing it loses nothing. Backing one up is actively harmful -- if
	# $olddir holds a same-named symlink to a directory from an earlier run,
	# mv follows it and moves the link INTO that directory, which is inside
	# this repo. That is how stray lein/lein and zsh/zsh appear.
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		mv "$target" "$olddir"
	fi
	echo "Creating symlink to $file in home directory"
	# -n so an existing symlink-to-directory is replaced, not written inside.
	ln -sfn "$dir/$file" "$target"
done

# Git has no OS conditional of its own -- includeIf only matches gitdir,
# onbranch and remote urls -- so the platform fragment gets picked here, at
# install time, and gitconfig includes ~/.gitconfig_os unconditionally.
os=`uname | tr '[:upper:]' '[:lower:]'`
if [ -f "$dir/gitconfig_$os" ]; then
	echo "Creating symlink to gitconfig_$os in home directory as .gitconfig_os"
	ln -sf "$dir/gitconfig_$os" ~/.gitconfig_os
else
	echo "No gitconfig_$os in this repo -- skipping ~/.gitconfig_os"
	rm -f ~/.gitconfig_os
fi

# ~/.claude mixes shared config with megabytes of local session state (history,
# credentials, plugin installs), so unlike every other top-level entry above,
# only these specific files/dirs are symlinked in -- the rest of ~/.claude stays
# real and local. Notably absent: helpers/graft-hooks.cjs, which `graft init`
# generates and overwrites in place per machine -- vendored, not ours to track.
echo "Symlinking shared claude/ config into ~/.claude"
mkdir -p ~/.claude
claude_files=(CLAUDE.md settings.json keybindings.json)
for file in "${claude_files[@]}"; do
	target=~/.claude/$file
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		mkdir -p "$olddir/claude/$(dirname "$file")"
		mv "$target" "$olddir/claude/$file"
	fi
	echo "Creating symlink to claude/$file in ~/.claude"
	ln -sf "$dir/claude/$file" "$target"
done

# Dependencies, from the two manifests. Both commands install only what's
# missing, so re-running costs a check and nothing else.
if command -v brew >/dev/null; then
	if brew bundle check --global >/dev/null 2>&1; then
		echo "Brewfile already satisfied"
	else
		echo "Installing from Brewfile"
		brew bundle --global
	fi
else
	echo "No brew on PATH -- skipping the Brewfile"
fi

if command -v npm >/dev/null; then
	echo "Installing npm globals from npm-globals.txt"
	grep -v '^#' "$dir/npm-globals.txt" | xargs npm i -g
	# nodenv puts a global's binary in the version's prefix but only exposes it
	# through a shim, so anything newly installed is missing from PATH until
	# this runs -- it looks like the install silently failed.
	if command -v nodenv >/dev/null; then
		nodenv rehash
	fi
else
	echo "No npm on PATH -- skipping npm-globals.txt"
fi

if command -v claude >/dev/null; then
	echo "claude code already installed"
else
	echo "Installing claude code"
	curl -fsSL https://claude.ai/install.sh | bash
fi

# Deliberately NOT run here: `graft init`. It rewrites the hook commands in the
# tracked claude/settings.json, replacing $HOME with this machine's absolute
# home path -- see CLAUDE.md. Running it on every make.sh would dirty the repo
# every time. Run it by hand once per machine, then put $HOME back.
if command -v graft >/dev/null && [ ! -f ~/.claude/helpers/graft-hooks.cjs ]; then
	echo "graft is installed but not wired up -- run 'graft init' once, then"
	echo "check 'git diff claude/settings.json' before committing (see CLAUDE.md)"
fi
