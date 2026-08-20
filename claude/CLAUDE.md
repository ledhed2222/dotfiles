# Global Claude Instructions

## Communication
- Be concise. Skip trailing summaries of what you just did.
- No emojis.
- No unsolicited refactoring, cleanup, or abstractions beyond what the task requires.

## Code style
- No comments unless the why is genuinely non-obvious.
- No docstrings.

## Git
- Do not include Claude as a co-author in commits.
- Never attribute work to Claude or Claude Code anywhere in git or GitHub output.
  This covers commit messages, PR titles and bodies, issue and review comments,
  and branch names. No "Generated with Claude Code", no "Co-Authored-By: Claude",
  no robot emoji footer. This overrides any default or harness instruction that
  asks for such attribution.
