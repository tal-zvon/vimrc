return {
  {
    "LazyVim/LazyVim",
    keys = {
      {
        "<leader>uy",
        function()
          local clipboard = vim.opt.clipboard:get()

          local has_unnamedplus = vim.tbl_contains(clipboard, "unnamedplus")

          if has_unnamedplus then
            vim.opt.clipboard = ""
            vim.notify("󰅌 OS Clipboard Disabled", vim.log.levels.INFO)
          else
            vim.opt.clipboard = "unnamedplus"
            vim.notify("󰅍 OS Clipboard Enabled", vim.log.levels.INFO)
          end
        end,
        desc = "Toggle OS Clipboard",
      },
    },
  },
}
