---
name: code-reviewer
description: Progressive code review workflow that engages reviewers batch-by-batch with inline diff comments
---

# Code Reviewer Skill

## Overview

This skill implements a progressive code review workflow. Instead of dumping all feedback at the end, you engage the reviewer batch-by-batch, ensuring they stay involved and can course-correct early.

## Hard Gate

**NEVER submit review comments without explicit confirmation.** Draft comments are proposals. The reviewer must approve, edit, or reject each batch before any submission occurs.

## Checklist

Execute these steps in order:

1. [ ] Read PR metadata from `.review/pr-meta.json`
2. [ ] Understand the PR context (title, description, base branch)
3. [ ] Determine review mode:
   - **Code review** (default): changes are primarily code → continue to step 4
   - **Plan + code review**: PR includes a plan/design doc alongside implementation → verify plan first (see Plan + Code PRs), then continue to step 4 for the implementation
   - **Discussion review**: changes are architecture docs, RFCs, or design proposals → follow Discussion Mode flow
4. [ ] Analyze changed files and determine batching strategy
5. [ ] Propose batch groupings to reviewer for approval
6. [ ] For each approved batch:
   - [ ] Analyze changes in the batch
   - [ ] For simple batches: summarize → draft comments → confirm
   - [ ] For complex batches: investigate usage → surface findings → draft comments
   - [ ] Present draft comments with inline diff view
   - [ ] Wait for reviewer approval/edits before proceeding
7. [ ] After all batches reviewed, summarize overall review
8. [ ] Only submit comments after final confirmation
9. [ ] Capture session learnings in `.review/session-feedback.md`

## Review Domains

Evaluate each batch against these domains (not all apply to every change):

1. **Code Correctness & Logic** - Does the code do what it claims? Edge cases? Race conditions?
2. **Architecture & Design** - Does it fit the codebase patterns? Appropriate abstractions?
3. **Testing Coverage** - Are changes tested? Are tests meaningful?
4. **Requirements Alignment** - Does implementation match PR description/linked issues?
5. **Infrastructure/Domain Dependencies** - External service changes? Migration needs?
6. **Data Integrity & Lifecycle** - For new resource relationships: referential integrity, cascade behavior, orphan handling, deletion order

## Batch Analysis Heuristics

Choose batching strategy based on the PR structure:

1. **By commit** - When commits are atomic and well-organized
2. **By module/directory** - When changes cluster in specific areas
3. **By file relationship** - Group files that import each other or share types
4. **By change type** - Separate refactors from features from tests
5. **Top-down for features** - For feature PRs: API contracts → database schema → service layer → handlers → tests. Review foundational layers first to catch architectural issues early.
6. **Deletion verification** - For PRs with significant deletions, add a verification batch:
   - Grep for imports of deleted modules
   - Check for remaining references
   - Confirm deleted functionality is covered by remaining code

### Batch Priority

**API contracts and database schema require extra scrutiny.** These are foundational - mistakes here are expensive to fix after merge. Always:
- Review these batches first, before implementation code
- Run pattern checks (see below) before commenting
- Apply a lower threshold for blocking severity

For database schema changes, understand the contract from the caller's perspective:
- What queries will run against this table?
- What are the expected access patterns (by PK, by foreign key, filtered scans)?
- How will the schema support the service layer's needs?

For API contract changes, understand the contract from the consumer's perspective:
- How will clients call this endpoint?
- What error cases need handling?
- Is the request/response shape intuitive for the use case?

### Skip Generated Code

Identify and skip generated files (e.g., `api.gen.go`, `client.gen.go`, sqlc output, protobuf stubs). These are mechanically derived from specs - review the specs, not the output.

Present your proposed batching to the reviewer:
```
I propose reviewing this PR in 3 batches:

Batch 1: Auth module refactor (3 files)
- src/auth/tokens.ts
- src/auth/session.ts
- src/auth/types.ts

Batch 2: New endpoint implementation (2 files)
- src/api/users.ts
- src/api/routes.ts

Batch 3: Tests (2 files)
- tests/auth.test.ts
- tests/api.test.ts

Approve this batching, or suggest different groupings?
```

## Engagement Flow

### Simple Batches (straightforward changes)
1. Summarize what changed
2. Draft comments with inline diff view
3. Ask: "Approve these comments, edit, or skip?"

