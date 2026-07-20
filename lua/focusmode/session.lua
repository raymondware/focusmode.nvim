local config = require("focusmode.config")
local timer = require("focusmode.timer")
local modes = require("focusmode.modes")
local persist = require("focusmode.persist")

local M = {}

-- State
local phase = "idle"           -- idle, focus, break, long_break, paused
local phase_before_pause = nil -- remember what we paused from
local current_mode_name = nil
local current_mode = nil
local session_number = 0
local total_duration = 0
local started_at = nil

-- Callback lists
local phase_change_cbs = {}
local tick_cbs = {}

-- Lazy-loaded modules (avoid circular deps)
local function get_ui()
  return require("focusmode.ui")
end

local function get_integrations()
  return require("focusmode.integrations")
end

local function get_dnd()
  return require("focusmode.dnd")
end

local function get_keybind()
  return require("focusmode.keybind")
end

local function get_focus_lock()
  return require("focusmode.focus_lock")
end

-- ── Callback Helpers ──────────────────────────────────────────

local function fire_phase_change(new_phase, old_phase)
  for _, cb in ipairs(phase_change_cbs) do
    pcall(cb, new_phase, old_phase)
  end
end

local function fire_tick(remaining)
  local state = M.get_state()
  state.remaining = remaining
  state.total_seconds = total_duration
  for _, cb in ipairs(tick_cbs) do
    pcall(cb, state)
  end
  -- Update timer UI
  local ui = get_ui()
  if ui.is_timer_open() then
    ui.update_timer(state)
  end
end

-- ── Forward Declarations ──────────────────────────────────────

local enter_focus
local enter_break
local cleanup_focus_features

-- ── Phase Transitions ─────────────────────────────────────────

cleanup_focus_features = function()
  if config.options.keybind_blocking.enabled then
    pcall(get_keybind().unblock)
  end
  if config.options.dnd.enabled then
    pcall(get_dnd().disable)
  end
  if config.options.focus_lock.enabled then
    pcall(get_focus_lock().disable)
  end
end

local function is_long_break()
  return current_mode.long_break_interval > 0
    and session_number > 0
    and session_number % current_mode.long_break_interval == 0
end

enter_focus = function()
  local old_phase = phase
  phase = "focus"
  session_number = session_number + 1
  total_duration = current_mode.focus * 60
  started_at = os.date("%H:%M")

  fire_phase_change(phase, old_phase)

  -- Enable focus features
  if config.options.keybind_blocking.enabled then
    pcall(get_keybind().block)
  end
  if config.options.dnd.enabled then
    pcall(get_dnd().enable)
  end
  if config.options.focus_lock.enabled then
    pcall(get_focus_lock().enable)
  end

  -- Open timer UI
  if config.options.timer_ui.enabled then
    get_ui().open_timer()
  end

  -- Start countdown
  timer.start(total_duration, fire_tick, function()
    -- Focus complete
    local minutes = current_mode.focus
    local ended_at = os.date("%H:%M")
    persist.record_session(current_mode_name, minutes, started_at, ended_at)

    -- Award XP
    pcall(function()
      local integrations = get_integrations()
      integrations.award_xp(minutes)
      integrations.earn_daily_achievement()
    end)

    -- Play sound
    if config.options.sound.enabled and config.options.sound.on_focus_end then
      pcall(get_integrations().play_sound)
    end

    -- Toast
    get_ui().show_toast(
      string.format("%d min focus complete - %d sessions today", minutes, session_number),
      "focus_complete"
    )

    -- Transition to break
    if config.options.auto_start_break then
      enter_break()
    else
      local old = phase
      phase = "idle"
      fire_phase_change(phase, old)
      cleanup_focus_features()
      get_ui().close_timer()
    end
  end)
end

