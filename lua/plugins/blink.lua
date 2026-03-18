return {
  "saghen/blink.cmp",
  opts = {
    sources = {
      providers = {
        -- Suggestions from words in the current buffer
        buffer = {
          enabled = function()
            -- Check buffer-local variable first, then global, default to true
            return vim.b.blink_buffer_enabled ~= false and vim.g.blink_buffer_enabled ~= false
          end,
        },
        -- Suggestions from snippets like datetime
        snippets = {
          enabled = function()
            return vim.b.blink_snippets_enabled ~= false and vim.g.blink_snippets_enabled ~= false
          end,
        },
      },
    },
  },
}
