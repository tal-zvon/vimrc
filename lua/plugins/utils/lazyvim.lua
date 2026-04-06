local M = {}

local auto_draft_enabled = false

-- Expand the ~ to a full path, then resolve any symlinks
local raw_folder = vim.fn.expand("~/Documents/Old Sublime Tabs/old_neovide_tabs/")
local draft_folder = vim.fn.resolve(raw_folder)

-- Ensure the resolved path still ends with a trailing slash for safe matching
if not vim.endswith(draft_folder, "/") then
  draft_folder = draft_folder .. "/"
end

local function get_next_draft_path()
  if vim.fn.isdirectory(draft_folder) == 0 then
    vim.fn.mkdir(draft_folder, "p")
  end

  local files = vim.fn.readdir(draft_folder)
  local max_num = 0

  for _, file in ipairs(files) do
    local name = file:match("^(%d+)%.") or file:match("^(%d+)$")
    if name then
      local num = tonumber(name)
      if num > max_num then
        max_num = num
      end
    end
  end

  local next_num = max_num + 1
  local new_path = draft_folder .. next_num .. ".md"

  -- Keep incrementing until we find a name that is completely free
  -- on both the disk AND in Neovim's internal buffer list.
  while vim.fn.bufexists(new_path) == 1 or vim.fn.filereadable(new_path) == 1 do
    next_num = next_num + 1
    new_path = draft_folder .. next_num .. ".md"
  end

  return new_path
end

function M.toggle_auto_draft()
  auto_draft_enabled = not auto_draft_enabled
  local state = auto_draft_enabled and "Enabled" or "Disabled"
  vim.notify("Auto-Draft Mode: " .. state, vim.log.levels.INFO)
end

-- Catch when you enter an unnamed, empty buffer
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    if not auto_draft_enabled then
      return
    end

    local buf = args.buf
    local buftype = vim.bo[buf].buftype
    local bufname = vim.api.nvim_buf_get_name(buf)

    if buftype == "" and bufname == "" then
      vim.bo[buf].filetype = "markdown"
      vim.b[buf].autoformat = false

      local new_path = get_next_draft_path()
      vim.api.nvim_buf_set_name(buf, new_path)
      vim.notify("New draft created: " .. new_path, vim.log.levels.INFO)
      vim.cmd("noautocmd silent! write")
    end
  end,
})

-- Auto-save when leaving insert mode or making normal mode changes
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  callback = function(args)
    if not auto_draft_enabled then
      return
    end

    -- Check if Neovim registers unsaved changes. If not, do nothing.
    if not vim.bo[args.buf].modified then
      return
    end

    local buf_name = vim.api.nvim_buf_get_name(args.buf)

    -- Ignore completely empty/unnamed buffers
    if buf_name == "" then
      return
    end

    -- Get the canonical path of the current buffer to bypass symlinks
    local resolved_buf_name = vim.fn.resolve(buf_name)

    -- Check if the canonical buffer path starts with the canonical draft folder path
    if vim.startswith(resolved_buf_name, draft_folder) then
      vim.notify("Auto-saving draft: " .. buf_name, vim.log.levels.INFO)

      -- :update only writes if the file is modified, and automatically clears the modified flag
      vim.cmd("noautocmd silent! update")
    end
  end,
})

function M.toggle_clipboard()
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

return M
