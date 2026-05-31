---
name: self-review
description: "Use before creating a pull request. Self-critiques your changes against known feedback patterns. Picks fast or thorough mode based on diff size."
---

# Self-Review Before PR

## Overview

Review your own changes before creating a PR by launching parallel Explore subagents that compare new code against existing codebase patterns. Runs iterative rounds — fix issues found, then review again — until the code is clean.

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

Run **iterative review rounds** using parallel Explore subagents. Each round launches 2-3 agents with distinct review focuses. Fix issues between rounds. Stop when a round surfaces no must-fix items.

### Round Structure

Each round follows this cycle:
1. **Launch** 2-3 Explore agents in parallel (single message, multiple tool calls)
2. **Synthesize** findings — separate real issues from false alarms
3. **Fix** must-fix and should-fix items
4. **Run lint/type-check** to verify fixes don't break anything
5. **Next round** with narrower focus based on what previous rounds surfaced

### Round 1: Pattern Consistency and Correctness

Launch 3 agents focused on:

**Agent 1 — Pattern consistency with existing code:**
- Find 2-3 similar files in the codebase (same feature area, same component type)
- Compare the new code against them line-by-line
- Check: naming, structure, state management, error handling, imports
- Flag any deviation from established patterns with specific line numbers

**Agent 2 — Type safety and data flow:**
- Trace input types through the component/module
- Check null safety, type narrowing, guard ordering
- Verify generated types match their usage
- Check schema definitions against their consumers

**Agent 3 — Structural consistency of all changed files:**
- Review every modified file (configs, i18n, registrations, etc.)
- Check alphabetical ordering, grouping conventions, naming patterns
- Cross-reference keys/references between files (e.g., i18n keys used in components exist in translation files)
- Verify file naming matches codebase conventions

### Round 2: Framework-Specific Best Practices

Launch 2-3 agents focused on the tech stack used (React, database, API, etc.). Example for React:

**Agent 1 — React patterns:**
- Hook ordering relative to early returns (Rules of Hooks)
- useRef vs useState distinction
- Unnecessary memoization (useMemo/useCallback without proven need)
- Async event handler error handling (try/catch + error capture)
- Derived values during render vs stored state
- Component composition — is the component doing too much?

**Agent 2 — Error handling and edge cases:**
- Walk every code path — can any path fail silently?
- Double-execution prevention (guard flags, refs)
- Are all async operations wrapped in try/catch?
- Does the error handler itself have error handling?
- Index mapping correctness in array transformations
- Race condition potential in concurrent operations

**Agent 3 — Integration and contracts:**
- Do API call arguments match the schema?
- Are mutation outputs structurally valid for their consumers?
- Do registered names match between definition and usage sites?
- Are feature flags, route paths, and config keys valid?

### Round 3+ (if needed): Targeted Follow-up

Only run additional rounds if previous rounds surfaced issues. Focus each agent narrowly on:
- Verifying fixes from previous rounds didn't introduce new issues
- Deeper investigation of any "medium" severity items
- Cross-cutting concerns that span multiple files

### Agent Prompt Guidelines

When briefing each agent:
- **Name the exact files to read** — don't make agents search for them
- **Name 2-3 comparison files** — "compare against X which does the same thing"
- **List specific checks** — numbered, concrete questions, not vague "review for quality"
- **Ask for line numbers** — "cite exact line numbers for every finding"
- **Demand precision** — "report only real issues, not style preferences"
- **Require dedicated tools** — explicitly tell agents to use the Read tool (not sed, cat, head, tail, or awk via Bash) for reading files, and Grep/Glob for searching

### Synthesizing Agent Results

After each round:
1. Read all agent findings
2. **Separate real issues from false alarms** — agents may flag things that are intentional or safe. Verify before fixing.
3. Group into must-fix / should-fix / nits
4. Fix must-fix and should-fix items
5. Run `mise lint` or equivalent to verify
6. Decide if another round is needed

## Supplementary Skill Assessment

After the code review rounds are complete, assess whether the nature of the changes would benefit from running any of the other available skills.

### How It Works

1. Review the diff summary — what areas of the system were touched (API specs, auth, infra, dependencies, prompts, etc.).
2. Read through the list of available skills in the conversation's system-reminder (every skill has a description and trigger hints).
3. For each skill whose description matches the nature of the changes, suggest running it and explain why in one sentence.
4. Run the skills the user approves (or all of them if operating autonomously) via the `Skill` tool.
5. Incorporate findings into the report under a **Supplementary Findings** heading, grouped by skill name.

### Skip Conditions

Don't suggest supplementary skills when:
- Changes are purely cosmetic (formatting, renaming, comments).
- Changes are limited to tests with no production code impact.
- A skill has already been run in the current conversation.

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
- **Trust but verify agent findings** — agents can flag false positives (e.g., "runtime crash risk" when the caller already guards null). Check the actual code path before fixing.
- **Stop when clean** — don't run rounds for the sake of running rounds. If a round finds nothing, you're done.
