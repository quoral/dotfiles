return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    local configs = require("lspconfig.configs")
    local util = require("lspconfig.util")
    opts.inlay_hints = { enabled = false }
    configs.pyrefly = {
      default_config = {
        cmd = { "uvx", "pyrefly", "lsp" },
        filetypes = { "python" },
        root_dir = util.root_pattern(".git", "pyproject.toml"),
      },
    }

    opts.servers = opts.servers or {}
    opts.servers.pyrefly = opts.servers.pyrefly or {}
  end,
}
