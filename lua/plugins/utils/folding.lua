local M = {}

-- Cache of computed foldtext chunks, keyed by buffer.
--
-- Neovim recomputes 'foldtext' for every visible closed fold on *every* redraw.
-- Building the highlighted header is relatively expensive (treesitter), so when
-- many folds are on screen (e.g. a class folded down to its method headers),
-- holding j/Down would recompute all of them per frame -- causing lag and
-- half-drawn ("torn") frames. The fold header text only changes when the buffer
-- changes, so we cache per (buffer, changedtick, fold start line): redraws while
-- scrolling reuse the cached chunks, and only a fold newly scrolled into view is
-- recomputed.
---@type table<integer, { tick: integer, lines: table<integer, table> }>
local foldtext_cache = {}

vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
  group = vim.api.nvim_create_augroup("custom_foldtext_cache", { clear = true }),
  callback = function(args)
    foldtext_cache[args.buf] = nil
  end,
})

-- Build syntax-highlighted virtual-text chunks for a single buffer line using
-- treesitter captures, so a custom foldtext can keep the line's highlighting.
--
-- Uses a single treesitter query pass over just this row (rather than one
-- get_captures_at_pos() call per column), which is dramatically cheaper on wide
-- lines and when many folds are visible at once. Later captures overwrite
-- earlier ones, matching the previous "last capture at position wins" behavior.
-- Falls back to a single unhighlighted chunk when no parser/highlights query is
-- available.
---@param bufnr integer
---@param row integer 0-based line number
---@param line string the text of that line
---@return table chunks list of { text, hlgroup }
local function line_highlight_chunks(bufnr, row, line)
  local tabstop = vim.bo[bufnr].tabstop

  -- Per-column highlight group; unset columns render as "Normal".
  local col_hl = {}

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if ok and parser then
    parser:parse({ row, row + 1 })
    parser:for_each_tree(function(tstree, ltree)
      local query = vim.treesitter.query.get(ltree:lang(), "highlights")
      if not query then
        return
      end
      for id, node in query:iter_captures(tstree:root(), bufnr, row, row + 1) do
        local capture = query.captures[id]
        if capture then
          local start_row, start_col, end_row, end_col = node:range()
          local scol = (start_row == row) and start_col or 0
          local ecol = (end_row == row) and end_col or #line
          local hl = "@" .. capture
          for col = scol, ecol - 1 do
            col_hl[col] = hl
          end
        end
      end
    end)
  end

  -- Coalesce consecutive same-highlight columns into chunks, expanding tabs.
  local chunks = {}
  local text = ""
  local prev_hl
  for col = 0, #line - 1 do
    local char = line:sub(col + 1, col + 1)
    if char == "\t" then
      char = string.rep(" ", tabstop)
    end

    local hl = col_hl[col] or "Normal"
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

  return chunks
end

-- Custom 'foldtext'. Returns a list of { text, hlgroup } chunks (rendered as
-- overlay virtual text). Mirrors the previous nvim-ufo fold text:
--   * normal windows: the (highlighted) first fold line + a 󰁂 <count> suffix
--   * diff windows:    a "---- N lines ----" marker
function M.foldtext()
  local bufnr = vim.api.nvim_get_current_buf()
  local lnum = vim.v.foldstart
  local end_lnum = vim.v.foldend

  -- Diff marker is cheap; no need to cache it.
  if vim.wo.diff then
    local line_count = end_lnum - lnum + 1
    local text = (" ---- %d lines %s"):format(line_count, string.rep("-", 50))
    return { { text, "Folded" } }
  end

  local tick = vim.b[bufnr].changedtick
  local entry = foldtext_cache[bufnr]
  if not entry or entry.tick ~= tick then
    entry = { tick = tick, lines = {} }
    foldtext_cache[bufnr] = entry
  elseif entry.lines[lnum] then
    return entry.lines[lnum]
  end

  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
  local chunks = line_highlight_chunks(bufnr, lnum - 1, line)
  table.insert(chunks, { (" 󰁂 %d "):format(end_lnum - lnum), "MoreMsg" })

  entry.lines[lnum] = chunks
  return chunks
