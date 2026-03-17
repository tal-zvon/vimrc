if not vim.g.neovide then
  return
end

vim.b.copilot_enabled = 0
vim.g.neovide_scale_factor = 2.0
vim.opt.swapfile = false       -- Disables .swp files used for recovery

vim.keymap.set({ "n", "v", "s", "x", "o", "i", "l", "c", "t" }, "<D-v>", function()
  vim.api.nvim_paste(vim.fn.getreg("+"), true, -1)
end, { noremap = true, silent = true })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- 1. Enable Auto-Draft Mode
    local ok, lazyvim_utils = pcall(require, "plugins.utils.lazyvim")
    if ok and lazyvim_utils.toggle_auto_draft then
      lazyvim_utils.toggle_auto_draft()
    end

    -- 2. Open project and restore session
    local project_path = vim.fn.expand("~/Documents/Old Sublime Tabs/")
    if vim.fn.isdirectory(project_path) == 1 then
      vim.api.nvim_set_current_dir(project_path)

      -- Try to restore session
      local has_persistence, persistence = pcall(require, "persistence")
      if has_persistence then
        persistence.load()
      end
    end
  end,
})
