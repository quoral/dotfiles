--[[
Python language support
--]]

return {

  -- Add languages to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, { "ninja", "python", "rst", "toml" })
    end,
  },

  -- Configure language server
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          keys = {
            { "<leader>cD", "<cmd>Neogen<cr>", desc = "Generate Docs", mode = { "n" } },
          },
        },
      },
    },
  },

  -- Configure debug adapter
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      "mfussenegger/nvim-dap-python",
      config = function()
        local path = require("mason-registry").get_package("debugpy"):get_install_path()
        require("dap-python").setup(path .. "/venv/bin/python")
        require("dap.ext.vscode").load_launchjs()
      end,
    },
  },
  {
    "mfussenegger/nvim-dap-python",
    lazy = true,
    config = function()
      require("dap-python").setup("uv")
    end,
    -- Consider the mappings at
    -- https://github.com/mfussenegger/nvim-dap-python?tab=readme-ov-file#mappings
    dependencies = {
      "mfussenegger/nvim-dap",
    },
  },
  -- Configure test runner
  {
    "nvim-neotest/neotest",
    optional = true,
    dependencies = { "nvim-neotest/neotest-python" },
    opts = {
      adapters = {
        ["neotest-python"] = {
          runner = "pytest",
          args = { "--log-level", "DEBUG" },
          dap = { justMyCode = true },
        },
      },
    },
  },
}
