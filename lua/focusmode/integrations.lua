local config = require("focusmode.config")

local M = {}

-- ── Achievement Tracker ───────────────────────────────────────

local function get_tracker()
  local ok, state = pcall(require, "achievement-tracker.state")
  if ok then return state end
  return nil
end

function M.award_xp(minutes)
  if not config.options.achievements.enabled then return end
  local tracker = get_tracker()
  if not tracker then return end

  local xp = minutes * config.options.achievements.xp_per_focus_minute

  -- Apply streak multiplier
  local streaks = require("focusmode.persist").get_streaks()
  if streaks.current > 1 then
    xp = math.floor(xp * config.options.achievements.bonus_streak_multiplier)
  end

  local ok, err = pcall(tracker.add_xp, xp)
  if not ok then
    -- Tracker not initialized - silently ignore
  end
end

function M.earn_daily_achievement()
  if not config.options.achievements.enabled then return end
  local tracker = get_tracker()
  if not tracker then return end

  local id = config.options.achievements.daily_achievement_id
  if tracker.earn_daily_achievement then
    pcall(tracker.earn_daily_achievement, id)
  end
end

-- ── Sound/Bell ────────────────────────────────────────────────

function M.play_sound()
  if not config.options.sound.enabled then return end

  if config.options.sound.bell then
    io.write("\a")
    io.flush()
  end

  local cmd = config.options.sound.command
  if cmd then
    vim.fn.jobstart(cmd, { detach = true })
  end
end

-- ── Lualine Component ─────────────────────────────────────────
-- Delegates to dedicated lualine module; kept for backwards compat

function M.lualine_component()
  return require("focusmode.lualine").component()
end

return M
