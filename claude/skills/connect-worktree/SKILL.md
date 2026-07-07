---
name: connect-worktree
description: Open an existing git worktree in a new tmuxinator dev session. Use when the user wants to connect to, attach to, or open a tmux session for an existing worktree. Triggers: connect worktree, open worktree, attach worktree, /connect-worktree, switch to worktree, open tmux for branch.
---

# connect-worktree

Opens an existing git worktree in a new dedicated tmuxinator `dev` session.

## What it does

1. Determines the worktree to connect to (from args or by listing available worktrees)
2. Derives the worktree path and session name from the branch
3. Launches `tmuxinator start` with that worktree as root, detached

## Instructions

When this skill is invoked:

### Step 1: Get the target worktree

If args were passed to the skill invocation, treat them as the branch name (full or suffix) to connect to.

If no args were provided, list existing worktrees:

```bash
git worktree list
```

Show the user the available worktrees (excluding the main one, i.e., not on `master`/`main`) and ask which one to open.

### Step 2: Derive names

- **Branch name**: the branch checked out in the target worktree (from `git worktree list` output or the args)
- **Branch suffix**: everything after the last `/` in the branch name. If there's no `/`, use the full name.
  - e.g., `gregweisbrod/plat-1234-my-feature` → `plat-1234-my-feature`
- **Worktree path**: read directly from `git worktree list` output — use the actual path on disk, do not construct it
- **Tmux session name**: the branch suffix

### Step 3: Verify the worktree exists

Check that the path from `git worktree list` exists on disk:

```bash
ls <worktree-path>
```

If it doesn't exist, tell the user and stop.

### Step 4: Launch the tmuxinator session

Write a temp config and launch it detached:

```bash
WORKTREE_PATH="<worktree-path>"
SESSION_NAME="<branch-suffix>"
TMP_CONFIG="/tmp/tmuxinator-${SESSION_NAME}.yml"

cat > "$TMP_CONFIG" << EOF
name: $SESSION_NAME
root: $WORKTREE_PATH

startup_window: vi

windows:
  - vi:
      root: $WORKTREE_PATH
      panes:
        - nvim
  - ai:
      root: $WORKTREE_PATH
      panes:
        - claude
  - zsh:
      root: $WORKTREE_PATH
      panes:
        - zsh
EOF

tmuxinator start -p "$TMP_CONFIG" -a false
```

The `-a false` flag prevents tmuxinator from attaching, keeping the session alive in the background.

If a tmux session with that name already exists, tell the user — they can switch to it directly without relaunching.

### Step 5: Report to the user

Tell the user:
- The worktree path
- The tmux session name
- How to switch to it: `tmux switch-client -t <branch-suffix>` (or `Ctrl+b $` to pick interactively)

## Example

Invocation: `/connect-worktree plat-5678-auth-refactor`

- Looks up `plat-5678-auth-refactor` in `git worktree list`
- Worktree path: whatever path `git worktree list` shows (e.g., `~/worktrees/anchorage/plat-5678-auth-refactor`)
- Branch suffix / session name: `plat-5678-auth-refactor`
- Temp config written to `/tmp/tmuxinator-plat-5678-auth-refactor.yml`
- Command run: `tmuxinator start -p /tmp/tmuxinator-plat-5678-auth-refactor.yml -a false`
- User told: switch with `tmux switch-client -t plat-5678-auth-refactor`
