local M = {}

local function is_symbol_boundary(text, pos)
  if pos <= 1 then
    return true
  end

  local prev = text:sub(pos - 1, pos - 1)
  local current = text:sub(pos, pos)

  if prev:match("[^%w]") then
    return true
  end

  if prev:match("%l") and current:match("%u") then
    return true
  end

  if prev:match("%d") and current:match("%a") then
    return true
  end

  return false
end

local function count_case_mismatches(name, query, positions)
  local mismatches = 0

  for i, pos in ipairs(positions) do
    if name:sub(pos, pos) ~= query:sub(i, i) then
      mismatches = mismatches + 1
    end
  end

  return mismatches
end

local function compare_rank(left, right)
  if right == nil then
    return true
  end

  for _, field in ipairs({
    "kind",
    "case_mismatches",
    "boundary_rank",
    "gaps",
    "start",
    "span",
  }) do
    if left[field] ~= right[field] then
      return left[field] < right[field]
    end
  end

  return false
end

local function make_rank(name, query, positions, kind)
  local start = positions[1]
  local finish = positions[#positions]
  local gaps = 0

  for i = 2, #positions do
    gaps = gaps + positions[i] - positions[i - 1] - 1
  end

  return {
    kind = kind,
    case_mismatches = count_case_mismatches(name, query, positions),
    boundary_rank = is_symbol_boundary(name, start) and 0 or 1,
    gaps = gaps,
    start = start,
    span = finish - start,
  }
end

local function best_contiguous_rank(name, query)
  local name_lower = name:lower()
  local query_lower = query:lower()
  local best
  local from = 1

  while true do
    local start = name_lower:find(query_lower, from, true)
    if not start then
      return best
    end

    local positions = {}
    for offset = 0, #query - 1 do
      positions[#positions + 1] = start + offset
    end

    local kind = 2
    if start == 1 then
      kind = #name == #query and 0 or 1
    end

    local rank = make_rank(name, query, positions, kind)
    if compare_rank(rank, best) then
      best = rank
    end

    from = start + 1
  end
end

local function best_subsequence_rank(name, query)
  local name_lower = name:lower()
  local query_lower = query:lower()
  local best
  local start_from = 1

  while true do
    local first = name_lower:find(query_lower:sub(1, 1), start_from, true)
    if not first then
      return best
    end

    local positions = { first }
    local search_from = first + 1
    local matched = true

    for i = 2, #query_lower do
      local pos = name_lower:find(query_lower:sub(i, i), search_from, true)
      if not pos then
        matched = false
        break
      end

      positions[#positions + 1] = pos
      search_from = pos + 1
    end

    if matched then
      local rank = make_rank(name, query, positions, 3)
      if compare_rank(rank, best) then
        best = rank
      end
    end

    start_from = first + 1
  end
end

local function apply_rank(item, query, rank)
  local name = item.name or item.text or ""

  item.workspace_has_query = query == "" and 1 or 0
  item.workspace_match_kind = rank and rank.kind or 99
  item.workspace_case_mismatches = rank and rank.case_mismatches or 99
  item.workspace_boundary_rank = rank and rank.boundary_rank or 99
  item.workspace_gaps = rank and rank.gaps or math.huge
  item.workspace_start = rank and rank.start or math.huge
  item.workspace_span = rank and rank.span or math.huge
  item.workspace_sort_text = query == "" and "" or name
  item.workspace_sort_name = query == "" and "" or name:lower()
end

function M.rank_workspace_symbol(item, ctx)
  local query = vim.trim(ctx.filter.search or "")
  local name = item.name or item.text or ""

  if query == "" or name == "" then
    apply_rank(item, query, nil)
    return item
  end

  local rank = best_contiguous_rank(name, query) or best_subsequence_rank(name, query)
  apply_rank(item, query, rank)
  return item
end

return M
