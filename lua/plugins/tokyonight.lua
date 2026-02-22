return {
	-- Fix tokyonight theme's imports line so they don't all look the same color
	{
		"folke/tokyonight.nvim",
		opts = {
			on_highlights = function(hl, colors)
				hl["@module.python"] = { fg = colors.blue }
				hl["@type.python"] = { fg = colors.orange }
			end,
		},
	},
}
