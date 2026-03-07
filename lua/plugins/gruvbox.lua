return {
  {
    "ellisonleao/gruvbox.nvim",
    enabled = false, -- set to true to enable gruvbox
    priority = 1000, -- load this before most other plugins
    lazy = false,
    config = function()
      vim.opt.background = "dark"
      vim.cmd.colorscheme("gruvbox")
    end,
  },
}
