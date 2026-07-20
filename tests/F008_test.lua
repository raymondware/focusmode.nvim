-- F008: Floating corner timer
local api = vim.api
local config = require("focusmode.config")
config.setup({})
local ui = require("focusmode.ui")

-- Test 1: Timer not open initially
assert(not ui.is_timer_open(), "Timer should not be open initially")

-- Test 2: Open timer creates floating window
ui.open_timer()
assert(ui.is_timer_open(), "Timer should be open after open_timer()")

-- Verify floating window exists
local wins = api.nvim_list_wins()
local found_float = false
for _, w in ipairs(wins) do
  local cfg = api.nvim_win_get_config(w)
  if cfg.relative == "editor" and cfg.focusable == false then
    found_float = true
    -- Verify position is top-right area
    local col_val = type(cfg.col) == "table" and cfg.col[false] or cfg.col
    local row_val = type(cfg.row) == "table" and cfg.row[false] or cfg.row
    assert(col_val > 0, "Timer should not be at col 0")
    assert(row_val <= 2, "Timer should be near top for top_right, got row " .. tostring(row_val))
    break
  end
end
assert(found_float, "Should find a non-focusable floating window")

-- Test 3: Update timer renders content
ui.update_timer({
  phase = "focus",
  remaining = 1500,
  total_seconds = 1500,
  mode = "pomodoro",
  session_number = 1,
  total_sessions = 4,
})
-- If we got here without error, the update worked

-- Test 4: Update with different remaining
ui.update_timer({
  phase = "focus",
  remaining = 60,
  total_seconds = 1500,
  mode = "pomodoro",
  session_number = 2,
  total_sessions = 4,
})

-- Test 5: Update with break phase
ui.update_timer({
  phase = "break",
  remaining = 300,
  total_seconds = 300,
  mode = "pomodoro",
  session_number = 2,
  total_sessions = 4,
})

-- Test 6: Update with paused phase
ui.update_timer({
  phase = "paused",
  remaining = 120,
  total_seconds = 300,
  mode = "pomodoro",
  session_number = 2,
  total_sessions = 4,
})

-- Test 7: Close timer removes window
ui.close_timer()
assert(not ui.is_timer_open(), "Timer should not be open after close")

-- Verify no floating windows remain
wins = api.nvim_list_wins()
for _, w in ipairs(wins) do
  local cfg = api.nvim_win_get_config(w)
  assert(cfg.relative ~= "editor" or cfg.focusable ~= false,
    "No non-focusable floating windows should remain")
end

-- Test 8: Double open is safe
ui.open_timer()
ui.open_timer()
assert(ui.is_timer_open(), "Timer should still be open after double open")
ui.close_timer()

-- Test 9: Close when not open is safe
ui.close_timer()

-- Test 10: Test all 4 positions
for _, pos in ipairs({"top_right", "top_left", "bottom_right", "bottom_left"}) do
  config.setup({ timer_ui = { position = pos } })
  ui.open_timer()
  assert(ui.is_timer_open(), "Timer should open at position: " .. pos)
  ui.close_timer()
end

print("PASS: F008 floating corner timer")
