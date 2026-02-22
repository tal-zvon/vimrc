local uv = vim.uv or vim.loop

local SUCCESS_BACKOFF_SECONDS = 60 * 60
local FAILURE_BACKOFF_SECONDS = 15 * 60
local FAILURE_NOTIFY_COOLDOWN_SECONDS = 60 * 60

local UPDATE_REPO_URL = "https://github.com/tal-zvon/vimrc.git"
local NOTIFY_TITLE = "Neovim Config Auto-Update"

local state_directory = vim.fn.stdpath("state")
local state_file_path = state_directory .. "/vimrc_auto_update.json"

local function now_epoch()
  return os.time()
end

local function notify(message, level)
  -- LazyVim.notify(msg, opts) where opts.level is the level
  if _G.LazyVim and type(_G.LazyVim.notify) == "function" then
    local ok = pcall(_G.LazyVim.notify, message, {
      title = NOTIFY_TITLE,
      level = level,
    })
    if ok then
      return
    end
  end

  -- Fallback: vim.notify(msg, level, opts)
  pcall(vim.notify, message, level, { title = NOTIFY_TITLE })
end

local function ensure_state_directory_exists()
  vim.fn.mkdir(state_directory, "p")
end

local function read_state()
  local default_state = {
    next_check_epoch = 0,
    last_failure_notify_epoch = 0,
  }

  if not uv.fs_stat(state_file_path) then
    return default_state
  end

  local ok_read, lines = pcall(vim.fn.readfile, state_file_path)
  if not ok_read or type(lines) ~= "table" or #lines == 0 then
    return default_state
  end

  local json_string = table.concat(lines, "\n")
  local ok_decode, decoded = pcall(vim.json.decode, json_string)
  if not ok_decode or type(decoded) ~= "table" then
    return default_state
  end

  if type(decoded.next_check_epoch) ~= "number" then
    decoded.next_check_epoch = default_state.next_check_epoch
  end
  if type(decoded.last_failure_notify_epoch) ~= "number" then
    decoded.last_failure_notify_epoch = default_state.last_failure_notify_epoch
  end

  return decoded
end

local function write_state(state)
  ensure_state_directory_exists()
  local json_string = vim.json.encode(state)
  vim.fn.writefile({ json_string }, state_file_path)
end

local function maybe_notify_failure_throttled(state, message)
  local current_time = now_epoch()
  local last_time = state.last_failure_notify_epoch or 0

  if (current_time - last_time) < FAILURE_NOTIFY_COOLDOWN_SECONDS then
    return
  end

  state.last_failure_notify_epoch = current_time
  write_state(state)

  notify(message, vim.log.levels.WARN)
end

local function set_next_check(state, seconds_from_now)
  state.next_check_epoch = now_epoch() + seconds_from_now
  write_state(state)
end

local has_vim_system = type(vim.system) == "function"

