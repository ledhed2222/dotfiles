# Git worktree + tmux session management.
#
#   wt new [-l layout] <branch>   branch off origin's default branch, open a session, switch to it
#   wt open [-l layout] [branch]  open (or jump to) the session for an existing worktree
#   wt close [branch]             remove the worktree, delete the branch, kill the session
#   wt ls                         list worktrees, marking the ones with a live session
#
# open and close take an exact branch, a fuzzy fragment, or no argument at all —
# anything short of an exact match goes through fzf.
#
# Worktrees live in $WORKTREE_HOME/<repo>/<branch-suffix>. Sessions are named
# after the branch suffix.
#
# A repo selects its tmuxinator layout with `git config wt.layout <name>`,
# resolved against ~/.config/tmuxinator/<name>.yml. Repos without one get
# `default`. Local git config lives in .git/config, so it never gets committed
# to a shared repo and needs no .gitignore entry, and every worktree of the repo
# reads the same value (worktrees share the common config file). Setting it in
# --global makes a personal default for every repo. -l overrides it for a single
# invocation.

export WORKTREE_HOME="${WORKTREE_HOME:-$HOME/worktrees}"

_wt_repo_name() {
  local dir=${1:-.} url
  url=$(git -C "$dir" remote get-url origin 2>/dev/null)
  if [[ -n $url ]]; then
    basename "${url%.git}"
  else
    basename "$(git -C "$dir" rev-parse --show-toplevel)"
  fi
}

_wt_layout() {
  local name
  name=$(git -C "$1" config --get wt.layout 2>/dev/null)
  print -- "${name:-default}"
}

_wt_default_branch() {
  local ref
  if ref=$(git symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null); then
    print -- "${ref##*/}"
  else
    git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}'
  fi
}

# "<branch>\t<path>" per worktree. Branch first so it leads in the fzf picker
# and lands in field 1 for --nth.
_wt_list() {
  git worktree list --porcelain | awk '
    /^worktree /  { path = substr($0, 10); branch = "(detached)" }
    /^branch /    { branch = substr($0, 8); sub(/^refs\/heads\//, "", branch) }
    /^$/          { if (path != "") print branch "\t" path; path = "" }
    END           { if (path != "") print branch "\t" path }
  '
}

# Exact match against full branch, branch suffix, or directory name
_wt_find() {
  _wt_list | awk -F'\t' -v q="$1" '
    { suffix = $1; sub(/.*\//, "", suffix); leaf = $2; sub(/.*\//, "", leaf) }
    $1 == q || suffix == q || leaf == q { print; exit }
  '
}

# Pick a worktree: an exact match wins outright, anything else seeds an fzf
# filter (so `wt open pl1a` finds plat-1-alpha, and no argument lists them all).
# $3 auto-accepts a unique fuzzy hit — `close` leaves it unset so a typo can
# never resolve straight into deleting a worktree you didn't mean.
_wt_resolve() {
  local query=$1 prompt=$2 autoselect=$3 sel rc
  if [[ -n $query ]]; then
    sel=$(_wt_find "$query")
    [[ -n $sel ]] && { print -- "$sel"; return 0 }
  fi

  if ! (( $+commands[fzf] )); then
    print -u2 "wt: no worktree matching '$query' (install fzf to match fuzzily)"
    return 1
  fi

  # --nth=1 matches on the branch alone. The path still shows, but searching it
  # too would let a long worktree path manufacture matches of its own. (Don't
  # reach for --with-nth here: it concatenates fields with no separator, which
  # both mangles the display and collapses everything into one field.)
  local -a opts
  opts=(--delimiter='\t' --nth=1 --height=40% --reverse
        --prompt="$prompt " --query="$query" --exit-0)
  [[ -n $autoselect ]] && opts+=(--select-1)

  sel=$(_wt_list | fzf "${opts[@]}")
  rc=$?
  case $rc in
    0)   ;;
    1)   print -u2 "wt: no worktree matching '$query'"; return 1 ;;
    130) return 1 ;;  # backed out on purpose, nothing to say
    *)   print -u2 "wt: fzf exited with status $rc"; return 1 ;;
  esac
  print -- "$sel"
}

_wt_goto() {
  if [[ -n $TMUX ]]; then
    tmux switch-client -t "=$1"
  else
    tmux attach -t "=$1"
  fi
}

