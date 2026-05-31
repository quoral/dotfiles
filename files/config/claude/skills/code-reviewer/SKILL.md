---
name: code-reviewer
description: Progressive code review workflow that engages reviewers batch-by-batch with inline diff comments
---

# Code Reviewer Skill

## Overview

This skill implements a progressive code review workflow. Instead of dumping all feedback at the end, you engage the reviewer batch-by-batch, ensuring they stay involved and can course-correct early.

## Hard Gate

**In interactive mode, NEVER submit review comments without explicit confirmation.** Draft comments are proposals. The reviewer must approve, edit, or reject each batch before any submission occurs.

In autonomous mode, this gate is relaxed — see Autonomous Mode for submission rules.

## Autonomous Mode

When explicitly told you are running in autonomous mode (no human reviewer in the loop), adjust your behavior:

- **Lower the threshold for flagging, but don't mechanically inflate severity.** You have no reviewer to catch what you miss. Flag things you'd normally stay quiet on — but keep their natural severity. A nitpick is still a nitpick; an architectural concern that's genuinely important should be important. The change is in what you surface, not in how you label it.
- **Skip the batch approval loop.** There is no reviewer to approve batches — analyze all batches sequentially, draft all comments, then submit them in a single review. Submit as `COMMENT` by default. Use `REQUEST_CHANGES` only when there are blocking issues.
- **Be thorough on architectural and cross-cutting concerns.** Run pattern comparisons, check dual code paths, and read beyond the diff even for batches that look simple. In interactive mode the reviewer catches what you miss — in autonomous mode, you are the only eyes.

## Checklist

Execute these steps in order:

1. [ ] Read PR metadata from `.review/pr-meta.json`
2. [ ] Understand the PR context (title, description, base branch)
3. [ ] Check for existing pending reviews and automated review comments (e.g., Greptile) on the PR to avoid duplicate feedback and to validate or dismiss prior findings:
   ```bash
   # Fetch existing reviews
   gh api repos/{owner}/{repo}/pulls/{pr}/reviews
   # Fetch inline comments (includes Greptile bot comments)
   gh api repos/{owner}/{repo}/pulls/{pr}/comments
   ```
4. [ ] Determine review mode:
   - **Code review** (default): changes are primarily code → continue to step 5
   - **Plan + code review**: PR includes a plan/design doc alongside implementation → verify plan first (see Plan + Code PRs), then continue to step 5 for the implementation
   - **Discussion review**: changes are architecture docs, RFCs, or design proposals → follow Discussion Mode flow
5. [ ] Analyze changed files and determine batching strategy
6. [ ] Propose batch groupings to reviewer for approval (autonomous: decide batching, proceed directly)
7. [ ] For each batch:
   - [ ] Analyze changes in the batch
   - [ ] For simple batches: summarize → draft comments → confirm
   - [ ] For complex batches: investigate usage → surface findings → draft comments
   - [ ] Present draft comments with inline diff view
   - [ ] Wait for reviewer approval/edits before proceeding (autonomous: skip — continue to next batch)
8. [ ] After all batches reviewed, summarize overall review
9. [ ] Submit comments after final confirmation (autonomous: submit directly)
10. [ ] Capture session learnings in `.review/session-feedback.md`

## Review Domains

Evaluate each batch against these domains (not all apply to every change):

1. **Code Correctness & Logic** - Does the code do what it claims? Edge cases? Race conditions?
2. **Architecture & Design** - Does it fit the codebase patterns? Appropriate abstractions?
3. **Testing Coverage** - Are changes tested? Are tests meaningful?
4. **Requirements Alignment** - Does implementation match PR description/linked issues?
5. **Infrastructure/Domain Dependencies** - External service changes? Migration needs?
6. **Data Integrity & Lifecycle** - For new resource relationships: referential integrity, cascade behavior, orphan handling, deletion order
7. **YAGNI & Scope** - Is everything in this PR necessary for the stated goal? Are there abstractions, parameters, or branches that serve hypothetical future needs rather than current requirements?

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
- Run pattern checks (see Investigation Techniques) before commenting
- Apply a lower threshold for blocking severity

For database schema changes, understand the contract from the caller's perspective:
- What queries will run against this table?
- What are the expected access patterns (by PK, by foreign key, filtered scans)?
- How will the schema support the service layer's needs?

For API contract changes, understand the contract from the consumer's perspective:
- How will clients call this endpoint?
- What error cases need handling?
- Is the request/response shape intuitive for the use case?

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

### Skip Generated Code

Identify and skip generated files (e.g., `api.gen.go`, `client.gen.go`, sqlc output, protobuf stubs) and machine-generated implementation plans included in PRs. These are mechanically derived from specs or tools — review the specs and the actual implementation, not the generated artifacts.

## Pre-Batch Research Phase

For PRs that introduce new abstractions (enum values, ownership semantics, architectural patterns), offer a conceptual discussion phase **before** proposing batches:

1. Identify the core design decisions in the PR
2. Research the codebase context (existing patterns, related systems)
3. Surface 1-2 conceptual concerns to the reviewer for discussion
4. Let the discussion converge before moving to batch-by-batch review

