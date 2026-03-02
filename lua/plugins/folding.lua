local handler = function(virtText, lnum, endLnum, width, truncate, ctx)
  local is_diff_window = vim.api.nvim_get_option_value("diff", { win = ctx.winid })

  if is_diff_window then
    local line_count = endLnum - lnum + 1
    local text = (" ---- %d lines %s"):format(line_count, string.rep("-", 50))

    return {
      { truncate(text, width), "Folded" },
    }
  end

  local newVirtText = {}
  local suffix = (" 󰁂 %d "):format(endLnum - lnum)
  local sufWidth = vim.fn.strdisplaywidth(suffix)
  local targetWidth = width - sufWidth
  local curWidth = 0

  for _, chunk in ipairs(virtText) do
    local chunkText = chunk[1]
    local chunkWidth = vim.fn.strdisplaywidth(chunkText)

    if targetWidth > curWidth + chunkWidth then
      table.insert(newVirtText, chunk)
    else
      chunkText = truncate(chunkText, targetWidth - curWidth)
      local hlGroup = chunk[2]
      table.insert(newVirtText, { chunkText, hlGroup })
      chunkWidth = vim.fn.strdisplaywidth(chunkText)

      if curWidth + chunkWidth < targetWidth then
        table.insert(
          newVirtText,
          { (" "):rep(targetWidth - curWidth - chunkWidth), "UfoFoldedEllipsis" }
        )
      end
      break
    end

    curWidth = curWidth + chunkWidth
  end

  table.insert(newVirtText, { suffix, "MoreMsg" })
  return newVirtText
end

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
      opts.fold_virt_text_handler = handler
      require("ufo").setup(opts)
    end,
  },
}
