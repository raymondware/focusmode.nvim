local config = require("focusmode.config")
local persist = require("focusmode.persist")

local M = {}

local function today_str()
  return os.date("%Y-%m-%d")
end

local function week_start()
  -- Monday of current week
  local t = os.time()
  local wday = tonumber(os.date("%w", t)) -- 0=Sun, 1=Mon, ...
  if wday == 0 then wday = 7 end
  local monday = t - (wday - 1) * 86400
  return os.date("%Y-%m-%d", monday)
end

local function month_start()
  return os.date("%Y-%m-01")
end

function M.today()
  local log = persist.get_daily_log()
  local today = today_str()
  local minutes = log[today] or 0
  local sessions = persist.get_sessions({ date = today })
  return {
    minutes = minutes,
    sessions = #sessions,
  }
end

function M.this_week()
  local log = persist.get_daily_log()
  local start = week_start()
  local total_minutes = 0
  local total_sessions = 0
  local best_day = nil
  local best_minutes = 0
  local daily_breakdown = {}

  for i = 0, 6 do
    local t = os.time() - (tonumber(os.date("%w")) == 0 and 7 or tonumber(os.date("%w")) - 1) * 86400 + i * 86400
    local date = os.date("%Y-%m-%d", t)
    if date >= start then
      local mins = log[date] or 0
      local day_name = os.date("%a", t)
      daily_breakdown[#daily_breakdown + 1] = { date = date, day = day_name, minutes = mins }
      total_minutes = total_minutes + mins
      if mins > best_minutes then
        best_minutes = mins
        best_day = date
      end
    end
  end

  local week_sessions = persist.get_sessions({ from_date = start })

  return {
    minutes = total_minutes,
    sessions = #week_sessions,
    best_day = best_day,
    best_minutes = best_minutes,
    daily_breakdown = daily_breakdown,
  }
end

function M.this_month()
  local log = persist.get_daily_log()
  local start = month_start()
  local total_minutes = 0
  local best_day = nil
  local best_minutes = 0

  for date, mins in pairs(log) do
    if date >= start then
      total_minutes = total_minutes + mins
      if mins > best_minutes then
        best_minutes = mins
        best_day = date
      end
    end
  end

  local month_sessions = persist.get_sessions({ from_date = start })

  return {
    minutes = total_minutes,
    sessions = #month_sessions,
    best_day = best_day,
    best_minutes = best_minutes,
  }
end

function M.streak()
  local streaks = persist.get_streaks()
  return {
    current = streaks.current,
    longest = streaks.longest,
  }
end

function M.goal_progress()
  local goals = config.options.goals
  local today_data = M.today()
  local week_data = M.this_week()

  local daily_pct = goals.daily_minutes > 0
    and math.min(100, math.floor(today_data.minutes / goals.daily_minutes * 100))
    or 0

  local weekly_pct = goals.weekly_minutes > 0
    and math.min(100, math.floor(week_data.minutes / goals.weekly_minutes * 100))
    or 0

  return {
    daily_pct = daily_pct,
    weekly_pct = weekly_pct,
    daily_remaining = math.max(0, goals.daily_minutes - today_data.minutes),
    weekly_remaining = math.max(0, goals.weekly_minutes - week_data.minutes),
    daily_target = goals.daily_minutes,
    weekly_target = goals.weekly_minutes,
  }
end

function M.by_mode()
  local sessions = persist.get_sessions()
  local result = {}
  for _, s in ipairs(sessions) do
    local mode = s.mode or "unknown"
    if not result[mode] then
      result[mode] = { minutes = 0, sessions = 0 }
    end
    result[mode].minutes = result[mode].minutes + s.minutes
    result[mode].sessions = result[mode].sessions + 1
  end
  return result
end

return M