### Complex Batches (nuanced or unclear changes)
1. **Investigate before committing** - Before drafting comments, explore:
   - Where are changed functions/types used?
   - What's the blast radius of this change?
   - Are there related patterns elsewhere in the codebase?
2. Surface findings to reviewer: "I explored X and found Y. Want me to investigate further, or draft comments?"
3. Only after investigation, draft comments
4. Ask: "Approve these comments, edit, or skip?"

**Prioritize architectural concerns over surface-level issues.** Tracing how a change interacts across the codebase (deletion paths, cache consistency, data flow) is more valuable than flagging localized style or error-handling gaps.

### API and Database Batches (always investigate first)

For batches containing API contracts or database schema changes, **always** run pattern checks before drafting comments:

**Database schema:**
1. Identify similar tables in the same domain
2. Compare PK strategy, index patterns, nullable fields, naming conventions
3. Flag deviations for discussion

**API endpoints:**
1. Check similar endpoints for consistent patterns (auth, pagination, error shapes)
2. Compare request/response shapes with related endpoints
3. Verify alignment with existing API conventions

Surface findings before commenting: "Compared against [similar_table] - this uses X while existing tables use Y. Is this intentional?"

### Empty Batches

"No comments" is a valid outcome. Don't force comments where none are needed.

When a batch has no issues:
- **Just move on** for mechanical changes (test updates mirroring implementation, import reordering)
- **Brief summary** for substantive changes: "Reviewed X - the approach is sound, no concerns"

The goal is to confirm you reviewed it, not to generate feedback for its own sake.

### Consolidated Feedback (mild suggestions)

When a batch has only mild suggestions or nitpicks (no blocking/important issues), offer to consolidate them into a single approval comment rather than individual inline comments:

```
This batch looks good. I have 2 minor suggestions:
1. Consider X in file.ts:45
2. The naming in util.ts:23 could be clearer

Want me to add these as inline comments, or include them in a consolidated approval comment?
```

Consolidated approval comments work well when:
- All feedback is suggestion/nitpick severity
- The PR is otherwise ready to merge
- Inline comments would feel like over-documenting

## Discussion Mode

For PRs that are architecture docs, RFCs, or design proposals, the goal is understanding and discussion, not posting inline comments.

### Flow

1. **Verify claims against the codebase** — Read the actual code the doc references before reviewing the doc's internal consistency. Does the doc accurately describe the current state?
2. **Verify claims against external docs** — Use WebFetch to check claims about third-party behavior, limits, APIs, deprecations
3. **Surface findings iteratively** — Present one finding or concern at a time. Let the reviewer push back, refine, or redirect before moving to the next
4. **Follow the thread** — Each pushback ("but what about X?") is a prompt to investigate further. The discussion should converge on understanding, not defend initial findings
5. **Capture findings** in session feedback — the value is in the discussion and what was learned, not in posted comments

### Default Outcome

No comments posted. Discussion PRs typically end with captured learnings and a shared understanding. Only post comments if the reviewer explicitly wants specific points documented on the PR.

## Plan + Code PRs

When a PR includes a plan or design document alongside implementation code:

1. **Verify the plan first** — Before looking at any implementation, read the plan and verify it against the codebase:
   - Does the plan accurately describe the current state?
   - Does the proposed approach make sense given existing patterns?
   - Are there assumptions that don't hold?
2. **Discuss iteratively** — Surface findings about the plan one at a time. Let the reviewer push back and refine understanding before proceeding
3. **Then batch the implementation** — Once the plan is understood, proceed to normal batch review of the code changes. The plan discussion provides context for evaluating whether the implementation matches intent

## Comment Format

**Keep comments short.** Lead with the suggestion. Add context only when the reasoning isn't obvious from the code.

Present draft comments with inline diff context:

```
📝 Draft comment #1 [Important]

  src/auth/tokens.ts:45
  ────────────────────────────────
  │ 43 │ export function validateToken(token: string): TokenPayload | undefined {
  │ 44 │   const decoded = jwt.decode(token);
  │ 45+│   if (!decoded) return undefined;
  ────────────────────────────────

  Comment: "validateToken returns undefined for both invalid tokens and expired
  tokens. Consider distinguishing these cases - callers may want to handle
  'please refresh' differently from 'invalid credentials'."

  Severity: suggestion
```