local function run_command(command_args, cwd, on_complete)
  if has_vim_system then
    vim.system(command_args, { cwd = cwd, text = true }, function(result)
      vim.schedule(function()
        on_complete(result.code or 1, result.stdout or "", result.stderr or "")
      end)
    end)
    return
  end

  local stdout_lines = {}
  local stderr_lines = {}

  local job_id = vim.fn.jobstart(command_args, {
    cwd = cwd,
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if type(data) == "table" then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stdout_lines, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if type(data) == "table" then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(stderr_lines, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      vim.schedule(function()
        on_complete(exit_code or 1, table.concat(stdout_lines, "\n"), table.concat(stderr_lines, "\n"))
      end)
    end,
  })

  if job_id <= 0 then
    vim.schedule(function()
      on_complete(1, "", "Failed to start job")
    end)
  end
end

local function is_git_repo(config_directory)
  return uv.fs_stat(config_directory .. "/.git") ~= nil
end

local function trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local M = {}
local is_running = false

function M.check_for_updates()
  if is_running then
    return
  end
  is_running = true

  local state = read_state()
  local current_time = now_epoch()

  if current_time < (state.next_check_epoch or 0) then
    is_running = false
    return
  end

  -- Set a default hourly backoff immediately so repeated opens don't spam checks
  set_next_check(state, SUCCESS_BACKOFF_SECONDS)

  if vim.fn.executable("git") ~= 1 then
    maybe_notify_failure_throttled(state, "git not found on PATH; skipping auto-update.")
    is_running = false
    return
  end

  local config_directory = vim.fn.stdpath("config")
  if not is_git_repo(config_directory) then
    maybe_notify_failure_throttled(state, "Config directory is not a git repo; skipping auto-update.")
    is_running = false
    return
  end

  -- If user is actively editing config, don't try to pull over it.
  run_command({ "git", "status", "--porcelain" }, config_directory, function(status_code, stdout, stderr)
    if status_code ~= 0 then
      set_next_check(state, FAILURE_BACKOFF_SECONDS)
      maybe_notify_failure_throttled(state, "git status failed; will retry later.\n" .. trim(stderr))
      is_running = false
      return
    end

    if trim(stdout) ~= "" then
      maybe_notify_failure_throttled(state, "Config repo has local changes; skipping auto-update.")
      is_running = false
      return
    end

    -- Detached HEAD check (optional, but avoids weird states)
    run_command({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, config_directory, function(head_code, head_out, head_err)
      if head_code ~= 0 then
        set_next_check(state, FAILURE_BACKOFF_SECONDS)
        maybe_notify_failure_throttled(state, "Failed to read current branch; will retry later.\n" .. trim(head_err))
        is_running = false
        return
      end

      if trim(head_out) == "HEAD" then
        maybe_notify_failure_throttled(state, "Repo is in detached HEAD; skipping auto-update.")
        is_running = false
        return
      end

      -- Ensure upstream exists
      run_command({ "git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}" }, config_directory, function(up_code, up_out, up_err)
        if up_code ~= 0 then
          maybe_notify_failure_throttled(state, "No upstream tracking branch configured; skipping auto-update.\n" .. trim(up_err))
          is_running = false
          return
        end

        -- Fetch updates
        run_command({ "git", "fetch", "--quiet", "--prune" }, config_directory, function(fetch_code, _, fetch_err)
          if fetch_code ~= 0 then
            set_next_check(state, FAILURE_BACKOFF_SECONDS)
            maybe_notify_failure_throttled(state, "git fetch failed; will retry later.\n" .. trim(fetch_err))
            is_running = false
            return
          end

          -- Are we behind upstream?
          run_command({ "git", "rev-list", "--count", "HEAD..@{u}" }, config_directory, function(behind_code, behind_out, behind_err)
            if behind_code ~= 0 then
              set_next_check(state, FAILURE_BACKOFF_SECONDS)
              maybe_notify_failure_throttled(state, "Failed to compare with upstream; will retry later.\n" .. trim(behind_err))
              is_running = false
              return
            end

            local behind_count = tonumber(trim(behind_out)) or 0
            if behind_count <= 0 then
              is_running = false
              return
            end

            -- Pull fast-forward only
            run_command({ "git", "pull", "--ff-only", "--quiet" }, config_directory, function(pull_code, _, pull_err)
              if pull_code ~= 0 then
                set_next_check(state, FAILURE_BACKOFF_SECONDS)
                maybe_notify_failure_throttled(
                  state,
                  "git pull failed (ff-only). Manual intervention needed.\n" .. trim(pull_err)
                )
                is_running = false
                return
              end

              notify(
                ("Config updated from %s (%d commit%s). Restart Neovim to apply."):format(
                  UPDATE_REPO_URL,
                  behind_count,
                  behind_count == 1 and "" or "s"
                ),
                vim.log.levels.INFO
              )

              is_running = false
            end)
          end)
        end)
      end)
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      vim.schedule(function()
        M.check_for_updates()
      end)
    end,
  })
end

return M
