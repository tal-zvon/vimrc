return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000, -- load this before most other plugins
    lazy = false,
    config = function()
      vim.opt.background = "dark"
      vim.cmd.colorscheme("gruvbox")
    end
  },
}
