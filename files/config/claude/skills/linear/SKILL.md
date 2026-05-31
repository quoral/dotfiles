---
name: linear
description: "Use when interacting with Linear for issue tracking — fetching issues, creating/updating issues, querying projects, or making raw GraphQL API calls."
---

# Linear CLI

Use the `linear` CLI to interact with Linear for issue tracking and project management.

## Issue commands

```bash
# List my assigned issues
linear issue mine

# Query issues with filters
linear issue query --team ENG --state started
linear issue query --search "auth bug" --team ENG
linear issue query --project "Q2 Roadmap" --state unstarted
linear issue query --assignee karl --cycle active
linear issue query --label "bug" --all-teams

# View, create, update
linear issue view <issueId>
linear issue create
linear issue update <issueId>
linear issue comment <issueId>

# Workflow
linear issue start <issueId>        # Start working on an issue
linear issue id                      # Detect issue from current git branch
linear issue pr <issueId>           # Create a GitHub PR with issue details
```

Query filter flags: `--team`, `--state` (triage|backlog|unstarted|started|completed|canceled), `--assignee`, `--project`, `--cycle`, `--label`, `--milestone`, `--search`, `--limit`, `--created-after`, `--updated-after`. Use `--json` for machine-readable output.

## Other resources

```bash
linear team list
linear project list [--team ENG] [--status active]
linear cycle list
linear label list
linear document list
```

## Raw GraphQL API

Use `linear api` for anything not covered by built-in commands. Pass queries inline or use `linear schema` to explore the schema.

```bash
# List all projects with their states
linear api '{ projects { nodes { id name state } } }'

# Get a specific issue with comments
linear api '{ issue(id: "ISSUE-123") { title description comments { nodes { body createdAt } } } }'

# Search for issues with a filter
linear api '{ issues(filter: { team: { key: { eq: "ENG" } }, state: { name: { eq: "In Progress" } } }) { nodes { identifier title assignee { name } } } }'

# Get current user info
linear api '{ viewer { id name email } }'

# List workflow states for a team
linear api '{ workflowStates(filter: { team: { key: { eq: "ENG" } } }) { nodes { id name type } } }'

# With variables
linear api '{ issue(id: $id) { title } }' --variable id=ENG-42

# Paginate through all results
linear api '{ issues { nodes { identifier title } } }' --paginate
```

Use `linear schema` to print the full GraphQL schema and discover available types, fields, and filters.

## Usage guidelines

- When working on a task linked to a Linear issue, fetch issue context (title, description, acceptance criteria) before starting work.
- After completing work, update the issue status or add a comment via the CLI.
- Use `linear issue id` to detect the issue from the current git branch name.
- Use `--json` on list commands when you need to parse the output programmatically.
