---
name: self-review
description: "Use before creating a pull request. Self-critiques your changes against known feedback patterns. Picks fast or thorough mode based on diff size."
---

# Self-Review Before PR

## Mindset

Self-review is intentionally **stricter** than reviewing someone else's code. You know the codebase, you wrote the change, and you have no excuse for shipping patterns you'd flag in a colleague's PR. If you'd raise it reviewing someone else — it's non-negotiable to catch in your own code.

The primary value is **architectural investigation** — tracing how your changes interact with the existing codebase (deletion paths, data flow, contract mismatches). Surface-level issues (style, naming, minor error-handling gaps) are secondary.

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

## Review Domains

Evaluate changes against these domains (not all apply to every change):

1. **Code Correctness & Logic** — Does the code do what it claims? Edge cases? Race conditions?
2. **Architecture & Design** — Does it fit the codebase patterns? Appropriate abstractions?
3. **Testing Coverage** — Are changes tested? Are tests meaningful?
4. **Requirements Alignment** — Does implementation match what was intended?
5. **Infrastructure/Domain Dependencies** — External service changes? Migration needs?
6. **Data Integrity & Lifecycle** — For new resource relationships: referential integrity, cascade behavior, orphan handling, deletion order
7. **YAGNI & Scope** — Is everything necessary for the stated goal? Are there abstractions, parameters, or branches that serve hypothetical future needs rather than current requirements?
8. **Complexity Justification** — For patterns that add complexity (concurrency primitives, generics, abstraction layers, indirection): is this justified at the current scale? A correct-but-complex pattern that serves no measurable need is still a cost.

**API contracts and database schema get extra scrutiny.** These are foundational — mistakes are expensive post-merge. For schema changes, think from the caller's perspective: what queries run against this table, what access patterns are expected. For API changes, think from the consumer's perspective: is the request/response shape intuitive, are error cases handled.

## Investigation Techniques

These are the highest-value activities in self-review. Don't just read your own diff — investigate how it interacts with the rest of the codebase.

### Cross-Codebase Pattern Comparison

Find existing implementations of the same pattern and compare:
- How do other handlers/modules in this domain handle the same concern?
- Does your implementation follow the established convention, or diverge?
- If you based your code on an existing pattern, does your version actually match in the load-bearing details?

### Dual Code Path Consistency

When two code paths serve similar purposes, a change to one often needs a corresponding change to the other. Check:
- Does the new behavior apply to both paths?
- Are there asymmetries between the paths that your change introduces or misses?

### Data Flow Tracing

When your change modifies how a field is written, read, or propagated, trace all paths:
- What writes this field? (API handlers, event consumers, backfill jobs, migrations)
- What reads it? (Queries, serializers, downstream consumers)
- After your change, do all write paths produce consistent state?

### Deletion Verification

For changes with significant deletions:
- Grep for imports of deleted modules
- Check for remaining references
- Confirm deleted functionality is covered by remaining code

## Fast Mode

1. **Gather the diff:**
   ```bash
   git diff main...HEAD
   ```

2. **Scan against feedback patterns:**
   - Read `feedback-patterns.md` in this skill directory
   - Check the diff for each known pattern
   - Flag matches with specific line references

3. **Quick domain checks:**
   - Obvious bugs, typos, debug leftovers
   - Missing error handling at boundaries
   - TODOs or FIXMEs that shouldn't ship
   - Hardcoded values that should be config
   - YAGNI violations — anything that serves hypothetical future needs
   - Pattern divergence — does new code follow established conventions?

4. **Report** using the format below.

## Thorough Mode

Run **iterative review rounds** using parallel Explore subagents. Each round launches 2-3 agents with distinct review focuses drawn from the review domains and investigation techniques. Fix issues between rounds. Stop when a round surfaces no must-fix items.

### Round Structure

Each round follows this cycle:
1. **Launch** 2-3 Explore agents in parallel (single message, multiple tool calls)
2. **Synthesize** findings — separate real issues from false alarms
3. **Fix** must-fix and should-fix items
4. **Run lint/type-check** to verify fixes don't break anything
5. **Next round** with narrower focus based on what previous rounds surfaced

### Round 1: Pattern Consistency and Correctness

Launch 3 agents focused on:

**Agent 1 — Cross-codebase pattern comparison:**
- Find 2-3 similar files in the codebase (same feature area, same component type)
- Compare the new code against them: naming, structure, error handling, imports
- Flag any deviation from established patterns with specific line numbers
- For API/schema changes: compare PK strategy, index patterns, auth, pagination, error shapes against similar existing code

