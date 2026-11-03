#!/bin/bash
# make.sh
# Creates symlinks from ~ to any desired dotfiles
dir=`pwd`
olddir=~/dotfiles_backup
# files in this repo that should NOT be symlinked into ~
# - claude: handled below, per-file, alongside the real ~/.claude
# - gitconfig_darwin/linux: picked by platform below, not symlinked by name
# - npm-globals.txt: a manifest read by npm, not a dotfile
ignore=(make.sh README.md CLAUDE.md claude gitconfig_darwin gitconfig_linux npm-globals.txt)
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

for file in $files; do
	target=~/.$file
	# Only back up a REAL file: a symlink is either ours already or stale, and
	# replacing it loses nothing. Backing one up is actively harmful -- if
	# $olddir holds a same-named symlink to a directory from an earlier run,
	# mv follows it and moves the link INTO that directory, which is inside
	# this repo, leaving strays like config/config or zsh/zsh. $olddir is
	# therefore created only when something real is actually being moved: on a
	# normal re-run nothing is, and an empty backup dir is just that trap
	# waiting for the next person to repopulate it by hand.
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		echo "Backing up real ~/.$file to $olddir"
		mkdir -p "$olddir"
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
# real and local. settings.json is not among them: it is generated, at the end.
echo "Symlinking shared claude/ config into ~/.claude"
mkdir -p ~/.claude
claude_files=(CLAUDE.md keybindings.json)
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

# ~/.claude/settings.json is the only user-scope settings file Claude Code reads,
# and every /plugin install, /model, /config and theme change writes to it. So
# it is generated, never symlinked: claude/settings.json (shared, tracked) deep-
# merged with ~/.claude/settings.machine.json (this machine only, untracked).
# Objects merge key by key, arrays concatenate, machine wins on a scalar.
#
# Claude's own writes land in the generated file. Overwriting it would silently
# undo them, so it is only rewritten while it still matches what was last
# generated (or already matches the new merge). Otherwise this prints what
# changed and leaves it alone: move each change into one of the two inputs,
# then re-run. /effort's per-session effortLevel is ignored in that comparison
# -- it is session state, not config -- and is dropped on the next rewrite.
claude_shared="$dir/claude/settings.json"
claude_machine=~/.claude/settings.machine.json
claude_live=~/.claude/settings.json
claude_last=~/.claude/.settings.generated.json
if command -v jq >/dev/null; then
	# the symlink this used to be points into the repo; never write through it
	[ -L "$claude_live" ] && rm "$claude_live"
	[ -f "$claude_machine" ] || echo '{}' > "$claude_machine"
	merged=$(jq -n --indent 2 --slurpfile shared "$claude_shared" --slurpfile machine "$claude_machine" '
		def merge($a; $b):
			if ($a | type) == "object" and ($b | type) == "object" then
				reduce ($b | keys_unsorted[]) as $k ($a; .[$k] = merge($a[$k]; $b[$k]))
			elif ($a | type) == "array" and ($b | type) == "array" then $a + ($b - $a)
			elif $b == null then $a
			else $b end;
		merge($shared[0]; $machine[0])') || exit 1
	normalise() {
		jq -S 'if .modelSettings then
			.modelSettings |= with_entries(.value |= del(.effortLevel))
			| .modelSettings |= with_entries(select(.value | length > 0))
			| (if (.modelSettings | length) == 0 then del(.modelSettings) else . end)
		else . end' "$@"
	}
	# Every leaf (arrays count as one, unordered) that Claude changed since the
	# last generation must already read the same in the new merge -- then
	# rewriting loses nothing, even when the inputs changed too.
	absorbed() {
		jq -n -e --slurpfile last <(normalise "$claude_last") --slurpfile live <(normalise "$claude_live") \
			--slurpfile merged <(echo "$merged" | normalise) '
			def leaves: if type == "object" then (keys[] as $k | (.[$k] | leaves) as $p | [$k] + $p) else [] end;
			def at($p): getpath($p) | if type == "array" then sort else . end;
			$last[0] as $a | $live[0] as $b | $merged[0] as $m
			| [($a, $b) | leaves] | unique
			| map(. as $p | select(($a | at($p)) != ($b | at($p))))
			| all(.[]; . as $p | ($m | at($p)) == ($b | at($p)))' >/dev/null
	}
	if [ ! -f "$claude_live" ] \
		|| [ "$(normalise "$claude_live")" = "$(echo "$merged" | normalise)" ] \
		|| { [ -f "$claude_last" ] && absorbed; }; then
		echo "Generating ~/.claude/settings.json from claude/settings.json + settings.machine.json"
		echo "$merged" > "$claude_live"
		echo "$merged" > "$claude_last"
	else
		echo "~/.claude/settings.json has changes from neither input -- leaving it alone:"
		if [ -f "$claude_last" ]; then
			diff <(normalise "$claude_last") <(normalise "$claude_live")
		else
			diff <(echo "$merged" | normalise) <(normalise "$claude_live")
		fi
		echo "Move each one into claude/settings.json (every machine) or"
		echo "~/.claude/settings.machine.json (this one), then re-run ./make.sh."
	fi
else
	echo "No jq on PATH -- skipping ~/.claude/settings.json"
fi
