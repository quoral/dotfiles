---
name: self-review
description: "Use before creating a pull request. Self-critiques your changes against known feedback patterns. Picks fast or thorough mode based on diff size."
---

# Self-Review Before PR

## Overview

Review your own changes before creating a PR, catching the kinds of issues reviewers typically flag. Learns from past reviewer feedback to get better over time.

## When to Use

Invoke this skill when:
- About to create a pull request
- About to push a feature branch for review
- User asks for a self-review or pre-PR check

## Mode Selection

Check the diff scope first:

```bash
git diff main...HEAD --stat
```

- **Fast mode**: <= 5 files changed AND total diff < 200 lines
- **Thorough mode**: > 5 files changed OR diff >= 200 lines OR new dependencies introduced

State which mode you're using and why.

## Fast Mode

1. **Gather the diff:**
   ```bash
   git diff main...HEAD
   ```

2. **Scan against feedback patterns:**
   - Read `feedback-patterns.md` in this skill directory
   - Check the diff for each known pattern
   - Flag matches with specific line references

3. **General quick checks:**
   - Obvious bugs, typos, debug leftovers
   - Missing error handling at boundaries
   - TODOs or FIXMEs that shouldn't ship
   - Hardcoded values that should be config

4. **Report** using the format below.

## Thorough Mode

1. **Gather the diff and commit history:**
   ```bash
   git diff main...HEAD --stat
   git diff main...HEAD
   git log main...HEAD --oneline
   ```

2. **Read full files** for any non-trivial changes (skip renames, formatting-only).

3. **Check against feedback patterns** — same as fast mode but with full file context.

4. **Deeper analysis:**
   - Architectural consistency — does this follow existing patterns in the codebase?
   - Missing tests — are new code paths covered?
   - Error handling gaps — what happens when things fail?
   - Security considerations — input validation, auth checks, injection risks
   - Edge cases — empty inputs, concurrent access, off-by-one
   - Naming and API design — will this make sense to reviewers?

5. **Report** using the format below.

## Report Format

Group findings by severity:

### Must-fix
Issues that will likely be flagged as blocking in review.

### Should-fix
Important improvements that reviewers will probably request.

### Nits
Style, naming, minor improvements. Worth fixing but won't block.

### Verdict

End with one of:
- **Ready to PR** — no must-fix items, ship it
- **Address items first** — list the must-fix items to resolve

## Important

- Be specific. Reference file paths and line numbers.
- Don't invent issues. If the code is clean, say so.
- Prioritize patterns from `feedback-patterns.md` — these are real things reviewers have caught before.
- Don't re-review things that are clearly intentional or already discussed in commit messages.
