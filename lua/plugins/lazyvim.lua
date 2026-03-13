local lazyvim_utils = require("plugins.utils.lazyvim")

return {
  {
    "LazyVim/LazyVim",
    keys = {
      {
        "<leader>uy",
        lazyvim_utils.toggle_clipboard,
        desc = "Toggle OS Clipboard",
      },
      {
        "<leader>m",
        lazyvim_utils.search_open_buffers_content,
        desc = "Search Open Buffers by Content",
      },
      { "<leader>uu", lazyvim_utils.toggle_auto_draft, desc = "Toggle Auto-Draft Mode" },
    },
  },
}
