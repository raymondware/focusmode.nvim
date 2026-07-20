local config = require("focusmode.config")

local M = {}

local state = nil

local function default_state()
  return {
    sessions = {},
    daily_log = {},
    streaks = {
      current = 0,
      longest = 0,
      last_active_date = nil,
    },
    lifetime_minutes = 0,
    lifetime_sessions = 0,
  }
end

local function get_data_path()
  local dir = config.options.data_dir or config.defaults.data_dir
  return dir .. "/state.json"
end

local function ensure_dir()
  local dir = config.options.data_dir or config.defaults.data_dir
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

function M.load()
  local path = get_data_path()
  local f = io.open(path, "r")
  if not f then
    state = default_state()
    return
  end
  local content = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.json.decode, content)
  if ok and decoded then
    state = vim.tbl_deep_extend("force", default_state(), decoded)
  else
    state = default_state()
  end
end

function M.save()
  if not state then return end
  ensure_dir()
  local path = get_data_path()
  local encoded = vim.json.encode(state)
  local f = io.open(path, "w")
  if f then
    f:write(encoded)
    f:close()
  end
end

local function today_str()
  return os.date("%Y-%m-%d")
end

local function update_streaks(date)
  local streaks = state.streaks

  if streaks.last_active_date == date then
    -- Already active today, nothing to update
    return
  end

  if streaks.last_active_date then
    -- Check if yesterday was the last active date
    local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
    if streaks.last_active_date == yesterday then
      streaks.current = streaks.current + 1
    else
      -- Streak broken
      streaks.current = 1
    end
  else
    streaks.current = 1
  end

  if streaks.current > streaks.longest then
    streaks.longest = streaks.current
  end

  streaks.last_active_date = date
end

function M.record_session(mode, minutes, started_at, ended_at)
  if not state then M.load() end

  local date = today_str()

  -- Append session
  state.sessions[#state.sessions + 1] = {
    date = date,
    mode = mode,
    minutes = minutes,
    started_at = started_at,
    ended_at = ended_at,
  }

  -- Update daily log
  state.daily_log[date] = (state.daily_log[date] or 0) + minutes

  -- Update lifetime
  state.lifetime_minutes = state.lifetime_minutes + minutes
  state.lifetime_sessions = state.lifetime_sessions + 1

  -- Update streaks
  update_streaks(date)

  M.save()
end

function M.get_sessions(filter)
  if not state then M.load() end
  if not filter then
    return state.sessions
  end

  local result = {}
  for _, s in ipairs(state.sessions) do
    local match = true
    if filter.date and s.date ~= filter.date then match = false end
    if filter.mode and s.mode ~= filter.mode then match = false end
    if filter.from_date and s.date < filter.from_date then match = false end
    if filter.to_date and s.date > filter.to_date then match = false end
    if match then
      result[#result + 1] = s
    end
  end
  return result
end

function M.get_daily_log()
  if not state then M.load() end
  return state.daily_log
end

function M.get_streaks()
  if not state then M.load() end
  return state.streaks
end

function M.get_lifetime()
  if not state then M.load() end
  return {
    minutes = state.lifetime_minutes,
    sessions = state.lifetime_sessions,
  }
end

function M.reset()
  state = default_state()
  M.save()
end

return M
