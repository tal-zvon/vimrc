-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local function disable_diagnostics(bufnr)
  if vim.diagnostic.disable then
    vim.diagnostic.disable(bufnr)
  else
    vim.diagnostic.enable(false, bufnr and { bufnr = bufnr } or nil)
  end
end

-- Disable diagnostics when in diff mode
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.wo.diff then
      disable_diagnostics()
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  callback = function(args)
    if vim.bo[args.buf].filetype == "markdown" then
      disable_diagnostics(args.buf)
    end
  end,
})