This phase is optional — skip it for PRs that are purely additive or follow established patterns. Offer it when the diff introduces something the reviewer will want to reason about holistically before seeing the implementation details.

For PRs with significant architectural changes or where the PR description requests high-level feedback, consider running a blast radius analysis (if available) as part of this phase. Architectural-level findings shape the entire review and prevent batch-level analysis from rehashing the same concerns.

## Engagement Flow

**Architectural concerns are the primary value of this review.** Tracing how a change interacts across the codebase (deletion paths, cache consistency, data flow, contract mismatches) is where reviews catch the bugs that tests miss. Surface-level issues (style, naming, minor error-handling gaps) are secondary — include them as nitpicks when noticed, but don't let them displace investigation time.

### Reviewer-Directed Mode

When the reviewer signals they've already reviewed the PR ("I've looked at this", "I have a question about X"), skip the overview and go directly to their specific concern. The reviewer is leading — follow their thread, investigate what they ask about, and only broaden scope if they invite it.

### Simple Batches (straightforward changes)
1. Summarize what changed
2. Draft comments with inline diff view
3. Ask: "Approve these comments, edit, or skip?"

### Complex Batches (nuanced or unclear changes)
1. **Investigate before committing** - Before drafting comments, explore:
   - Where are changed functions/types used?
   - What's the blast radius of this change?
   - Are there related patterns elsewhere in the codebase?
   - **Read full files, not just the diff** — the diff shows what changed, but reading surrounding code catches asymmetries between related code paths (e.g., two handlers that serve similar purposes but have different entry points)
2. Surface findings to reviewer: "I explored X and found Y. Want me to investigate further, or draft comments?"
3. Only after investigation, draft comments
4. Ask: "Approve these comments, edit, or skip?"

### API and Database Batches (always investigate first)

For batches containing API contracts or database schema changes, **always** run cross-codebase pattern comparison (see Investigation Techniques) before drafting comments. Specifically:

- **Database schema:** Compare PK strategy, index patterns, nullable fields, and naming conventions against similar tables in the same domain
- **API endpoints:** Compare auth, pagination, error shapes, and request/response shapes against similar endpoints

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

Present draft comments with inline diff context. Each comment must include a clickable GitHub link to the file and line range so the reviewer can jump directly to the code.

The link format is: `https://github.com/{owner}/{repo}/blob/{head_branch}/{path}#L{start}-L{end}`

Get the head branch from `.review/pr-meta.json` (`headRefName`) and the owner/repo from the PR URL or system prompt.

