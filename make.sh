#!/bin/bash
# .make.sh
# Creates symlinks from ~ to any desired dotfiles

dir=`pwd`
olddir=~/dotfiles_backup
files="bash_profile vimrc"

echo "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
echo "...done"

for file in $files
do
	echo "Moving any existing dotfiles from ~ to $olddir"
	mv ~/.$file $olddir
	echo "Creating symlink to $file in home directory"
	ln -s $dir/$file ~/.$file
done

