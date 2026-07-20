-- F010: Session state machine
local config = require("focusmode.config")
config.setup({ timer_ui = { enabled = false }, toast = { enabled = false }, sound = { enabled = false } })

local session = require("focusmode.session")

-- Test 1: Initial state is idle
local s = session.get_state()
assert(s.phase == "idle", "Initial phase should be idle, got " .. s.phase)

-- Test 2: Start sets phase to focus
session.start("pomodoro")
s = session.get_state()
assert(s.phase == "focus", "Phase should be focus after start, got " .. s.phase)
assert(s.mode == "pomodoro", "Mode should be pomodoro, got " .. tostring(s.mode))
assert(s.session_number == 1, "Session number should be 1, got " .. s.session_number)

-- Test 3: Pause
session.pause()
s = session.get_state()
assert(s.phase == "paused", "Phase should be paused, got " .. s.phase)

-- Test 4: Resume
session.resume()
s = session.get_state()
assert(s.phase == "focus", "Phase should be focus after resume, got " .. s.phase)

-- Test 5: Stop returns to idle
session.stop()
s = session.get_state()
assert(s.phase == "idle", "Phase should be idle after stop, got " .. s.phase)

-- Test 6: Skip during focus
session.start("pomodoro")
s = session.get_state()
assert(s.phase == "focus", "Should be in focus")
session.skip()
s = session.get_state()
-- Skip from focus should go to break (if auto_start_break) or idle
assert(s.phase == "break" or s.phase == "idle",
  "After skip from focus, phase should be break or idle, got " .. s.phase)
session.stop()

-- Test 7: Toggle from idle starts, from running pauses, from paused resumes
s = session.get_state()
assert(s.phase == "idle", "Should start idle")

session.toggle()
s = session.get_state()
assert(s.phase == "focus", "Toggle from idle should start focus, got " .. s.phase)

session.toggle()
s = session.get_state()
assert(s.phase == "paused", "Toggle from focus should pause, got " .. s.phase)

session.toggle()
s = session.get_state()
assert(s.phase == "focus", "Toggle from paused should resume, got " .. s.phase)

session.stop()

-- Test 8: get_state returns expected fields
session.start("deep_work")
s = session.get_state()
assert(s.phase ~= nil, "get_state should have phase")
assert(s.mode ~= nil, "get_state should have mode")
assert(s.session_number ~= nil, "get_state should have session_number")
assert(s.remaining_seconds ~= nil, "get_state should have remaining_seconds")
session.stop()

-- Test 9: Pause when idle is no-op
session.pause()
s = session.get_state()
assert(s.phase == "idle", "Pause when idle should remain idle")

-- Test 10: Resume when not paused is no-op
session.start("pomodoro")
session.resume()
s = session.get_state()
assert(s.phase == "focus", "Resume when not paused should stay in focus")
session.stop()

-- Test 11: on_phase_change callback fires
local changes = {}
session.on_phase_change(function(new, old)
  changes[#changes + 1] = { new = new, old = old }
end)

session.start("review")
assert(#changes >= 1, "Should have at least 1 phase change after start")
assert(changes[#changes].new == "focus", "Latest change should be to focus")
session.stop()
assert(changes[#changes].new == "idle", "Stop should fire idle change")

print("PASS: F010 session state machine")
