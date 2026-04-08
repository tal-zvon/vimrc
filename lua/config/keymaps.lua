local map = vim.keymap.set

map("n", "<Tab>", ">>", { desc = "Indent current line" })
map("n", "<S-Tab>", "<<", { desc = "Dedent current line" })

map("x", "<Tab>", ">gv", { desc = "Indent selected lines" })
map("x", "<S-Tab>", "<gv", { desc = "Dedent selected lines" })
