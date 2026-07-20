-- F005: JSON persistence module
local config = require("focusmode.config")

-- Use a temp dir for test isolation
local test_dir = vim.fn.tempname() .. "_focusmode_test"
config.setup({ data_dir = test_dir })

local persist = require("focusmode.persist")

-- Test 1: Fresh load creates default state
persist.load()
local lt = persist.get_lifetime()
assert(lt.minutes == 0, "Fresh state should have 0 lifetime minutes")
assert(lt.sessions == 0, "Fresh state should have 0 lifetime sessions")

-- Test 2: Record a session
persist.record_session("pomodoro", 25, "14:00", "14:25")
lt = persist.get_lifetime()
assert(lt.minutes == 25, "Lifetime should be 25 after one session, got " .. lt.minutes)
assert(lt.sessions == 1, "Lifetime sessions should be 1")

-- Test 3: Daily log updated
local log = persist.get_daily_log()
local today = os.date("%Y-%m-%d")
assert(log[today] == 25, "Daily log should show 25 minutes today, got " .. tostring(log[today]))

-- Test 4: Multiple sessions same day sum correctly
persist.record_session("deep_work", 50, "15:00", "15:50")
log = persist.get_daily_log()
assert(log[today] == 75, "Daily log should show 75 after two sessions, got " .. tostring(log[today]))

-- Test 5: Sessions list
local sessions = persist.get_sessions()
assert(#sessions == 2, "Should have 2 sessions, got " .. #sessions)
assert(sessions[1].mode == "pomodoro", "First session should be pomodoro")
assert(sessions[2].mode == "deep_work", "Second session should be deep_work")

-- Test 6: Filtered sessions
local filtered = persist.get_sessions({ mode = "pomodoro" })
assert(#filtered == 1, "Should have 1 pomodoro session, got " .. #filtered)

-- Test 7: Save and reload round-trips
persist.save()
persist.load()
lt = persist.get_lifetime()
assert(lt.minutes == 75, "Round-trip should preserve lifetime minutes, got " .. lt.minutes)
assert(lt.sessions == 2, "Round-trip should preserve session count")

-- Test 8: Streak tracking
local streaks = persist.get_streaks()
assert(streaks.current >= 1, "Current streak should be at least 1 after recording today")

-- Test 9: Reset clears everything
persist.reset()
lt = persist.get_lifetime()
assert(lt.minutes == 0, "Reset should clear lifetime minutes")
assert(lt.sessions == 0, "Reset should clear lifetime sessions")
sessions = persist.get_sessions()
assert(#sessions == 0, "Reset should clear sessions")

-- Cleanup test dir
vim.fn.delete(test_dir, "rf")

print("PASS: F005 JSON persistence module")
