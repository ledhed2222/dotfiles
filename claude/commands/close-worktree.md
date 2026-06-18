Close the worktree, tmux session, and branch for `$ARGUMENTS` by following these steps in order:

1. Get the repo name:
   ```
   basename $(git rev-parse --show-toplevel)
   ```

2. Detect the default branch:
   ```
   git remote show origin | grep 'HEAD branch' | awk '{print $NF}'
   ```

3. Check if the branch is merged into the default branch:
   ```
   git branch --merged <default-branch> | grep -w $ARGUMENTS
   ```
   If the branch is NOT merged, stop and ask the user: "Branch `$ARGUMENTS` has not been merged into `<default-branch>`. Continue closing and deleting it?"
   Do not proceed until the user confirms.

4. Remove the worktree (force in case of untracked files):
   ```
   git worktree remove --force ${DEVHOME:-$HOME/Dev}/worktrees/<reponame>/$ARGUMENTS
   ```

5. Delete the branch:
   - If merged: `git branch -d $ARGUMENTS`
   - If unmerged but user confirmed: `git branch -D $ARGUMENTS`

6. Kill the tmux session:
   ```
   tmux kill-session -t $ARGUMENTS
   ```
   If the session doesn't exist, continue without error.
