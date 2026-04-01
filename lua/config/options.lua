local o = vim.opt
local g = vim.g

-- #####################
-- ##### My config #####
-- #####################

-- Disable incremental search
-- Note: I'll try getting used to it
-- o.incsearch = false

-- show existing tab with 4 spaces width
o.tabstop = 4

-- When you hit tab to add 4 spaces, with this, backspace will delete 4 spaces
o.softtabstop=4

-- when indenting with '>', use 4 spaces width
o.shiftwidth=4

-- On pressing tab, insert 4 spaces
o.expandtab = true

-- Length of idle time before vim writes to the swapfile
-- Also controls how often vim updates git tags in gitgutter bar
-- o.updatetime = 100

-- Set text width
-- For gt and gw, the number of characters to consider a single line
-- 75 replicates GNU fmt, and works well. The default is too long in
-- my vim, where I have a gutter with line numbers showing
-- Note: Setting textwidth also enables automatic newlines as you type.
-- fo-=tc disables that. See: https://vi.stackexchange.com/a/28725/32517
o.formatexpr = ""
o.textwidth = 75
o.formatoptions:remove({ "t", "c" })

-- Disable auto-comment on Enter and on o/O
o.formatoptions:remove({ "r", "o" })

-- Disable automatic formatting on save
g.autoformat = false

-- Don't keep an undo file so undo history is in RAM only
o.undofile = false

-- Add border around windows like Code Diagnostic window (<leader>cd)
o.winborder = "rounded"

-- Start with internal clipboard only
-- We will have a key binding to switch to unnamedplus
o.clipboard = ""

-- List characters
-- Note: Tab filler characters are visually overlapping with snacks
-- indentation guides, so I set them to two spaces instead of a visible
-- character
o.listchars = {
  tab = "  ",
  nbsp = "␣",
  trail = " ",
}
