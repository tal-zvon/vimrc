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

local function trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function ellipsize(text, max_len)
  local cleaned = trim(text or "")
  if #cleaned <= max_len then
    return cleaned
  end
  return cleaned:sub(1, max_len) .. "…"
end

local function wrap_text(s, width)
  width = width or math.floor(vim.o.columns * 0.8)
  local wrapped_lines = {}

  -- iterate original lines to preserve intentional newlines
  for orig_line in (s .. "\n"):gmatch("(.-)\n") do
    local out, line = {}, ""
    for word in orig_line:gmatch("%S+") do
      if #line == 0 then
        line = word
      elseif #line + 1 + #word <= width then
        line = line .. " " .. word
      else
        table.insert(out, line)
        line = word
      end
    end
    if #line > 0 then table.insert(out, line) end

    -- preserve empty lines too
    if #out == 0 then
      table.insert(wrapped_lines, "")
    else
      for _, l in ipairs(out) do
        table.insert(wrapped_lines, l)
      end
    end
  end

  -- remove the extra line added by (s.."\n") if s ended with newline
  if s:sub(-1) == "\n" and wrapped_lines[#wrapped_lines] == "" then
    table.remove(wrapped_lines, #wrapped_lines)
  end

  return table.concat(wrapped_lines, "\n")
end

local function is_debug_enabled()
  local env = os.getenv("NVIM_VIMRC_AUTO_UPDATE_DEBUG")
  if env == "1" or env == "true" or env == "yes" then
    return true
  end

  local g_value = vim.g.vimrc_auto_update_debug
  return g_value == 1 or g_value == true or g_value == "1" or g_value == "true"
end

local function notify(message, level, timeout_ms)
  local msg = (type(message) == "string") and message or (vim.inspect and vim.inspect(message) or tostring(message))
  msg = wrap_text(msg)

  local opts = { title = NOTIFY_TITLE }
  if type(timeout_ms) == "number" then
    opts.timeout = timeout_ms
  end

  pcall(vim.notify, msg, level, opts)
end

local function debug_notify(message)
  if not is_debug_enabled() then
    return
  end
  notify(message, vim.log.levels.INFO)
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
    debug_notify("DEBUG: Failure occurred, but notification is throttled.")
    return
  end

  state.last_failure_notify_epoch = current_time
  write_state(state)

  notify(message, vim.log.levels.WARN)
end

local function set_next_check(state, seconds_from_now)
  state.next_check_epoch = now_epoch() + seconds_from_now
  write_state(state)
  debug_notify(("DEBUG: next_check_epoch set to %d (in %d seconds)"):format(state.next_check_epoch, seconds_from_now))
end

local has_vim_system = type(vim.system) == "function"

local function run_command(command_args, cwd, on_complete)
  debug_notify(("DEBUG: Running command in %s: %s"):format(cwd, table.concat(command_args, " ")))

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

local M = {}
local is_running = false

function M.check_for_updates()
  if is_running then
    debug_notify("DEBUG: Already running; skipping.")
    return
  end
  is_running = true

  local function finish()
    is_running = false
    debug_notify("DEBUG: Finished.")
  end

  local state = read_state()
  local current_time = now_epoch()

  debug_notify("DEBUG: Starting auto-update check.")
  debug_notify(("DEBUG: state_file_path=%s"):format(state_file_path))
  debug_notify(("DEBUG: now=%d next_check_epoch=%d last_failure_notify_epoch=%d"):format(
    current_time,
    state.next_check_epoch or 0,
    state.last_failure_notify_epoch or 0
  ))

  if current_time < (state.next_check_epoch or 0) then
    local seconds_left = (state.next_check_epoch or 0) - current_time
    debug_notify(("DEBUG: Rate-limited; next check in %d seconds."):format(seconds_left))
    finish()
    return
  end

  -- Set hourly backoff immediately so repeated opens don't spam checks
  set_next_check(state, SUCCESS_BACKOFF_SECONDS)

  if vim.fn.executable("git") ~= 1 then
    maybe_notify_failure_throttled(state, "git not found on PATH; skipping auto-update.")
    finish()
    return
  end

  local config_directory = vim.fn.stdpath("config")
  debug_notify(("DEBUG: stdpath('config')=%s"):format(config_directory))

  if not is_git_repo(config_directory) then
    maybe_notify_failure_throttled(state, "Config directory is not a git repo; skipping auto-update.")
    finish()
    return
  end

  -- If user is actively editing config, don't try to pull over it.
  run_command({ "git", "status", "--porcelain" }, config_directory, function(status_code, stdout, stderr)
    debug_notify(("DEBUG: git status exit=%d stdout=%q stderr=%q"):format(
      status_code,
      ellipsize(stdout, 200),
      ellipsize(stderr, 200)
    ))

    if status_code ~= 0 then
      set_next_check(state, FAILURE_BACKOFF_SECONDS)
      maybe_notify_failure_throttled(state, "git status failed; will retry later.\n" .. ellipsize(stderr, 400))
      finish()
      return
    end

    if trim(stdout) ~= "" then
      maybe_notify_failure_throttled(state, "Config repo has local changes; skipping auto-update.")
      finish()
      return
    end

    -- Detached HEAD check
    run_command({ "git", "rev-parse", "--abbrev-ref", "HEAD" }, config_directory, function(head_code, head_out, head_err)
      debug_notify(("DEBUG: git branch exit=%d branch=%q err=%q"):format(
        head_code,
        trim(head_out),
        ellipsize(head_err, 200)
      ))

      if head_code ~= 0 then
        set_next_check(state, FAILURE_BACKOFF_SECONDS)
        maybe_notify_failure_throttled(state, "Failed to read current branch; will retry later.\n" .. ellipsize(head_err, 400))
        finish()
        return
      end

      if trim(head_out) == "HEAD" then
        maybe_notify_failure_throttled(state, "Repo is in detached HEAD; skipping auto-update.")
        finish()
        return
      end

      -- Ensure upstream exists
      run_command({ "git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}" }, config_directory, function(up_code, up_out, up_err)
        debug_notify(("DEBUG: git upstream exit=%d upstream=%q err=%q"):format(
          up_code,
          trim(up_out),
          ellipsize(up_err, 200)
        ))

        if up_code ~= 0 then
          maybe_notify_failure_throttled(state, "No upstream tracking branch configured; skipping auto-update.\n" .. ellipsize(up_err, 400))
          finish()
          return
        end

        -- Fetch updates
        run_command({ "git", "fetch", "--quiet", "--prune" }, config_directory, function(fetch_code, _, fetch_err)
          debug_notify(("DEBUG: git fetch exit=%d err=%q"):format(fetch_code, ellipsize(fetch_err, 200)))

          if fetch_code ~= 0 then
            set_next_check(state, FAILURE_BACKOFF_SECONDS)
            maybe_notify_failure_throttled(state, "git fetch failed; will retry later.\n" .. ellipsize(fetch_err, 400))
            finish()
            return
          end

          -- Are we behind upstream?
          run_command({ "git", "rev-list", "--count", "HEAD..@{u}" }, config_directory, function(behind_code, behind_out, behind_err)
            debug_notify(("DEBUG: behind check exit=%d behind=%q err=%q"):format(
              behind_code,
              trim(behind_out),
              ellipsize(behind_err, 200)
            ))

            if behind_code ~= 0 then
              set_next_check(state, FAILURE_BACKOFF_SECONDS)
              maybe_notify_failure_throttled(state, "Failed to compare with upstream; will retry later.\n" .. ellipsize(behind_err, 400))
              finish()
              return
            end

            local behind_count = tonumber(trim(behind_out)) or 0
            if behind_count <= 0 then
              debug_notify("DEBUG: Repo already up-to-date; no pull needed.")
              finish()
              return
            end

            debug_notify(("DEBUG: Repo is behind by %d commit(s); pulling ff-only."):format(behind_count))

            -- Pull fast-forward only
            run_command({ "git", "pull", "--ff-only", "--quiet" }, config_directory, function(pull_code, _, pull_err)
              debug_notify(("DEBUG: git pull exit=%d err=%q"):format(pull_code, ellipsize(pull_err, 200)))

              if pull_code ~= 0 then
                set_next_check(state, FAILURE_BACKOFF_SECONDS)
                maybe_notify_failure_throttled(
                  state,
                  "git pull failed (ff-only). Manual intervention needed.\n" .. ellipsize(pull_err, 400)
                )
                finish()
                return
              end

              notify(
                ("Config updated from %s (%d commit%s). Restart Neovim to apply."):format(
                  UPDATE_REPO_URL,
                  behind_count,
                  behind_count == 1 and "" or "s"
                ),
                vim.log.levels.INFO,
                15000
              )

              finish()
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
      -- Run after everything else is loaded, but don't block.
      vim.schedule(function()
        M.check_for_updates()
      end)
    end,
  })
end

return M
