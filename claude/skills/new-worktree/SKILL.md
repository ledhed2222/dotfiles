---
name: new-worktree
description: Create a new git worktree on a fresh branch off master, then open it in a new tmux session using tmuxinator. Use whenever the user wants to start work on a new branch, create a worktree, spin up a new dev session, or work on multiple branches simultaneously. Triggers: new worktree, new branch, /new-worktree, start a new branch, spin up a branch, new tmux session for a branch.
---

# new-worktree

Creates a new git worktree branched off master, then launches a dedicated tmuxinator `dev` session for it.

## What it does

1. Determines the branch name (from args or by prompting)
2. Detects the current repo name from the git remote or directory name
3. Fetches and pulls latest master
4. Creates a new worktree at `~/worktrees/<repo-name>/<branch-suffix>/`
5. Creates and checks out the new branch in that worktree
6. Launches `tmuxinator start dev` with the worktree as root and a session named after the branch suffix

## Instructions

When this skill is invoked:

### Step 1: Get the branch name

If args were passed to the skill invocation, use that verbatim as the full branch name. Do not add any prefix — use exactly what was passed (e.g., `fconnect-read-replica` or `gregweisbrod/plat-1234-my-feature`).

If no args were provided, ask the user: "What should the branch be called?"

### Step 2: Derive names

- **Branch suffix**: everything after the last `/` in the branch name. If there's no `/`, use the full name.
  - e.g., `gregweisbrod/plat-1234-my-feature` → `plat-1234-my-feature`
- **Repo name**: run `git remote get-url origin` and extract the repo name from the URL, or fall back to the name of the git root directory.
- **Worktree path**: `~/worktrees/<repo-name>/<branch-suffix>`
- **Tmux session name**: the branch suffix

### Step 3: Fetch and pull master

Run these from the current repo root (not the worktree):

```bash
git fetch origin
git checkout master
git pull origin master
```

If `git checkout master` fails (e.g., there are uncommitted changes), warn the user and stop — don't force anything.

### Step 4: Create the worktree and branch

```bash
mkdir -p ~/worktrees/<repo-name>
git worktree add ~/worktrees/<repo-name>/<branch-suffix> -b <full-branch-name>
```

If the worktree path already exists, tell the user and stop.
If the branch already exists, tell the user and stop.

### Step 5: Launch the tmuxinator session

Tmuxinator doesn't support overriding `root` via CLI args, and `--no-attach` doesn't reliably keep the session alive when run from Claude's shell. Instead, write a temp config and launch it detached via `tmux new-session`:

```bash
WORKTREE_PATH="$HOME/worktrees/<repo-name>/<branch-suffix>"
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

# Start detached — tmuxinator attach behavior is unreliable from Claude's shell
# Per-window root is required because top-level root alone is not reliably applied
tmuxinator start -p "$TMP_CONFIG" -a false
```

The `-a false` flag prevents tmuxinator from attaching, keeping the session alive in the background regardless of Claude's shell lifecycle.

### Step 6: Report to the user

Tell the user:
- The worktree path
- The tmux session name
- How to switch to it: `tmux switch-client -t <branch-suffix>` (or `Ctrl+b $` to pick interactively)

## Example

Invocation: `/new-worktree gregweisbrod/plat-5678-auth-refactor`

- Branch name: `gregweisbrod/plat-5678-auth-refactor`
- Branch suffix / session name: `plat-5678-auth-refactor`
- Worktree path: `~/worktrees/anchorage/plat-5678-auth-refactor`
- Temp config written to `/tmp/tmuxinator-plat-5678-auth-refactor.yml`
- Command run: `tmuxinator start -p /tmp/tmuxinator-plat-5678-auth-refactor.yml -a false`
- User told: switch with `tmux switch-client -t plat-5678-auth-refactor`
