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
        hl.DiffText = { bg = "#51576d", fg = colors.orange, bold = true }
      end,
    },
  },
}
