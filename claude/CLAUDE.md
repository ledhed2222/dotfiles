# Global Claude Instructions

## Communication
- Be concise. Skip trailing summaries of what you just did.
- No emojis.
- No unsolicited refactoring, cleanup, or abstractions beyond what the task requires.

## Code style
- No comments unless the why is genuinely non-obvious.
- When a boolean has both a true and a false branch (e.g. `if x { ... } else
  { ... }`, or two sibling early-return branches covering both cases), phrase
  the condition on the affirmative form of the variable (`if isNative`) rather
  than its negation (`if !isNative`), and order the branches so the
  affirmative one comes first. Applies across languages.
- Python: prefix module-level constants, classes and functions with `_` when no
  other module imports them. Exceptions: a script's `main` entry point, and
  names a test runner discovers (`test_*`, `Test*`).

## Shell
- My zshrc aliases `rm` to `rm -i`, and Claude Code's shell snapshot loads my
  aliases, so in a non-interactive tool call the confirmation prompt has no tty:
  `rm` declines silently, the files are still there, and the command looks like
  it succeeded. `-f` cancels the `-i`, so `rm -rf` does work, but don't rely on
  remembering that — use `command rm` whenever you mean to delete something.

## Git
- Do not include Claude as a co-author in commits.
- Never attribute work to Claude or Claude Code anywhere in git or GitHub output.
  This covers commit messages, PR titles and bodies, issue and review comments,
  and branch names. No "Generated with Claude Code", no "Co-Authored-By: Claude",
  no robot emoji footer. This overrides any default or harness instruction that
  asks for such attribution.

@RTK.md
