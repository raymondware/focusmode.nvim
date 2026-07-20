local M = {}

M.defaults = {
  focus_duration = 25,
  break_duration = 5,
  long_break_duration = 15,
  long_break_interval = 4,
  auto_start_break = true,
  auto_start_focus = false,

  modes = {
    pomodoro = { focus = 25, ["break"] = 5, long_break = 15, long_break_interval = 4 },
    deep_work = { focus = 50, ["break"] = 10, long_break = 20, long_break_interval = 2 },
    review = { focus = 15, ["break"] = 3, long_break = 10, long_break_interval = 4 },
    learning = { focus = 30, ["break"] = 10, long_break = 15, long_break_interval = 3 },
  },
  default_mode = "pomodoro",

  timer_ui = {
    enabled = true,
    position = "top_right", -- top_right, top_left, bottom_right, bottom_left, center_top, center_bottom
    row_offset = 0,
    col_offset = 0,
    width = 22,
    border = "rounded",
    zindex = 50,
    blend = 10,
    show_mode = true,
    show_session_count = true,
  },

  toast = {
    enabled = true,
    duration_ms = 4000,
    width = 40,
    position = "bottom_right",
  },

  sound = {
    enabled = false,
    on_focus_end = true,
    on_break_end = true,
    bell = true,
    command = nil,
  },

  keybind_blocking = {
    enabled = false,
    blocked_keys = {},
    allow_override = true,
  },

  auto_pause = {
    enabled = false,
    on_focus_lost = true,
    on_idle = false,
    idle_timeout = 120,
  },

  goals = {
    daily_minutes = 120,
    weekly_minutes = 600,
  },

  achievements = {
    enabled = true,
    xp_per_focus_minute = 4,
    bonus_streak_multiplier = 1.5,
    daily_achievement_id = "deep_focus_session",
  },

  dnd = {
    enabled = false,
    suppress_notify = true,
    suppress_diagnostics = false,
  },

  focus_lock = {
    enabled = false,
    severity = "warn", -- "warn" shows prompt, "block" prevents quit entirely
    message = "You're in a focus session! Are you sure you want to quit?",
  },

  picker = {
    backend = "auto", -- "auto", "telescope", "fzf_lua", "select"
  },

  data_dir = vim.fn.stdpath("data") .. "/focusmode",

  keymaps = {
    toggle = nil,
    start = nil,
    stop = nil,
    pause = nil,
    dashboard = nil,
  },

  lualine = {
    icon_focus = "󰔛",
    icon_break = "󰾴",
    icon_paused = "󰏤",
    icon_idle = "",
    show_progress = true,
    show_session_count = true,
    show_mode = true,
    progress_width = 6,
    -- format tokens: {icon} {time} {bar} {mode} {session}
    format_focus = "{icon} {time} {bar} ({mode} {session})",
    format_break = "{icon} {time} {bar}",
    format_paused = "{icon} PAUSED {time}",
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

function M.get_mode(name)
  local modes = M.options.modes or M.defaults.modes
  local mode = modes[name]
  if mode then
    return mode
  end
  -- Fall back to default mode
  local default = M.options.default_mode or M.defaults.default_mode
  return modes[default] or modes.pomodoro
end

return M
