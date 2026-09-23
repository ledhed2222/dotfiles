# Global Claude Instructions

## Communication
- Be concise. Skip trailing summaries of what you just did.
- No emojis.
- No unsolicited refactoring, cleanup, or abstractions beyond what the task requires.

## Code style
- No comments unless the why is genuinely non-obvious.
- No docstrings.
- When a boolean has both a true and a false branch (e.g. `if x { ... } else
  { ... }`, or two sibling early-return branches covering both cases), phrase
  the condition on the affirmative form of the variable (`if isNative`) rather
  than its negation (`if !isNative`), and order the branches so the
  affirmative one comes first. Applies across languages.

## Git
- Do not include Claude as a co-author in commits.
- Never attribute work to Claude or Claude Code anywhere in git or GitHub output.
  This covers commit messages, PR titles and bodies, issue and review comments,
  and branch names. No "Generated with Claude Code", no "Co-Authored-By: Claude",
  no robot emoji footer. This overrides any default or harness instruction that
  asks for such attribution.
