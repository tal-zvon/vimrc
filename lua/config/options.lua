local o = vim.opt

-- #####################
-- ##### My config #####
-- #####################

-- Disable incremental search
-- Note: I'll try getting used to it
-- o.incsearch = false

-- show existing tab with 4 spaces width
o.tabstop = 4

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