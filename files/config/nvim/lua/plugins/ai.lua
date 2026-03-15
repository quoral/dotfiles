return {
  -- Disable old AI plugins
  { "folke/sidekick.nvim", enabled = false },
  { "zbirenbaum/copilot.lua", enabled = false },
  { "zbirenbaum/copilot-cmp", enabled = false },
  { "CopilotC-Nvim/CopilotChat.nvim", enabled = false },

  -- Claude Code integration
  {
    "coder/claudecode.nvim",
    opts = {
      terminal = {
        split_width_percentage = 0.40,
      },
    },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      { "<c-.>", "<cmd>ClaudeCodeFocus<cr>", mode = { "n", "x", "i", "t" }, desc = "Claude Focus" },
      { "<leader>ga", "<cmd>ClaudeCode<cr>", desc = "Open AI Assistant" },
      { "<leader>gc", "<cmd>ClaudeCode<cr>", desc = "Claude Toggle", mode = { "n", "v" } },
    },
  },

  {
    "stevearc/dressing.nvim",
    lazy = true,
    opts = {
      input = { enabled = false },
      select = { enabled = false },
    },
  },
}
