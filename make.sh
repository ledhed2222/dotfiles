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
ignore=(make.sh README.md CLAUDE.md claude graft)
ignore_pattern=$(IFS='|'; echo "^(${ignore[*]})$")
files=`ls | grep -Ev "$ignore_pattern"`

echo "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
echo "...done"

echo "Moving any existing dotfiles from ~ to $olddir"
for file in $files
do
	mv ~/.$file $olddir
	echo "Creating symlink to $file in home directory"
	ln -s $dir/$file ~/.$file
done

# ~/.claude mixes shared config with megabytes of local session state (history,
# credentials, plugin installs), so unlike every other top-level entry above,
# only these specific files/dirs are symlinked in -- the rest of ~/.claude stays
# real and local.
echo "Symlinking shared claude/ config into ~/.claude"
mkdir -p ~/.claude/helpers
claude_files=(CLAUDE.md settings.json keybindings.json skills helpers/graft-hooks.cjs)
for file in "${claude_files[@]}"
do
	target=~/.claude/$file
	if [ -e "$target" ] && [ ! -L "$target" ]
	then
		mkdir -p "$olddir/claude/$(dirname "$file")"
		mv "$target" "$olddir/claude/$file"
	fi
	echo "Creating symlink to claude/$file in ~/.claude"
	ln -sf "$dir/claude/$file" "$target"
done