**Agent 2 — Type safety and data flow tracing:**
- Trace input types through the component/module
- Check null safety, type narrowing, guard ordering
- Verify generated types match their usage
- Trace field reads/writes across the codebase — do all write paths produce consistent state after this change?

**Agent 3 — Structural consistency and data integrity:**
- Review every modified file (configs, registrations, etc.)
- Cross-reference keys/references between files
- For new resource relationships: check referential integrity, cascade behavior, orphan handling, deletion order
- Verify file naming matches codebase conventions

### Round 2: Architecture, Edge Cases, and Integration

Launch 2-3 agents focused on the specific concerns this change raises:

**Agent 1 — Architecture and complexity:**
- Does the change fit codebase patterns? Is the abstraction level appropriate?
- YAGNI check: is everything necessary for the stated goal?
- Complexity justification: are complex patterns (concurrency, generics, indirection) warranted at current scale?
- Dual code path consistency: if similar paths exist, does the change apply to both?

**Agent 2 — Error handling and edge cases:**
- Walk every code path — can any path fail silently?
- Are all async operations properly handled?
- Race condition potential in concurrent operations
- Silent failure modes that would pass tests but produce wrong behavior

**Agent 3 — Integration and contracts:**
- Do API call arguments match the schema?
- Are mutation outputs structurally valid for their consumers?
- Do registered names match between definition and usage sites?
- For deletions: grep for remaining references to deleted code

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
- **Tell agents to read full files, not just the diff** — the diff shows what changed, but surrounding code catches asymmetries between related code paths

### Synthesizing Agent Results

After each round:
1. Read all agent findings
2. **Separate real issues from false alarms** — agents may flag things that are intentional or safe. Verify before fixing.
3. **Calibrate theoretical risks by failure visibility** — if a future change would trigger an obvious failure (compilation error, test failure), skip it. Only flag theoretical risks when the failure mode would be silent: subtle data corruption, wrong-but-plausible behavior, or bugs that pass tests.
4. Group into must-fix / should-fix / nits
5. Fix must-fix and should-fix items
6. Run `mise lint` or equivalent to verify
7. Decide if another round is needed

## Adversarial Verification Pass

After all review rounds are complete and fixes applied, do one final pass through the diff with a **reviewer's lens** — pretend you're reviewing a colleague's PR, not your own code. This catches issues that self-review rounds miss due to author bias.

1. Re-read the full diff (`git diff main...HEAD`)
2. For each changed file, evaluate against the review domains as if seeing this code for the first time
3. Apply the investigation techniques: cross-codebase pattern comparison, dual code path consistency, data flow tracing
4. Be adversarial — look for reasons to request changes, not reasons to approve
5. If this pass surfaces must-fix items: fix them and re-run the adversarial pass

This pass is what makes `/goal` composition work. The goal evaluator checks the verdict — if the adversarial pass found issues, the verdict says so and `/goal` keeps the session alive for another cycle.

## Supplementary Skill Assessment

After the adversarial pass is clean, assess whether the nature of the changes would benefit from running any of the other available skills.

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
Issues that will likely be caught in review — or worse, in production.

### Should-fix
Important improvements. A reviewer would flag these.

### Nits
Style, naming, minor improvements. Worth fixing but won't block.

### Verdict

End with exactly one of these lines (the `/goal` evaluator reads this):

> **VERDICT: READY TO PR** — no must-fix items remain, adversarial pass is clean

> **VERDICT: NOT READY** — N must-fix items remain: [list them]

## Composing with /goal

This skill is designed to work with `/goal` for fully autonomous self-improvement loops:

```
/goal run /self-review until the verdict is READY TO PR
```

Each `/goal` iteration runs a full self-review cycle (rounds → fixes → adversarial pass → verdict). The goal evaluator checks the verdict line. If NOT READY, Claude re-enters the skill for another cycle. If READY TO PR, the goal is met and Claude stops.

## Important

- Be specific. Reference file paths and line numbers.
- Don't invent issues. If the code is clean, say so.
- Prioritize patterns from `feedback-patterns.md` — these come from real review feedback.
- Don't re-review things that are clearly intentional or already discussed in commit messages.
- **Trust but verify agent findings** — agents can flag false positives (e.g., "runtime crash risk" when the caller already guards null). Check the actual code path before fixing.
- **Stop when clean** — don't run rounds for the sake of running rounds. If a round finds nothing, move to the adversarial pass.
- **Verify your own fixes are sound** — before applying a fix, verify the mechanism is available in the runtime context. An incorrect fix is worse than the original issue.
