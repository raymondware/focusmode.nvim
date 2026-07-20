local api = vim.api
local config = require("focusmode.config")
local hl = require("focusmode.hl")
local stats = require("focusmode.stats")
local persist = require("focusmode.persist")

local M = {}

local dash_win = nil
local dash_buf = nil
local dim_win = nil
local dim_buf = nil

-- ── Helpers ───────────────────────────────────────────────────

local function progress_bar(pct, width)
  local filled = math.floor(pct / 100 * width)
  local empty = width - filled
  return string.rep("█", filled) .. string.rep("░", empty)
end

local function pad(str, width)
  local sw = api.nvim_strwidth(str)
  if sw >= width then return str end
  return str .. string.rep(" ", width - sw)
end

local function center(str, width)
  local sw = api.nvim_strwidth(str)
  if sw >= width then return str end
  local left = math.floor((width - sw) / 2)
  return string.rep(" ", left) .. str
end

local function fmt_minutes(mins)
  if mins >= 60 then
    local h = math.floor(mins / 60)
    local m = mins % 60
    if m > 0 then
      return string.format("%dh %dm", h, m)
    end
    return string.format("%dh", h)
  end
  return string.format("%dm", mins)
end

-- ── Dim Overlay ───────────────────────────────────────────────

local function open_dim()
  dim_buf = api.nvim_create_buf(false, true)
  vim.bo[dim_buf].bufhidden = "wipe"
  dim_win = api.nvim_open_win(dim_buf, false, {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines,
    row = 0,
    col = 0,
    style = "minimal",
    border = "none",
    zindex = 49,
    focusable = false,
  })
  api.nvim_win_set_hl_ns(dim_win, hl.ns)
  vim.wo[dim_win].winblend = 40
end

local function close_dim()
  if dim_win and api.nvim_win_is_valid(dim_win) then
    api.nvim_win_close(dim_win, true)
  end
  dim_win = nil
  dim_buf = nil
end

-- ── Build Dashboard Content ───────────────────────────────────