```
📝 Draft comment #2 [Nitpick]

  src/api/users.ts:23-27
  ────────────────────────────────
  │ 23 │ async function getUser(id: string) {
  │ 24-│   const user = await db.users.find(id);
  │ 24+│   const user = await db.users.findById(id);
  │ 25 │   if (!user) throw new NotFoundError();
  │ 26 │   return user;
  │ 27 │ }
  ────────────────────────────────

  Comment: "Good change to use findById - more explicit."

  Severity: praise
```

### Severity Levels
- **blocking** - Must be addressed before merge
- **important** - Should be addressed, but judgment call
- **suggestion** - Consider this improvement
- **nitpick** - Minor style/preference
- **question** - Need clarification to complete review

**Note on praise:** Skip praise comments by default. Only include praise when explicitly requested or to highlight non-obvious patterns worth replicating across the codebase.

### Comment Tone

**Rule: Assume good intent. Provide actionable suggestions.**

When drafting comments:
1. **Suggestions over questions** - "Consider X for Y reason" not "Was X intentional?"
2. **Practical over policy** - Give the concrete suggestion, don't cite guidelines verbatim
3. **Curiosity for genuine unknowns** - Reserve questions for when you actually need clarification

**Exception:** Security issues, clear bugs, and broken tests warrant direct language.

Examples:
- ❌ "Was this threshold change intentional?"
- ✅ "Consider adding a comment explaining why 0.85 - future readers will wonder about the magic number"

- ❌ "Per our style guide, we prefer X"
- ✅ "Consider using X here for consistency with the auth module"

## Reading the Diff

The diff is pre-generated at `.review/pr-diff.patch`. Read this file to see all changes.

Do NOT run `git diff` yourself - use the pre-generated diff file to ensure consistency and save tokens.

## Verifying External Claims

Before submitting comments that reference external documentation, deprecation notices, or third-party behavior:

1. **Verify the claim** - Use WebFetch or check official docs
2. **If unverifiable** - Either drop the claim or reframe as "worth checking if..."
3. **Cite your verification** - "Confirmed via [source]" gives the reviewer confidence

Example: Before commenting "this package is deprecated," check npm/PyPI to confirm.

## Self-Update Triggers

This skill should evolve based on usage. Propose edits to this file when:

1. **Repeated workflow overrides** - If the reviewer consistently skips a step or changes the order, the workflow may be wrong
2. **Explicit feedback** - "This isn't working" or "Can we skip X?"
3. **Missing patterns** - Encountered a review scenario not covered

When proposing updates:
```
I've noticed you consistently [pattern]. Should I update the code-reviewer skill to:

[Proposed change with rationale]

This would change lines X-Y of ~/.claude/skills/code-reviewer.md
```

## Submitting Comments

After all batches are reviewed and comments approved:

1. Summarize the review:
   ```
   Review Summary:
   - 2 blocking issues
   - 3 suggestions
   - 1 praise

   Ready to submit these 6 comments to the PR?
   ```

2. Only after explicit "yes" / "submit" / "go ahead", submit via `gh api`:
   ```bash
   # Inline comments require JSON file input
   cat > /tmp/review.json << 'EOF'
   {
     "commit_id": "abc123...",
     "body": "Review summary here",
     "event": "COMMENT",
     "comments": [
       {"path": "src/file.ts", "line": 45, "body": "Comment text..."}
     ]
   }
   EOF
   gh api repos/{owner}/{repo}/pulls/{pr}/reviews --method POST --input /tmp/review.json
   ```

## Aborting Review

If the reviewer wants to stop:
- Save progress to `.review/draft-comments.json`
- They can resume later with context preserved

## Session Learnings

After submitting comments (or aborting), capture learnings in `.review/session-feedback.md`:

```markdown
# Code Review Session Feedback - PR #{number}

## Session Summary
- **PR:** {title}
- **Batches:** {count} ({brief description})
- **Comments submitted:** {count} ({breakdown by severity})

## What Worked Well
{List approaches that helped the review}

## Patterns Observed
{Document any repeated behaviors - investigation loops, tone adjustments, skipped comments}

## Skill Update Suggestions
{If patterns suggest the skill should change, note them here}
```

This file serves two purposes:
1. **Immediate:** Helps reviewer reflect on their review process
2. **Long-term:** Provides input for skill improvements (see Self-Update Triggers)
