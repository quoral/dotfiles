# Planning Rules

- When writing plans that include database migrations, never hardcode migration file numbers (e.g., `000004_`). Use a placeholder like `NNNNNN_` and resolve the next available number at implementation time by checking existing files in the `migrations/` directory.
