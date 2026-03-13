local folding_utils = require("plugins.utils.folding")

return {
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    event = "BufReadPost", -- Load when you open a file
    opts = {
      provider_selector = function(bufnr, filetype, buftype)
        -- Use LSP first, fallback to Treesitter, then Indent
        return { "lsp", "indent" }
      end,
    },
    config = function(_, opts)
      -- Fold settings for nvim-ufo
      vim.o.foldcolumn = "1" -- '0' is not show, '1' shows a small column
      vim.o.foldlevel = 99 -- Using ufo provider need a large value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      -- Option: Custom handler to show line count at the end of the fold in diff mode
      opts.fold_virt_text_handler = folding_utils.fold_virt_text_handler
      require("ufo").setup(opts)
    end,
  },
}
