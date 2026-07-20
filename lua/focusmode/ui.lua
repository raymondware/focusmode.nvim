local api = vim.api
local config = require("focusmode.config")
local hl = require("focusmode.hl")

local M = {}

-- Timer window state
local timer_win = nil
local timer_buf = nil

-- Toast state
local active_toast = nil

-- ── Position Helpers ──────────────────────────────────────────

local function get_anchor_offsets()
  -- Account for tabline and statusline stealing editor rows
  local top_offset = 0
  local bottom_offset = 0

  local showtabline = vim.o.showtabline
  if showtabline == 2 or (showtabline == 1 and #vim.api.nvim_list_tabpages() > 1) then
    top_offset = 1
  end

  local laststatus = vim.o.laststatus
  if laststatus >= 1 then
    bottom_offset = 2 -- statusline + cmdline
  else
    bottom_offset = 1 -- cmdline only
  end

  return top_offset, bottom_offset
end

local function get_timer_position(width, height)
  local ui_cfg = config.options.timer_ui
  local pos = ui_cfg.position
  local row_off = ui_cfg.row_offset or 0
  local col_off = ui_cfg.col_offset or 0
  local top_anchor, bottom_anchor = get_anchor_offsets()
  local col, row

  if pos == "top_right" then
    col = vim.o.columns - width - 2
    row = top_anchor + 1
  elseif pos == "top_left" then
    col = 2
    row = top_anchor + 1
  elseif pos == "bottom_right" then
    col = vim.o.columns - width - 2
    row = vim.o.lines - height - bottom_anchor - 1
  elseif pos == "bottom_left" then
    col = 2
    row = vim.o.lines - height - bottom_anchor - 1
  elseif pos == "center_top" then
    col = math.floor((vim.o.columns - width) / 2)
    row = top_anchor + 1
  elseif pos == "center_bottom" then
    col = math.floor((vim.o.columns - width) / 2)
    row = vim.o.lines - height - bottom_anchor - 1
  else
    col = vim.o.columns - width - 2
    row = top_anchor + 1
  end

  return col + col_off, row + row_off
end

local function get_toast_position(width, height)
  local pos = config.options.toast.position
  local top_anchor, bottom_anchor = get_anchor_offsets()
  local col, row

  if pos == "bottom_right" then
    col = vim.o.columns - width - 2
    row = vim.o.lines - height - bottom_anchor - 1
  elseif pos == "bottom_left" then
    col = 2
    row = vim.o.lines - height - bottom_anchor - 1
  elseif pos == "top_right" then
    col = vim.o.columns - width - 2
    row = top_anchor + 1
  elseif pos == "top_left" then
    col = 2
    row = top_anchor + 1
  else
    col = vim.o.columns - width - 2
    row = vim.o.lines - height - bottom_anchor - 1
  end

  return col, row
end

-- ── Progress Bar ──────────────────────────────────────────────

local function progress_bar(pct, width)
  local filled = math.floor(pct * width)
  local empty = width - filled
  return string.rep("█", filled) .. string.rep("░", empty)
end

-- ── Timer Window ──────────────────────────────────────────────

function M.open_timer()
  if timer_win and api.nvim_win_is_valid(timer_win) then
    return
  end

  hl.setup()

  local ui_cfg = config.options.timer_ui
  local width = ui_cfg.width
  local height = 3

  timer_buf = api.nvim_create_buf(false, true)
  vim.bo[timer_buf].bufhidden = "wipe"

  -- Placeholder lines
  api.nvim_buf_set_lines(timer_buf, 0, -1, false, { "", "", "" })

  local col, row = get_timer_position(width, height)

  timer_win = api.nvim_open_win(timer_buf, false, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = ui_cfg.border,
    zindex = ui_cfg.zindex,
    focusable = false,
    noautocmd = true,
  })

  api.nvim_win_set_hl_ns(timer_win, hl.ns)
  vim.wo[timer_win].winblend = ui_cfg.blend

  -- Reposition on resize
  api.nvim_create_autocmd("VimResized", {
    callback = function()
      if timer_win and api.nvim_win_is_valid(timer_win) then
        local c, r = get_timer_position(width, height)
        api.nvim_win_set_config(timer_win, {
          relative = "editor",
          col = c,
          row = r,
        })
      end
    end,
    group = api.nvim_create_augroup("FocusModeTimerResize", { clear = true }),
  })
end

function M.close_timer()
  if timer_win and api.nvim_win_is_valid(timer_win) then
    api.nvim_win_close(timer_win, true)
  end
  timer_win = nil
  timer_buf = nil
  pcall(api.nvim_del_augroup_by_name, "FocusModeTimerResize")
end

function M.is_timer_open()
  return timer_win ~= nil and api.nvim_win_is_valid(timer_win)
end

