return {
  "folke/snacks.nvim",
  opts = {
    indent = {
      enabled = true,
      filter = function(buf)
        -- Check if 'diff' is active in the current window
        return not vim.wo.diff
      end,
    },
    scope = {
      enabled = true,
      filter = function(buf)
        -- Check if 'diff' is active in the current window
        return not vim.wo.diff
      end,
    },
    picker = {
      win = {
        input = {
          keys = {
            -- Key to focus the preview
            ["<c-w>"] = { "focus_preview", mode = { "i", "n" } },
          },
        },
        preview = {
          wo = {
            wrap = true,
            linebreak = true, -- optional, nicer wrapping
          },
        },
      },
    },
  },
}
