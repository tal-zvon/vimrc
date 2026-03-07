-- Enable/Disable OS clipboard
_G.toggle_clipboard = function()
  local clipboard = vim.opt.clipboard:get()

  local has_unnamedplus = vim.tbl_contains(clipboard, "unnamedplus")

  if has_unnamedplus then
    vim.opt.clipboard = ""
    vim.notify("󰅌 OS Clipboard Disabled", vim.log.levels.INFO)
  else
    vim.opt.clipboard = "unnamedplus"
    vim.notify("󰅍 OS Clipboard Enabled", vim.log.levels.INFO)
  end
end

-- Allow searching of open buffers by matching the content of the buffer,
-- rather than the name of the buffer
_G.search_open_buffers_content = function()
  Snacks.picker({
    title = " Buffer Matches By Content ",
    live = true,
    layout = {
      preset = "default",
      preview = true,
    },
    format = function(item, picker)
      local icon, icon_hl = require("mini.icons").get("file", item.file)
      local icon_text = icon and (icon .. " ") or ""

      -- Handles the initial state before any search pattern is entered
      if not item._line then
        return {
          { icon_text, icon_hl },
          { item._tail or item.text, "" },
        }
      end

      -- Formats the matched line metadata (filename:line:col)
      return {
        { icon_text, icon_hl },
        { item._tail, "" },
        { ":", "Comment" },
        { tostring(item._line), "String" },
        { ":", "Comment" },
        { tostring(item._col), "String" },
      }
    end,
    finder = function(opts, ctx)
      local pattern = ctx.filter.search:lower()
      local results = {}

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        -- Filters for buffers that are currently loaded and visible to the user
        if vim.api.nvim_buf_is_loaded(buf) and vim.fn.buflisted(buf) == 1 then
          local name = vim.api.nvim_buf_get_name(buf)

          if name ~= "" then
            if pattern == "" then
              table.insert(results, {
                file = name,
                buf = buf,
                text = vim.fn.fnamemodify(name, ":t"),
              })
            else
              local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
              for i, line in ipairs(lines) do
                local init = 1
                local lower_line = line:lower()

                -- Finds all occurrences of the pattern within a single line
                while true do
                  local start_pos, end_pos = lower_line:find(pattern, init, true)
                  if not start_pos then
                    break
                  end

                  local tail = vim.fn.fnamemodify(name, ":t")

                  table.insert(results, {
                    file = name,
                    buf = buf,
                    text = line,
                    _tail = tail,
                    _line = i,
                    _col = start_pos,
                    pos = { i, start_pos - 1 },
                    end_pos = { i, end_pos },
                  })

                  init = start_pos + 1
                end
              end
            end
          end
        end
      end
      return results
    end,
  })
end

return {
  {
    "LazyVim/LazyVim",
    keys = {
      {
        "<leader>uy",
        toggle_clipboard,
        desc = "Toggle OS Clipboard",
      },
      {
        "<leader>m",
        search_open_buffers_content,
        desc = "Search Open Buffers by Content",
      },
    },
  },
}
