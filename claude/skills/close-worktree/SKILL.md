---
name: close-worktree
description: Remove a git worktree, delete its branch, and kill its tmux session. Use whenever the user wants to close, remove, tear down, or clean up a worktree and its associated branch/session. Triggers: close worktree, remove worktree, tear down worktree, /close-worktree, delete branch and worktree, clean up worktree.
---

# close-worktree

Removes a git worktree, deletes its branch, and kills the dedicated tmux session for it — the counterpart to `new-worktree`.

## What it does

1. Determines the branch name (from args or by prompting)
2. Detects the current repo name from the git remote or directory name
3. Checks whether the branch has been merged into the default branch, prompting for confirmation if not
4. Removes the worktree
5. Deletes the branch
6. Kills the tmux session

## Instructions

When this skill is invoked:

### Step 1: Get the branch name

If args were passed to the skill invocation, use that verbatim as the full branch name. Otherwise ask: "Which branch's worktree should I close?"

### Step 2: Derive names

- **Branch suffix**: everything after the last `/` in the branch name (matches how `new-worktree`/`connect-worktree` name things).
  - e.g., `gregweisbrod/plat-1234-my-feature` → `plat-1234-my-feature`
- **Repo name**: run `git remote get-url origin` and extract the repo name from the URL, or fall back to the name of the git root directory.
- **Worktree path**: `~/worktrees/<repo-name>/<branch-suffix>`
- **Tmux session name**: the branch suffix

### Step 3: Detect the default branch and check merge status

```bash
git remote show origin | grep 'HEAD branch' | awk '{print $NF}'
```

Then:

```bash
git branch --merged <default-branch> | grep -w <full-branch-name>
```

If the branch is **not** merged, stop and ask the user: "Branch `<full-branch-name>` has not been merged into `<default-branch>`. Continue closing and deleting it?" Do not proceed until they confirm.

### Step 4: Remove the worktree

```bash
git worktree remove --force ~/worktrees/<repo-name>/<branch-suffix>
```

If the worktree path doesn't exist, tell the user and skip to Step 6 (the branch/session may still need cleanup).

### Step 5: Delete the branch

- If merged: `git branch -d <full-branch-name>`
- If unmerged but the user confirmed in Step 3: `git branch -D <full-branch-name>`

### Step 6: Kill the tmux session

```bash
tmux kill-session -t <branch-suffix>
```

If the session doesn't exist, continue without error — don't treat it as a failure.

### Step 7: Report to the user

Confirm what was removed: the worktree path, the branch, and the tmux session name.

## Example

Invocation: `/close-worktree gregweisbrod/plat-5678-auth-refactor`

- Branch suffix / session name: `plat-5678-auth-refactor`
- Worktree path: `~/worktrees/anchorage/plat-5678-auth-refactor`
- If merged into master: `git branch -d gregweisbrod/plat-5678-auth-refactor`
- Tmux session `plat-5678-auth-refactor` killed