# Note: `path` is tied to $PATH in zsh, so worktree paths are always held in
# `dir` — a `local path` would blank out the command search path.
_wt_session() {
  local dir=$1 session=$2 layout=$3
  if tmux has-session -t "=$session" 2>/dev/null; then
    return 0
  fi
  if ! (( $+commands[tmuxinator] )); then
    print -u2 "wt: tmuxinator is not installed"
    return 1
  fi
  # Resolve against the target worktree, not $PWD — `wt open` is often run from
  # a different repo than the one being opened.
  [[ -z $layout ]] && layout=$(_wt_layout "$dir")
  PROJECT_ROOT="$dir" PROJECT_NAME="$session" tmuxinator start "$layout" -a false || return 1

  # A layout that hardcodes `name:` rather than reading PROJECT_NAME starts a
  # session under the wrong name and still exits 0, so the failure only shows up
  # later as a baffling "can't find session" from tmux.
  if ! tmux has-session -t "=$session" 2>/dev/null; then
    print -u2 "wt: layout '$layout' started no session named '$session'"
    print -u2 "wt: its name:/root: must read PROJECT_NAME/PROJECT_ROOT (see default.yml)"
    return 1
  fi
}

# Strips a leading -l/--layout from $@; caller reads $REPLY and shifts $wt_optshift
_wt_parse_layout() {
  REPLY=""
  wt_optshift=0
  while [[ $1 == -* ]]; do
    case $1 in
      -l|--layout)
        REPLY=$2
        [[ -z $REPLY ]] && { print -u2 "wt: -l needs a layout name"; return 1 }
        shift 2
        (( wt_optshift += 2 ))
        ;;
      *)
        print -u2 "wt: unknown option $1"
        return 1
        ;;
    esac
  done
  return 0
}

