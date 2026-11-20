#!/bin/bash
# make.sh
# Creates symlinks from ~ to any desired dotfiles
dir=`pwd`
olddir=~/dotfiles_backup
# files in this repo that should NOT be symlinked into ~
# - claude: handled below, per-file, alongside the real ~/.claude
# - config: handled below, per-directory, inside a real ~/.config
# - gitconfig_darwin/linux: picked by platform below, not symlinked by name
# - zsh: zshrc sources zsh/*.zsh from this repo directly, by its own real path
ignore=(make.sh README.md CLAUDE.md claude config gitconfig_darwin gitconfig_linux zsh)
ignore_pattern=$(IFS='|'; echo "^(${ignore[*]})$")
# tracked entries only, so a scratch file in the checkout never becomes ~/.<name>;
# the repo's own dotfiles (.gitignore) are repo config, not dotfiles to link
files=`git -C "$dir" ls-files | cut -d/ -f1 | sort -u | grep -v '^\.' | grep -Ev "$ignore_pattern"`

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

# A file deleted from the repo leaves its link dangling wherever it was linked
# to. Clear those -- only links into this repo, so nothing else is touched.
for link in ~/.[!.]* ~/.config/* ~/.claude/* ~/.claude/skills/*; do
	if [ -L "$link" ] && [ ! -e "$link" ] && [[ "$(readlink "$link")" == "$dir"/* ]]; then
		echo "Removing dangling link $link"
		rm "$link"
	fi
done
# ~/.zsh linked to zsh/ before zsh/ was taken off the link list
[ -L ~/.zsh ] && [ "$(readlink ~/.zsh)" = "$dir/zsh" ] && rm ~/.zsh

# ~/.config is where every app writes its state, so it is a real directory and
# only the tracked config/<dir>s are symlinked into it. It used to be one symlink
# to config/, which put every app's state -- gh's login, 1Password -- inside
# this working tree. Undo that once: whatever is in config/ but untracked was
# written through the old link and belongs to its app, so it moves out.
if [ -L ~/.config ]; then
	echo "Replacing the ~/.config symlink with a real directory"
	rm ~/.config
	mkdir ~/.config
	shopt -s nullglob dotglob
	for entry in "$dir"/config/*; do
		name=$(basename "$entry")
		if [ -z "$(git -C "$dir" ls-files -- "config/$name")" ]; then
			echo "Moving untracked config/$name out to ~/.config"
			# an app that is running can recreate its dir first; never clobber it
			mv "$entry" ~/.config/ || echo "WARNING: config/$name is still in the repo -- quit its app, merge it into ~/.config/$name by hand"
		fi
	done
	shopt -u nullglob dotglob
fi
mkdir -p ~/.config
for entry in "$dir"/config/*/; do
	name=$(basename "$entry")
	# only shared config: an untracked dir here is app state that failed to move
	[ -n "$(git -C "$dir" ls-files -- "config/$name")" ] || continue
	target=~/.config/$name
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		echo "Backing up real ~/.config/$name to $olddir/config"
		mkdir -p "$olddir/config"
		mv "$target" "$olddir/config/"
	fi
	echo "Creating symlink to config/$name in ~/.config"
	ln -sfn "$dir/config/$name" "$target"
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

