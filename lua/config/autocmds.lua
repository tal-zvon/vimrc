-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Disable diagnostics when in diff mode
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.wo.diff then
      vim.diagnostic.disable()
    end
  end,
})

-- Show nicer fold text in diff mode
_G.MyFoldText = function()
  local line_count = vim.v.foldend - vim.v.foldstart + 1
  return "---- " .. line_count .. "  lines " .. string.rep("-", 50)
end

vim.api.nvim_create_autocmd({ "DiffUpdated", "WinEnter" }, {
  group = vim.api.nvim_create_augroup("DiffFoldText", { clear = true }),
  callback = function()
    -- Loop through every window in the current tab
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      -- Check if that specific window is in diff mode
      if vim.api.nvim_get_option_value("diff", { win = win }) then
        vim.api.nvim_set_option_value("foldtext", "v:lua.MyFoldText()", { win = win })
      else
        vim.api.nvim_set_option_value("foldtext", "foldtext()", { win = win })
      end
    end
  end,
})