```
📝 Draft comment #1 [Important]

  [src/auth/tokens.ts:43-45](https://github.com/acme/platform/blob/feat/auth-refactor/src/auth/tokens.ts#L43-L45)
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

### Severity Levels
- **blocking** - Must be addressed before merge
- **important** - Should be addressed, but judgment call
- **suggestion** - Consider this improvement
- **nitpick** - Minor style/preference
- **question** - Need clarification to complete review

**Default severity is suggestion.** Use blocking for clear bugs, security issues, spec violations, or failing tests. Use important for architectural concerns, contract mismatches, and issues that are expensive to fix post-merge. Don't inflate severity for theoretical risks from hypothetical future changes, but do flag silent failure modes.

**No inline praise comments.** Never post praise as inline review comments. If something is worth calling out (a non-obvious pattern worth replicating, a particularly clean solution), mention it in the final review summary comment instead.

**Include spec/RFC links when referencing standards.** When a comment references an RFC, spec, or external standard (e.g., PKCE, OAuth2, MCP spec), include the link in the comment body. This gives the PR author traceability and saves them from having to look it up. Verify the claim via WebFetch before citing it — an authoritative source elevates a suggestion from opinion to fact.

### Comment Tone

**Rule: Assume good intent. Provide actionable suggestions.**

When drafting comments:
1. **Suggestions over questions** - "Consider X for Y reason" not "Was X intentional?"
2. **Practical over policy** - Give the concrete suggestion, don't cite guidelines verbatim
3. **Curiosity for genuine unknowns** - Reserve questions for when you actually need clarification

**Exception:** Security issues, clear bugs, and broken tests warrant direct language.

**Calibrate theoretical risks by failure visibility.** If a future change would trigger an obvious, non-silent failure (compilation error, test failure, immediate crash), skip the comment — it will surface naturally. Only raise theoretical risks as real comments when the failure mode would be silent: subtle data corruption, wrong-but-plausible behaviour, or a bug that passes tests.

**Skip external-tracking questions.** Don't ask whether something is tracked in Linear/Jira/etc. unless the risk is immediate and blocking this PR. If it's deferred and documented in the code, trust that it's handled.

**When a fix has two natural locations, present both.** If a change could reasonably live in the helper or the caller, name both options and let the reviewer decide rather than picking one.

**Verify your own suggestions are feasible.** Before suggesting a mitigation or fix, verify the mechanism is available in the runtime context. Don't suggest using temp state keys if they don't survive across turns, or propose a caching strategy if the execution model doesn't support it. An infeasible suggestion wastes the reviewer's time and erodes trust.

Examples:
- ❌ "Was this threshold change intentional?"
- ✅ "Consider adding a comment explaining why 0.85 - future readers will wonder about the magic number"

- ❌ "Per our style guide, we prefer X"
- ✅ "Consider using X here for consistency with the auth module"

## Reading the Diff

The diff is pre-generated at `.review/pr-diff.patch`. Read this file to see all changes.

Do NOT run `git diff` yourself — use the pre-generated diff file to ensure consistency and save tokens. However, **do** read full source files (via `Read` or `cat`) when investigating — the diff shows what changed, but the surrounding code provides the context needed to evaluate the change.

## Investigation Techniques

These techniques apply across all batch types. The most consistently valuable review work comes from investigating how changes interact with the existing codebase, not from reading the diff in isolation.

### Cross-Codebase Pattern Comparison

When reviewing a new implementation, find existing implementations of the same pattern and compare:
- "How do other handlers in this domain handle X?" (e.g., comparing webhook handlers found a missing `MaxBytesReader`)
- "Where else is this pattern used, and does this PR follow the convention?" (e.g., surveying PATCH handlers answered a deduplication question)
- "Does the cited precedent actually match?" (e.g., pre-existing auth middleware patterns clarified that an unauthenticated endpoint was intentional)

This applies to API/DB batches (already covered) but is equally valuable for service logic, handler patterns, error handling, and test structure.

### Dual Code Path Consistency

When two code paths serve similar purposes (e.g., `HandleOAuthCallback` vs `handleNativeAuthCallback`), a change to one often needs a corresponding change to the other. Check:
- Does the new behavior apply to both paths?
- Are there asymmetries between the paths that the PR introduces or misses?

This is a recurring bug pattern — different entry points to similar logic diverge silently.

## Verifying External Claims

Before submitting comments that reference external documentation, deprecation notices, or third-party behavior:

1. **Verify the claim** - Use WebFetch or check official docs
2. **If unverifiable** - Either drop the claim or reframe as "worth checking if..."
3. **Cite your verification** - "Confirmed via [source]" gives the reviewer confidence

Example: Before commenting "this package is deprecated," check npm/PyPI to confirm.

**Also verify precedent claims in PR descriptions.** When an author justifies a pattern by citing existing usage ("same as X"), check that the cited usage actually matches. Copy-paste precedents are often partial — the cited example may differ in a load-bearing way.

**Verify claimed constraints and rejected alternatives.** When a PR description says "we considered X but chose Y because Z," verify Z before accepting the tradeoff. Check whether the claimed limitation actually exists — constraints assumed during design sometimes don't hold, and the simpler alternative may be viable.

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
   - 1 important
   - 2 suggestions

   Ready to submit these 5 comments to the PR?
   ```

**Do not submit a review verdict (approve / request-changes) unless the reviewer explicitly asks.** Always use `"event": "COMMENT"` by default. When the reviewer wants to approve alongside comments, use `"event": "APPROVE"` instead. Offer both options:
```
Ready to submit. Post as:
a) Comments only (no verdict)
b) Approve with comments
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

### Pending Reviews

If the reviewer already has a pending (draft) review on the PR, the REST endpoints `POST /pulls/comments` and `POST /pulls/reviews` will both return 422. In this case, use the GraphQL `addPullRequestReviewThread` mutation with the `pullRequestReviewId` instead:

```bash
gh api graphql -f query='
  mutation($reviewId: ID!, $path: String!, $line: Int!, $body: String!) {
    addPullRequestReviewThread(input: {
      pullRequestReviewId: $reviewId, path: $path, line: $line, body: $body
    }) { thread { id } }
  }' -f reviewId="..." -f path="src/file.ts" -F line=45 -f body="Comment text"
```

Note: the `line` field returned by REST for GraphQL-created review threads shows `null` — this is a known quirk, not an error.

## Aborting Review

If the reviewer wants to stop:
- Save progress to `.review/draft-comments.json`
- They can resume later with context preserved

## Session Learnings

After submitting comments (or aborting), capture learnings in `.review/session-feedback.md`.

**If the file already exists** (i.e., this PR has been reviewed before), **append** a new session section with a horizontal rule separator — do not overwrite prior session feedback. Number the sessions sequentially (Session 1, Session 2, etc.).

**If the file does not exist**, create it with the header and first session:

```markdown
# Code Review Session Feedback - PR #{number}

---

## Session {n}

### Session Summary
- **PR:** {title}
- **Batches:** {count} ({brief description})
- **Comments submitted:** {count} ({breakdown by severity})

### What Worked Well
{List approaches that helped the review}

### Patterns Observed
{Document any repeated behaviors - investigation loops, tone adjustments, skipped comments}

### Findings Considered and Dropped
{List findings you investigated but chose not to comment on, with reasoning. This calibrates future reviews.}

### Skill Update Suggestions
{If patterns suggest the skill should change, note them here}
```

This file serves two purposes:
1. **Immediate:** Helps reviewer reflect on their review process
2. **Long-term:** Provides input for skill improvements (see Self-Update Triggers)
