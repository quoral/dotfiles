return {
  { "gbprod/nord.nvim" },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "nord",
    },
    init = function()
      vim.api.nvim_set_hl(0, "SnacksPickerPathHidden", { link = "Directory" })
    end,
  },
}
