Create a new git worktree for branch `$ARGUMENTS` by running these steps in order:

1. Detect the default branch:
   ```
   git remote show origin | grep 'HEAD branch' | awk '{print $NF}'
   ```

2. Switch to the default branch and pull latest:
   ```
   git checkout <default-branch> && git pull
   ```

3. Get the repo name:
   ```
   basename $(git rev-parse --show-toplevel)
   ```

4. Set the worktree path:
   ```
   ${DEVHOME:-$HOME/Dev}/worktrees/<reponame>/$ARGUMENTS
   ```

5. Create the directory and worktree:
   ```
   mkdir -p <worktree-path>
   git worktree add <worktree-path> -b $ARGUMENTS <default-branch>
   ```
   If the branch already exists locally, omit `-b`.

6. Start a new tmuxinator session rooted at the worktree without attaching (leaves the current session unchanged):
   ```
   PROJECT_ROOT=<worktree-path> PROJECT_NAME=$ARGUMENTS mux start default --no-attach
   ```
