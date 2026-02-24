-- Show the class or function you're in if it spans more than one page

return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    opts = {
      enable = true,
      max_lines = 3,      -- how many context lines to show
      trim_scope = "outer",
      mode = "cursor",    -- or "topline"
      separator = "-",    -- set to nil if you don't want a divider
    },
  },
}
