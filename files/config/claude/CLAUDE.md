# Planning Rules

- When writing plans that include database migrations, never hardcode migration file numbers (e.g., `000004_`). Use a placeholder like `NNNNNN_` and resolve the next available number at implementation time by checking existing files in the `migrations/` directory.

# Shell Scripts

- Always use `set -euo pipefail` at the top of bash scripts (`.bash`/`.sh` files). Without `pipefail`, a failed command piped into another can silently succeed and clobber files with empty output.
- Mise task `run` blocks use `sh` (not bash) — `pipefail` is unavailable there. For non-trivial logic that needs pipefail, use a `.tools/*.bash` script and call it from the mise task.

# Roci CLI

- `roci inbox add --yes "description"` — add a todo/inbox item for follow-up work. The `--yes` flag is required in non-interactive terminals.