local function build_content(width)
  local lines = {}
  local highlights = {} -- {line_idx, col_start, col_end, hl_group}

  local function add(text, hl_group)
    lines[#lines + 1] = pad(text, width)
    if hl_group then
      highlights[#highlights + 1] = { #lines - 1, 0, #lines[#lines], hl_group }
    end
  end

  local function add_hl(text, parts)
    lines[#lines + 1] = pad(text, width)
    local line_idx = #lines - 1
    for _, p in ipairs(parts) do
      highlights[#highlights + 1] = { line_idx, p[1], p[2], p[3] }
    end
  end

  local sep = string.rep("─", width - 4)

  -- Title
  add("")
  add(center("Deep Work Dashboard", width), "FocusDashTitle")
  add("")

  -- Today
  local today = stats.today()
  local goals = stats.goal_progress()

  add("  TODAY", "FocusDashHeading")
  add("  " .. sep, "FocusDashSep")

  local today_line = string.format("  %s focused  |  %d sessions", fmt_minutes(today.minutes), today.sessions)
  add(today_line, "FocusDashStatVal")

  -- Daily goal bar
  local bar_width = width - 20
  if bar_width < 10 then bar_width = 10 end
  local bar = progress_bar(goals.daily_pct, bar_width)
  local goal_line = string.format("  Goal: %s %d%%", bar, goals.daily_pct)
  if goals.daily_pct >= 100 then
    add(goal_line, "FocusDashGoalMet")
  else
    add(goal_line, "FocusDashStatLabel")
  end

  local remaining_line = string.format("  %s remaining of %s goal",
    fmt_minutes(goals.daily_remaining), fmt_minutes(goals.daily_target))
  add(remaining_line, "FocusDashStatLabel")

  add("")

  -- This Week
  local week = stats.this_week()

  add("  THIS WEEK", "FocusDashHeading")
  add("  " .. sep, "FocusDashSep")

  local week_line = string.format("  %s focused  |  %d sessions", fmt_minutes(week.minutes), week.sessions)
  add(week_line, "FocusDashStatVal")

  -- Weekly goal bar
  local wbar = progress_bar(goals.weekly_pct, bar_width)
  local wgoal_line = string.format("  Goal: %s %d%%", wbar, goals.weekly_pct)
  if goals.weekly_pct >= 100 then
    add(wgoal_line, "FocusDashGoalMet")
  else
    add(wgoal_line, "FocusDashStatLabel")
  end

  -- Daily breakdown
  if week.daily_breakdown and #week.daily_breakdown > 0 then
    add("")
    local breakdown = "  "
    for _, day in ipairs(week.daily_breakdown) do
      local day_bar = ""
      if day.minutes > 0 then
        local day_pct = math.min(100, math.floor(day.minutes / (goals.daily_target > 0 and goals.daily_target or 120) * 100))
        day_bar = progress_bar(day_pct, 4)
      else
        day_bar = "░░░░"
      end
      breakdown = breakdown .. day.day .. " " .. day_bar .. " "
    end
    add(breakdown, "FocusDashStatLabel")
  end

  if week.best_day then
    add(string.format("  Best day: %s (%s)", week.best_day, fmt_minutes(week.best_minutes)), "FocusDashStatLabel")
  end

  add("")

  -- Streaks
  local streak = stats.streak()

  add("  STREAKS", "FocusDashHeading")
  add("  " .. sep, "FocusDashSep")

  local streak_line = string.format("  Current: %d days  |  Longest: %d days", streak.current, streak.longest)
  add(streak_line, "FocusDashStreak")

  add("")

  -- By Mode
  local by_mode = stats.by_mode()
  local mode_entries = {}
  for mode, data in pairs(by_mode) do
    mode_entries[#mode_entries + 1] = { mode = mode, minutes = data.minutes, sessions = data.sessions }
  end
  table.sort(mode_entries, function(a, b) return a.minutes > b.minutes end)

  if #mode_entries > 0 then
    add("  BY MODE", "FocusDashHeading")
    add("  " .. sep, "FocusDashSep")

    for _, entry in ipairs(mode_entries) do
      local mode_line = string.format("  %-12s %s  (%d sessions)", entry.mode, fmt_minutes(entry.minutes), entry.sessions)
      add(mode_line, "FocusDashStatVal")
    end

    add("")
  end

  -- Lifetime
  local lifetime = persist.get_lifetime()

  add("  LIFETIME", "FocusDashHeading")
  add("  " .. sep, "FocusDashSep")
  add(string.format("  %s focused  |  %d sessions", fmt_minutes(lifetime.minutes), lifetime.sessions), "FocusDashStatVal")

  add("")

  -- Recent sessions
  local sessions = persist.get_sessions()
  if #sessions > 0 then
    add("  RECENT SESSIONS", "FocusDashHeading")
    add("  " .. sep, "FocusDashSep")

    local start_idx = math.max(1, #sessions - 9)
    for i = #sessions, start_idx, -1 do
      local s = sessions[i]
      local line = string.format("  %s  %-12s  %s  %s - %s",
        s.date, s.mode or "?", fmt_minutes(s.minutes), s.started_at or "?", s.ended_at or "?")
      add(line, "FocusDashStatLabel")
    end
  end

  add("")
  add(center("Press q to close", width), "FocusDashStatLabel")
  add("")

  return lines, highlights
end

-- ── Open / Close ──────────────────────────────────────────────

function M.open()
  if dash_win and api.nvim_win_is_valid(dash_win) then
    return
  end

  hl.setup()

  local width = math.min(60, math.floor(vim.o.columns * 0.8))
  local lines, highlights = build_content(width)
  local height = math.min(#lines, math.floor(vim.o.lines * 0.8))

  -- Dim overlay
  open_dim()

  -- Dashboard buffer
  dash_buf = api.nvim_create_buf(false, true)
  vim.bo[dash_buf].bufhidden = "wipe"
  vim.bo[dash_buf].modifiable = true
  api.nvim_buf_set_lines(dash_buf, 0, -1, false, lines)
  vim.bo[dash_buf].modifiable = false

  -- Apply highlights
  local ns = hl.ns
  for _, h in ipairs(highlights) do
    api.nvim_buf_set_extmark(dash_buf, ns, h[1], h[2], {
      end_col = h[3],
      hl_group = h[4],
    })
  end

  -- Center window
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  dash_win = api.nvim_open_win(dash_buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Deep Work ",
    title_pos = "center",
    zindex = 50,
  })

  api.nvim_win_set_hl_ns(dash_win, ns)
  vim.wo[dash_win].cursorline = false
  vim.wo[dash_win].wrap = false

  -- Keymaps
  vim.keymap.set("n", "q", function() M.close() end, { buffer = dash_buf, nowait = true })
  vim.keymap.set("n", "<Esc>", function() M.close() end, { buffer = dash_buf, nowait = true })

  -- Auto-close on leave
  api.nvim_create_autocmd("WinLeave", {
    buffer = dash_buf,
    once = true,
    callback = function()
      vim.schedule(function() M.close() end)
    end,
  })
end

function M.close()
  if dash_win and api.nvim_win_is_valid(dash_win) then
    api.nvim_win_close(dash_win, true)
  end
  dash_win = nil
  dash_buf = nil
  close_dim()
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

function M.is_open()
  return dash_win ~= nil and api.nvim_win_is_valid(dash_win)
end

return M