enter_break = function()
  local old_phase = phase
  local long = is_long_break()
  phase = long and "long_break" or "break"
  local break_minutes = long and current_mode.long_break or current_mode["break"]
  total_duration = break_minutes * 60

  fire_phase_change(phase, old_phase)

  -- Relax focus features during break
  cleanup_focus_features()

  timer.start(total_duration, fire_tick, function()
    -- Break complete
    if config.options.sound.enabled and config.options.sound.on_break_end then
      pcall(get_integrations().play_sound)
    end

    get_ui().show_toast("Break over - ready for the next session?", "break_complete")

    if config.options.auto_start_focus then
      enter_focus()
    else
      local old = phase
      phase = "idle"
      fire_phase_change(phase, old)
      get_ui().close_timer()
    end
  end)
end

-- ── Public API ────────────────────────────────────────────────

function M.start(mode_name)
  if phase ~= "idle" then
    M.stop()
  end

  current_mode_name = mode_name or config.options.default_mode
  current_mode = modes.get(current_mode_name)
  session_number = 0

  enter_focus()
end

function M.stop()
  local old_phase = phase
  timer.stop()
  phase = "idle"
  phase_before_pause = nil
  cleanup_focus_features()
  get_ui().close_timer()
  if old_phase ~= "idle" then
    fire_phase_change("idle", old_phase)
  end
end

function M.pause()
  if phase ~= "focus" and phase ~= "break" and phase ~= "long_break" then
    return
  end
  phase_before_pause = phase
  local old_phase = phase
  phase = "paused"
  timer.pause()

  -- Relax blocking during pause
  cleanup_focus_features()

  fire_phase_change("paused", old_phase)

  -- Update UI to show paused state
  if get_ui().is_timer_open() then
    get_ui().update_timer(M.get_state())
  end
end

function M.resume()
  if phase ~= "paused" then return end
  local old_phase = phase
  phase = phase_before_pause or "focus"
  phase_before_pause = nil
  timer.resume()

  -- Re-enable focus features if resuming into focus
  if phase == "focus" then
    if config.options.keybind_blocking.enabled then
      pcall(get_keybind().block)
    end
    if config.options.dnd.enabled then
      pcall(get_dnd().enable)
    end
  end

  fire_phase_change(phase, old_phase)
end

function M.toggle()
  if phase == "idle" then
    M.start()
  elseif phase == "paused" then
    M.resume()
  else
    M.pause()
  end
end

function M.skip()
  if phase == "focus" then
    timer.stop()
    -- Don't record incomplete session
    if config.options.auto_start_break then
      enter_break()
    else
      local old = phase
      phase = "idle"
      cleanup_focus_features()
      get_ui().close_timer()
      fire_phase_change("idle", old)
    end
  elseif phase == "break" or phase == "long_break" then
    timer.stop()
    if config.options.auto_start_focus then
      enter_focus()
    else
      local old = phase
      phase = "idle"
      get_ui().close_timer()
      fire_phase_change("idle", old)
    end
  end
end

function M.get_state()
  return {
    phase = phase,
    mode = current_mode_name,
    session_number = session_number,
    total_sessions = current_mode and current_mode.long_break_interval or 0,
    remaining_seconds = timer.get_remaining() or 0,
    remaining = timer.get_remaining() or 0,
    total_seconds = total_duration,
    started_at = started_at,
  }
end

function M.on_phase_change(callback)
  phase_change_cbs[#phase_change_cbs + 1] = callback
end

function M.on_tick(callback)
  tick_cbs[#tick_cbs + 1] = callback
end

-- ── Auto-Pause Autocmds ──────────────────────────────────────

local autopause_group = vim.api.nvim_create_augroup("FocusModeAutoPause", { clear = true })

vim.api.nvim_create_autocmd("FocusLost", {
  group = autopause_group,
  callback = function()
    if not config.options.auto_pause.enabled then return end
    if not config.options.auto_pause.on_focus_lost then return end
    if phase == "focus" or phase == "break" or phase == "long_break" then
      M.pause()
    end
  end,
  desc = "focusmode: auto-pause on focus lost",
})

vim.api.nvim_create_autocmd("FocusGained", {
  group = autopause_group,
  callback = function()
    if not config.options.auto_pause.enabled then return end
    if not config.options.auto_pause.on_focus_lost then return end
    if phase == "paused" then
      M.resume()
    end
  end,
  desc = "focusmode: auto-resume on focus gained",
})

return M