end

-- Two-tier "outer layer" folding for zO/zC.
--
-- We treat folds as two tiers by nesting depth:
--   * "class"  = the outermost fold containing the cursor (fold level 1)
--   * "method" = the fold nested one level directly inside it (fold level 2)
-- zO/zC always act on the *whole* enclosing method when the cursor is anywhere
-- inside one (its body, a deeply nested block, or its multi-line signature), and
-- on the whole class only when the cursor is at class-body/header level (not
-- inside any method). Sibling and ancestor folds are always left untouched.
--
-- Why this can't use native zc/zC/zO or a plain foldclose!/foldopen!:
-- a multi-line signature creates a nested parameter-list fold, so a method's
-- `def` line can sit at fold level 3 (inside that param-list fold) even though
-- the method fold is level 2. That makes native `zc` close only the param list,
-- and native `zC` / `:foldclose!` climb outward and collapse the whole class.
-- We instead compute the target tier's line range directly from fold levels.

-- Line range [s, e] of the fold to operate on, plus its tier level L.
-- L = 2 (method) when the cursor is inside a method (fold level >= 2), else
-- L = 1 (class). The range is grown outward while the fold level stays >= L, so
-- a multi-line signature (whose def line is at a deeper level) is still fully
-- covered. Returns nil when the cursor is not inside any fold.
---@return integer? start, integer? end_, integer? level
local function target_range()
  local line = vim.fn.line(".")
  local level = vim.fn.foldlevel(line)
  if level == 0 then
    return nil
  end

  local L = level >= 2 and 2 or 1
  local last = vim.fn.line("$")
  local s, e = line, line
  while s > 1 and vim.fn.foldlevel(s - 1) >= L do
    s = s - 1
  end
  while e < last and vim.fn.foldlevel(e + 1) >= L do
    e = e + 1
  end
  return s, e, L
end

-- Close the target fold [s, e] and all of its descendants, deepest-first, using
-- `zc`. `zc` only ever closes the innermost OPEN fold at the cursor and never an
-- ancestor, and every line in [s, e] has fold level >= L, so this can never
-- climb out to the enclosing class or touch siblings. Deepest-first ordering
-- means nested folds are closed before the target, so a later `zo` of the target
-- reveals its internals still folded.
---@param s integer fold start line
---@param e integer fold end line
---@param L integer target tier fold level
local function close_within(s, e, L)
  local max_level = 0
  for l = s, e do
    max_level = math.max(max_level, vim.fn.foldlevel(l))
  end

  for level = max_level, L, -1 do
    for l = s, e do
      if vim.fn.foldclosed(l) == -1 and vim.fn.foldlevel(l) == level then
        vim.fn.cursor(l, 1)
        vim.cmd("normal! zc")
      end
    end
  end

  -- Fallback: close the target fold itself when no line has a structural level
  -- equal to L (e.g. a method whose entire body lives inside deeper folds).
  vim.fn.cursor(s, 1)
  while not (vim.fn.foldclosed(s) == s and vim.fn.foldclosedend(s) == e) do
    local before = vim.fn.foldclosedend(s)
    vim.cmd("normal! zc")
    local closed = vim.fn.foldclosed(s)
    if vim.fn.foldclosedend(s) == before or vim.fn.foldclosedend(s) > e or (closed ~= -1 and closed < s) then
      break
    end
  end
end

function M.fold_open_recursive()
  local view = vim.fn.winsaveview()
  local s, e = target_range()
  if s then
    -- Bang opens all descendant folds within the range.
    vim.cmd(("%d,%dfoldopen!"):format(s, e))
  end
  vim.fn.winrestview(view)
end

function M.fold_close_recursive()
  local view = vim.fn.winsaveview()
  local s, e, L = target_range()
  if s then
    close_within(s, e, L)
  end
  vim.fn.winrestview(view)
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
