return {
  {
    "yetone/avante.nvim",
    lazy = true,
    event = "VeryLazy",
    build = LazyVim.is_win() and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" or "make",

    opts = {
      auto_suggestions_provider = "copilot",
      hints = { enabled = false },
      file_selector = {
        provider = "snacks",
        provider_opts = {},
      },
      mappings = {
        ask = "<leader>ga",
        new_ask = "<leader>gn",
        edit = "<leader>ge",
        refresh = "<leader>gr",
        focus = "<leader>gf",
        stop = "<leader>gS",
        toggle = {
          default = "<leader>gt",
          debug = "<leader>gd",
          hint = "<leader>gh",
          suggestion = "<leader>gs",
          repomap = "<leader>gR",
        },
        files = {
          add_current = "<leader>gc", -- Add current buffer to selected files
          add_all_buffers = "<leader>gB", -- Add all buffer files to selected files
        },
        select_model = "<leader>g?", -- Select model command
        select_history = "<leader>gh", -- Select history command
      },
      providers = {
        copilot = {
          enabled = true,
          model = "claude-3.5-sonnet",
          temperature = 0,
          max_tokens = 8192,
        },
      },
    },

    dependencies = {
      {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = function(_, ft)
          vim.list_extend(ft, { "Avante" })
        end,
      },
      {
        "folke/which-key.nvim",
        opts = {
          spec = {
            { "<leader>ga", group = "ai" },
          },
        },
      },
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

  {
    "saghen/blink.compat",
    lazy = true,
    opts = {},
    config = function()
      -- monkeypatch cmp.ConfirmBehavior for Avante
      require("cmp").ConfirmBehavior = {
        Insert = "insert",
        Replace = "replace",
      }
    end,
  },

  {
    "saghen/blink.cmp",
    lazy = true,
    opts = {
      sources = {
        default = { "avante_commands", "avante_mentions", "avante_files" },
        providers = {
          avante_commands = {
            name = "avante_commands",
            module = "blink.compat.source",
            score_offset = 90, -- show at a higher priority than lsp
            opts = {},
          },
          avante_files = {
            name = "avante_commands",
            module = "blink.compat.source",
            score_offset = 100, -- show at a higher priority than lsp
            opts = {},
          },
          avante_mentions = {
            name = "avante_mentions",
            module = "blink.compat.source",
            score_offset = 1000, -- show at a higher priority than lsp
            opts = {},
          },
        },
      },
    },
  },
}
