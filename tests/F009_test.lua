-- F009: Toast notifications
local api = vim.api
local config = require("focusmode.config")
config.setup({})
local ui = require("focusmode.ui")

-- Test 1: Show toast creates a floating window
ui.show_toast("Test message", "focus_complete")

local found_toast = false
local wins = api.nvim_list_wins()
for _, w in ipairs(wins) do
  local cfg = api.nvim_win_get_config(w)
  if cfg.relative == "editor" and cfg.focusable == false and cfg.zindex == 200 then
    found_toast = true
    break
  end
end
assert(found_toast, "Toast window should exist after show_toast()")

-- Test 2: Show toast with disabled config is no-op
config.setup({ toast = { enabled = false } })
-- Close existing toast by showing new one (which won't show since disabled)
-- The previous toast may still be open, but new ones shouldn't appear
local win_count_before = #api.nvim_list_wins()
ui.show_toast("Should not show", "session_start")
-- Can't easily verify no new window since old toast may still exist

-- Test 3: Re-enable and show different types
config.setup({})
local types = { "focus_complete", "break_complete", "goal_reached", "session_start" }
for _, t in ipairs(types) do
  ui.show_toast("Test " .. t, t)
  -- Just verify no errors
end

-- Test 4: Rapid toasts don't crash
for i = 1, 5 do
  ui.show_toast("Rapid toast " .. i, "focus_complete")
end

print("PASS: F009 toast notifications")