# Skills link one by one, like config/: ~/.claude/skills also holds skills that
# plugins and work tooling install, which stay real and local to this machine.
mkdir -p ~/.claude/skills
for entry in "$dir"/claude/skills/*/; do
	name=$(basename "$entry")
	target=~/.claude/skills/$name
	if [ -e "$target" ] && [ ! -L "$target" ]; then
		echo "Backing up real ~/.claude/skills/$name to $olddir/claude/skills"
		mkdir -p "$olddir/claude/skills"
		mv "$target" "$olddir/claude/skills/"
	fi
	echo "Creating symlink to claude/skills/$name in ~/.claude/skills"
	ln -sfn "$dir/claude/skills/$name" "$target"
done

# Directories the shell config only ever reads. zshrc exports these as common
# locations, and adds $GOPATH/bin to PATH *only when GOPATH exists* -- so on a
# machine where it doesn't, a `go install` lands somewhere not on PATH and the
# binary looks like it failed to build. The paths are read out of zshrc rather
# than repeated here: they are plain assignments that bash evaluates the same
# way zsh does, so this can't drift from the values the shell actually uses.
eval "$(grep -E '^export (DEVHOME|WORKHOME|GOPATH)=' "$dir/zshrc")"
eval "$(grep -E '^export WORKTREE_HOME=' "$dir/zsh/worktree.zsh")"
for d in "$DEVHOME" "$WORKHOME" "$GOPATH" "$WORKTREE_HOME"; do
	if [ -z "$d" ] || [ -d "$d" ]; then
		continue
	fi
	echo "Creating $d"
	mkdir -p "$d"
done

# Dependencies, from the Brewfile and the mise config. Both install only what's
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

# Languages and npm CLIs, from config/mise/config.toml (linked into ~/.config
# above). Installs only what's missing, like the Brewfile.
if command -v mise >/dev/null; then
	echo "Installing global tools from config/mise/config.toml"
	mise install --yes
else
	echo "No mise on PATH -- skipping config/mise/config.toml"
fi

# Retired by mise: the per-language managers. Their formulae go once mise is
# here to take over; their state dirs go only when they hold no versions --
# anything installed there needs porting to config/mise/config.toml first.
if command -v mise >/dev/null; then
	for manager in jenv nodenv pyenv rbenv; do
		if command -v brew >/dev/null && brew list --formula "$manager" >/dev/null 2>&1; then
			echo "Uninstalling $manager (replaced by mise)"
			brew uninstall "$manager"
		fi
		state=~/.$manager
		[ -d "$state" ] || continue
		versions=$(ls -A "$state/versions" 2>/dev/null)
		if [ -z "$versions" ]; then
			echo "Removing $state (no versions installed)"
			rm -rf "$state"
		else
			echo "WARNING: $state still has versions: $(echo $versions) -- add what you need via mise use -g, then rm -rf $state"
		fi
	done
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
	# Every leaf (arrays count as one, unordered) that changed in the live file
	# since the last generation must already read the same in the new merge --
	# then rewriting loses nothing, even when the inputs changed too. Prints one
	# line per leaf that doesn't; empty output means safe to rewrite.
	conflicts() {
		jq -n -r --slurpfile last <(normalise "$claude_last") --slurpfile live <(normalise "$claude_live") \
			--slurpfile merged <(echo "$merged" | normalise) \
			--slurpfile shared "$claude_shared" --slurpfile machine "$claude_machine" '
			def leaves: if type == "object" then (keys[] as $k | (.[$k] | leaves) as $p | [$k] + $p) else [] end;
			def at($p): getpath($p) | if type == "array" then sort else . end;
			def show: if . == null then "(unset)" else tojson end;
			$last[0] as $a | $live[0] as $b | $merged[0] as $m
			| [($a, $b) | leaves] | unique[]
			| . as $p
			| select(($a | at($p)) != ($b | at($p)) and ($m | at($p)) != ($b | at($p)))
			| (if ($machine[0] | getpath($p)) != null then "~/.claude/settings.machine.json"
				elif ($shared[0] | getpath($p)) != null then "claude/settings.json"
				else "neither input" end) as $src
			| "  \($p | join(".")): inputs say \($m | getpath($p) | show) (\($src)), live file says \($b | getpath($p) | show)"'
	}
	if [ -f "$claude_live" ] && [ -f "$claude_last" ]; then
		conflicting=$(conflicts) || exit 1
	fi
	if [ ! -f "$claude_live" ] \
		|| [ "$(normalise "$claude_live")" = "$(echo "$merged" | normalise)" ] \
		|| { [ -f "$claude_last" ] && [ -z "$conflicting" ]; }; then
		echo "Generating ~/.claude/settings.json from claude/settings.json + settings.machine.json"
		echo "$merged" > "$claude_live"
		echo "$merged" > "$claude_last"
	else
		settings_blocked=1
		{
			if [ -f "$claude_last" ]; then
				echo "WARNING: ~/.claude/settings.json NOT regenerated. Since make.sh last wrote it,"
				echo "it was edited (by Claude Code or by hand), and these keys now disagree with the inputs:"
				echo "$conflicting"
				echo "For each key, make the two agree: edit the input to match the live file, or"
				echo "edit the live file to match the input (rm ~/.claude/settings.json takes the"
				echo "inputs for every key). Then re-run ./make.sh."
			else
				echo "WARNING: ~/.claude/settings.json NOT regenerated: there is no record of the last"
				echo "generation, so it can't tell whose changes these are (< inputs, > live file):"
				diff <(echo "$merged" | normalise) <(normalise "$claude_live")
				echo "Make the live file match, or rm ~/.claude/settings.json to take the inputs. Then re-run ./make.sh."
			fi
		} >&2
	fi
else
	echo "No jq on PATH -- skipping ~/.claude/settings.json"
fi

# what's installed by hand but not in the Brewfile; also runnable as brew-audit
if command -v brew >/dev/null; then
	source "$dir/zsh/brew-audit.zsh"
	brew-audit
fi

[ -z "$settings_blocked" ] || exit 1
