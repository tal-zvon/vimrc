local M = {}

-- Build syntax-highlighted virtual-text chunks for a single buffer line using
-- treesitter captures, so a custom foldtext can keep the line's highlighting.
---@param chunks table list of { text, hlgroup } chunks to append to
---@param bufnr integer
---@param row integer 0-based line number
---@param line string the text of that line
local function add_highlighted_chunks(chunks, bufnr, row, line)
  local tabstop = vim.bo[bufnr].tabstop
  local prev_hl
  local text = ""

  for col = 0, #line - 1 do
    local char = line:sub(col + 1, col + 1)
    if char == "\t" then
      char = string.rep(" ", tabstop)
    end

    local captures = vim.treesitter.get_captures_at_pos(bufnr, row, col)
    local hl = "Normal"
    if #captures > 0 then
      hl = "@" .. captures[#captures].capture
    end

    if hl ~= prev_hl then
      if #text > 0 then
        table.insert(chunks, { text, prev_hl })
      end
      text = ""
      prev_hl = hl
    end
    text = text .. char
  end

  if #text > 0 then
    table.insert(chunks, { text, prev_hl })
  end
end

-- Custom 'foldtext'. Returns a list of { text, hlgroup } chunks (rendered as
-- overlay virtual text). Mirrors the previous nvim-ufo fold text:
--   * normal windows: the (highlighted) first fold line + a 󰁂 <count> suffix
--   * diff windows:    a "---- N lines ----" marker
function M.foldtext()
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.v.foldstart
  local end_lnum = vim.v.foldend
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""

  if vim.wo.diff then
    local line_count = end_lnum - lnum + 1
    local text = (" ---- %d lines %s"):format(line_count, string.rep("-", 50))
    return { { text, "Folded" } }
  end

  local chunks = {}
  add_highlighted_chunks(chunks, bufnr, lnum - 1, line)
  table.insert(chunks, { (" 󰁂 %d "):format(end_lnum - lnum), "MoreMsg" })
  return chunks
end

-- Recursively open or close the whole fold under the cursor (including nested
-- folds), even when the cursor is on the fold's first/header line.
--
-- Native zO/zC only act on folds that *contain* the cursor line, so on a class
-- header line they leave the method folds (which start on the next line)
-- untouched. We instead operate on the fold's entire line range:
--   * zO on a class header opens the class and all its methods
--   * zC on a class header closes the class and all its methods, so reopening
--     the class with zo still shows the methods folded
---@param open boolean true => open recursively (zO), false => close (zC)
local function fold_recursive(open)
  local line = vim.fn.line(".")
  if vim.fn.foldlevel(line) == 0 then
    return
  end

  -- foldclosed/foldclosedend only report a range when the fold is closed, so
  -- briefly close an open fold to read its extent (no redraw happens in between
  -- so this is invisible to the user).
  if vim.fn.foldclosed(line) == -1 then
    vim.cmd("normal! zc")
  end

  local start_line = vim.fn.foldclosed(line)
  local end_line = vim.fn.foldclosedend(line)
  if start_line == -1 then
    return
  end

  local action = open and "foldopen" or "foldclose"
  vim.cmd(("%d,%d%s!"):format(start_line, end_line, action))
end

function M.fold_open_recursive()
  fold_recursive(true)
end

function M.fold_close_recursive()
  fold_recursive(false)
end

-- Open/close all folds. In a diff window this acts on every diff window in the
-- current tab page so both sides of a side-by-side diff stay in sync;
-- otherwise it behaves like the native zR/zM on the current window only.
---@param open boolean true => open all (zR), false => close all (zM)
function M.fold_all(open)
  local cmd = open and "normal! zR" or "normal! zM"

  if not vim.wo.diff then
    vim.cmd(cmd)
    return
  end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.wo[win].diff then
      vim.api.nvim_win_call(win, function()
        vim.cmd(cmd)
      end)
    end
  end
end

return M