_wt_new() {
  local layout wt_optshift
  _wt_parse_layout "$@" || return 1
  layout=$REPLY
  shift $wt_optshift

  local branch=$1
  if [[ -z $branch ]]; then
    print -u2 "usage: wt new [-l layout] <branch>"
    return 1
  fi
  git rev-parse --git-dir >/dev/null 2>&1 || { print -u2 "wt: not in a git repo"; return 1 }

  local repo suffix base dir
  repo=$(_wt_repo_name)
  suffix=${branch##*/}
  base=$(_wt_default_branch)
  dir="$WORKTREE_HOME/$repo/$suffix"

  git fetch --quiet origin "$base" || return 1
  mkdir -p "$WORKTREE_HOME/$repo"

  # Branch straight off the freshly fetched remote head so the current checkout
  # is never touched — no stashing or switching branches first.
  git worktree add -b "$branch" "$dir" "origin/$base" || return 1

  _wt_session "$dir" "$suffix" "$layout" || return 1
  _wt_goto "$suffix"
}

_wt_open() {
  local layout wt_optshift
  _wt_parse_layout "$@" || return 1
  layout=$REPLY
  shift $wt_optshift

  local sel dir branch
  sel=$(_wt_resolve "$1" "open>" autoselect) || return 1

  branch=${sel%%$'\t'*}
  dir=${sel##*$'\t'}
  [[ -d $dir ]] || { print -u2 "wt: $dir no longer exists"; return 1 }

  _wt_session "$dir" "${branch##*/}" "$layout" || return 1
  _wt_goto "${branch##*/}"
}

_wt_close() {
  local sel dir branch base force_branch=0
  sel=$(_wt_resolve "$1" "close>") || return 1

  branch=${sel%%$'\t'*}
  dir=${sel##*$'\t'}
  base=$(_wt_default_branch)

  local main_root
  main_root=$(_wt_list | head -1 | cut -f2)
  if [[ $dir == $main_root ]]; then
    print -u2 "wt: refusing to close the main worktree"
    return 1
  fi

  # Squash-merged branches still look unmerged by ancestry, so this is a
  # confirmation rather than a hard stop.
  if ! git merge-base --is-ancestor "$branch" "origin/$base" 2>/dev/null; then
    print -n "wt: $branch is not merged into origin/$base. Delete anyway? [y/N] "
    if ! read -q; then
      print ""
      return 1
    fi
    print ""
    force_branch=1
  fi

  # Never sit inside the directory being removed
  [[ $PWD/ == $dir/* ]] && cd "$main_root"

  local err
  if ! err=$(git worktree remove "$dir" 2>&1); then
    print -u2 "wt: $err"
    print -n "wt: force remove $dir? [y/N] "
    if ! read -q; then
      print ""
      return 1
    fi
    print ""
    git worktree remove --force "$dir" || return 1
  fi

  if (( force_branch )); then
    git branch -D "$branch"
  else
    git branch -d "$branch"
  fi

  # Last, so killing our own session doesn't cut the function short
  tmux kill-session -t "=${branch##*/}" 2>/dev/null

  print "wt: closed $branch"
}

_wt_ls() {
  local dir branch mark
  _wt_list | while IFS=$'\t' read -r branch dir; do
    if tmux has-session -t "=${branch##*/}" 2>/dev/null; then
      mark="●"
    else
      mark=" "
    fi
    printf "%s %-45s %s\n" "$mark" "$branch" "$dir"
  done
}

function wt {
  local cmd=${1:-ls}
  (( $# )) && shift
  case $cmd in
    new|n)          _wt_new "$@" ;;
    open|o|connect) _wt_open "$@" ;;
    close|rm)       _wt_close "$@" ;;
    ls|list)        _wt_ls ;;
    *)              print -u2 "usage: wt {new [-l layout] <branch>|open [-l layout] [branch]|close [branch]|ls}"; return 1 ;;
  esac
}

# Completion. Without it zsh falls back to filenames, so `wt open <TAB>` offers
# the files in the repo — never a valid argument. open and close complete
# existing worktrees; every other position deliberately completes nothing rather
# than reverting to files. fzf still does the fuzzy matching at runtime.
_wt_comp_worktrees() {
  local -a branches
  branches=(${(f)"$(_wt_list 2>/dev/null | cut -f1)"})
  # -Q since branch names contain slashes that would otherwise be quoted
  _describe -t worktrees 'worktree' branches -Q
}

_wt() {
  local -a subcommands layout_opt
  subcommands=(
    'new:branch off origin default, open a session, switch to it'
    'open:open (or jump to) the session for an existing worktree'
    'close:remove the worktree, delete the branch, kill the session'
    'ls:list worktrees, marking the ones with a live session'
  )
  # Recognised so `-l` doesn't fall through to filenames; its value is a layout
  # name you can list with `mux ls`, so nothing is offered for it.
  layout_opt=('(-l --layout)'{-l,--layout}'[tmuxinator layout]:layout: ')

  local curcontext=$curcontext state line
  _arguments -C '1: :->cmd' '*:: :->args'

  case $state in
    cmd)
      _describe -t commands 'wt command' subcommands
      ;;
    args)
      case $words[1] in
        new|n)          _arguments $layout_opt ;;
        open|o|connect) _arguments $layout_opt '1:worktree:_wt_comp_worktrees' ;;
        close|rm)       _arguments '1:worktree:_wt_comp_worktrees' ;;
      esac
      ;;
  esac
}

# Guarded so this file still sources cleanly in a non-interactive shell, where
# compinit hasn't run and compdef doesn't exist. An `if` rather than `&&` so
# sourcing the file doesn't come back non-zero when the guard is false.
if (( $+functions[compdef] )); then
  compdef _wt wt
fi

# zsh bells on an ambiguous completion and on no match, both by way of the
# completion widget returning non-zero — and there's no per-command option for
# it. LIST_BEEP's documented escape hatch is a user-defined widget, so wrap Tab
# and swallow the status only when the line starts with `wt`, leaving the bell
# intact for every other command. This sources after fzf's completion.zsh, so
# the wrapped widget is whatever Tab actually ended up bound to.
if [[ -o interactive ]] && (( $+functions[compdef] )); then
  _wt_tab_target=${${(z)$(bindkey '^I')}[2]}
  if [[ -n $_wt_tab_target && $_wt_tab_target != _wt_tab ]]; then
    _wt_tab() {
      zle "$_wt_tab_target"
      local ret=$?
      # Assigned to an array first: (z) on a one-word line yields a scalar, and
      # subscripting that would take the first character rather than the word.
      local -a first
      first=(${(z)LBUFFER})
      [[ $first[1] == wt ]] && return 0
      return $ret
    }
    zle -N _wt_tab
    bindkey '^I' _wt_tab
    bindkey -M viins '^I' _wt_tab
  fi
fi
