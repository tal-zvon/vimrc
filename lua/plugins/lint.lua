local function is_executable(path)
  return path ~= nil and path ~= "" and vim.uv.fs_stat(path) ~= nil
end

local function project_root(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return vim.fn.getcwd()
  end

  return vim.fs.root(name, {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
  }) or vim.fn.getcwd()
end

local function python_from_venv(root)
  local candidates = {}

  if vim.env.VIRTUAL_ENV then
    candidates[#candidates + 1] = vim.fs.joinpath(vim.env.VIRTUAL_ENV, "bin", "python")
  end

  for _, dir in ipairs({ ".venv", "venv", ".virtualenv" }) do
    candidates[#candidates + 1] = vim.fs.joinpath(root, dir, "bin", "python")
  end

  for _, path in ipairs(candidates) do
    if is_executable(path) then
      return path
    end
  end

  return ""
end

local function mason_mypy()
  local path = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin", "mypy")
  if is_executable(path) then
    return path
  end

  return vim.fn.exepath("mypy")
end

local function mypy_linter()
  local bufnr = vim.api.nvim_get_current_buf()
  local root = project_root(bufnr)
  local python = python_from_venv(root)

  -- 1. Define the base command and arguments once
  local cmd = "mypy"
  local args = {
    "--show-column-numbers",
    "--show-error-end",
    "--hide-error-context",
    "--no-color-output",
    "--no-error-summary",
    "--no-pretty",
    "--show-error-codes", -- CRITICAL FIX: Forces error codes so the regex parser never fails
  }

  -- 2. Modify the command and args dynamically based on environment
  if python ~= "" then
    cmd = python
    table.insert(args, 1, "mypy")
    table.insert(args, 1, "-m")
  else
    local mason_bin = mason_mypy()
    if mason_bin ~= "" then
      cmd = mason_bin
    end
  end

  -- 3. Return the single, consolidated linter definition
  return {
    cmd = cmd,
    stdin = false,
    stream = "both",
    ignore_exitcode = true,
    cwd = root,
    args = args,
    parser = require("lint.parser").from_pattern(
      "([^:]+):(%d+):(%d+):(%d+):(%d+): (%a+): (.*) %[(%a[%a-]+)%]",
      { "file", "lnum", "col", "end_lnum", "end_col", "severity", "message", "code" },
      {
        error = vim.diagnostic.severity.ERROR,
        warning = vim.diagnostic.severity.WARN,
        note = vim.diagnostic.severity.HINT,
      },
      { source = "mypy" },
      { end_col_offset = 0 }
    ),
  }
end

return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    opts = {
      linters_by_ft = {
        python = { "mypy" },
      },
    },
    config = function(_, opts)
      local lint = require("lint")

      lint.linters.mypy = mypy_linter

      lint.linters_by_ft = lint.linters_by_ft or {}
      for filetype, linters in pairs(opts.linters_by_ft or {}) do
        lint.linters_by_ft[filetype] = vim.list_extend(lint.linters_by_ft[filetype] or {}, linters)
      end

      vim.api.nvim_create_autocmd(opts.events or { "BufEnter", "BufWritePost", "InsertLeave" }, {
        callback = function()
          lint.try_lint()
        end,
      })

      vim.schedule(function()
        lint.try_lint()
      end)
    end,
  },
}
