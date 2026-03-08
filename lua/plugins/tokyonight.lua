return {
  {
    "folke/tokyonight.nvim",
    opts = {
      on_highlights = function(hl, colors)
        -------------------------------------------------------------------------------
        -- Fix tokyonight theme's imports line so they don't all look the same color --
        -------------------------------------------------------------------------------

        hl["@module.python"] = { fg = colors.blue }
        hl["@type.python"] = { fg = colors.orange }

        ----------------------------------
        -- Highlight Bad Whitespace Red --
        ----------------------------------

        -- Show whitespace characters
        -- This applies to anything in listchars, which includes tabs, trailing
        -- spaces, and non-breaking spaces (invisible unicode characters that look
        -- like a space, but are not treated as whitespace by most tools)
        hl.Whitespace = { bg = "#ff0000", bold = true }

        -------------------------------------------------------
        -- Fix diff so it's not a mess of distracting colors --
        -------------------------------------------------------

        -- The folded line
        hl.Folded = { bg = "#151724", fg = colors.comment, italic = true }

        -- The added line
        --hl.DiffAdd = { bg = "#ff0000" }

        -- The modified line background
        hl.DiffChange = { bg = "#2a4556" }

        -- The specific "word" highlight
        hl.DiffText = { bg = "#3d59a1", fg = colors.orange, bold = true }
      end,
    },
  },
}
