#!/bin/bash
# make.sh
# Creates symlinks from ~ to any desired dotfiles
dir=`pwd`
olddir=~/dotfiles_backup
files=`ls | grep "[^make\.sh|README\.md]"`

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