function M.update_timer(state)
  if not timer_buf or not api.nvim_buf_is_valid(timer_buf) then
    return
  end

  local ns = hl.ns
  local remaining = state.remaining or 0
  local minutes = math.floor(remaining / 60)
  local seconds = remaining % 60
  local time_str = string.format("%02d:%02d", minutes, seconds)

  -- Line 0: Mode name + session count
  local mode_label = (state.mode or ""):upper()
  local session_str = ""
  if state.session_number and state.total_sessions and state.total_sessions > 0 then
    session_str = string.format(" %d/%d", state.session_number, state.total_sessions)
  end

  -- Line 1: Time with progress bar
  local total = state.total_seconds or (remaining + 1)
  if total <= 0 then total = 1 end
  local pct = 1 - (remaining / total)
  local bar_width = config.options.timer_ui.width - #time_str - 3
  if bar_width < 4 then bar_width = 4 end
  local bar = progress_bar(pct, bar_width)

  -- Line 2: Phase indicator
  local phase = (state.phase or "idle"):upper()

  -- Set lines
  local ui_width = config.options.timer_ui.width
  local line0 = " " .. mode_label .. session_str
  local line1 = " " .. time_str .. " " .. bar
  local line2 = " " .. phase

  -- Pad lines to width to avoid visual artifacts
  line0 = line0 .. string.rep(" ", math.max(0, ui_width - api.nvim_strwidth(line0)))
  line1 = line1 .. string.rep(" ", math.max(0, ui_width - api.nvim_strwidth(line1)))
  line2 = line2 .. string.rep(" ", math.max(0, ui_width - api.nvim_strwidth(line2)))

  api.nvim_buf_set_lines(timer_buf, 0, -1, false, { line0, line1, line2 })

  -- Apply highlights via extmarks
  api.nvim_buf_clear_namespace(timer_buf, ns, 0, -1)

  -- Line 0: mode label
  api.nvim_buf_set_extmark(timer_buf, ns, 0, 0, {
    end_col = #line0,
    hl_group = "FocusTimerLabel",
  })

  -- Line 1: time text
  local time_end = 1 + #time_str
  api.nvim_buf_set_extmark(timer_buf, ns, 1, 1, {
    end_col = time_end,
    hl_group = "FocusTimerText",
  })

  -- Line 1: progress bar
  local bar_start = time_end + 1
  local filled_chars = math.floor(pct * bar_width)
  if filled_chars > 0 then
    -- Approximate byte position for filled portion
    local filled_byte_end = bar_start + filled_chars * 3 -- UTF-8 block chars are 3 bytes
    api.nvim_buf_set_extmark(timer_buf, ns, 1, bar_start, {
      end_col = math.min(filled_byte_end, #line1),
      hl_group = "FocusTimerBarOn",
    })
  end

  -- Line 2: phase indicator
  local phase_hl = "FocusPhaseFocus"
  if state.phase == "break" or state.phase == "long_break" then
    phase_hl = "FocusPhaseBreak"
  elseif state.phase == "paused" then
    phase_hl = "FocusPhasePaused"
  end
  api.nvim_buf_set_extmark(timer_buf, ns, 2, 0, {
    end_col = #line2,
    hl_group = phase_hl,
  })
end

-- ── Toast Notifications ───────────────────────────────────────

local function dismiss_toast()
  if active_toast then
    if active_toast.timer then
      active_toast.timer:stop()
      active_toast.timer:close()
    end
    if active_toast.win and api.nvim_win_is_valid(active_toast.win) then
      api.nvim_win_close(active_toast.win, true)
    end
    active_toast = nil
  end
end

local toast_icons = {
  focus_complete = "  Focus complete!",
  break_complete = "  Break over!",
  goal_reached = "  Goal reached!",
  session_start = "  Focus started",
}

function M.show_toast(message, toast_type)
  if not config.options.toast.enabled then return end

  dismiss_toast()
  hl.setup()

  local width = config.options.toast.width
  local icon_line = toast_icons[toast_type] or "  " .. (toast_type or "")
  local lines = { "", icon_line, "  " .. message, "" }
  local height = #lines

  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Apply highlights
  local ns = hl.ns
  api.nvim_buf_set_extmark(buf, ns, 1, 0, {
    end_col = #lines[2],
    hl_group = "FocusToastTitle",
  })
  api.nvim_buf_set_extmark(buf, ns, 2, 0, {
    end_col = #lines[3],
    hl_group = "FocusToastBody",
  })

  local col, row = get_toast_position(width, height)

  local win = api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    zindex = 200,
    focusable = false,
    noautocmd = true,
  })

  api.nvim_win_set_hl_ns(win, ns)
  vim.wo[win].winblend = 5

  local timer = vim.uv.new_timer()
  active_toast = { win = win, buf = buf, timer = timer }

  timer:start(config.options.toast.duration_ms, 0, vim.schedule_wrap(function()
    dismiss_toast()
  end))
end

return M
