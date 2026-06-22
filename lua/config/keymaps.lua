local map = vim.keymap.set

map("n", "<Tab>", ">>", { desc = "Indent current line" })
map("n", "<S-Tab>", "<<", { desc = "Dedent current line" })

map("x", "<Tab>", ">gv", { desc = "Indent selected lines" })
map("x", "<S-Tab>", "<gv", { desc = "Dedent selected lines" })

-- In diff mode, open/close all folds across every diff window in the tab so
-- both sides of a side-by-side diff stay in sync. Outside diff, behaves like
-- the native zR/zM on the current window. See plugins/utils/folding.lua.
map("n", "zR", function()
  require("plugins.utils.folding").fold_all(true)
end, { desc = "Open all folds (all diff windows)" })
map("n", "zM", function()
  require("plugins.utils.folding").fold_all(false)
end, { desc = "Close all folds (all diff windows)" })

-- zO/zC on a fold's header line should open/close the whole fold tree
-- (including nested folds). Native zO/zC ignore folds that don't contain the
-- cursor line, so on a class header they leave the methods untouched.
map("n", "zO", function()
  require("plugins.utils.folding").fold_open_recursive()
end, { desc = "Open fold under cursor recursively" })
map("n", "zC", function()
  require("plugins.utils.folding").fold_close_recursive()
end, { desc = "Close fold under cursor recursively" })
