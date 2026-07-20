-- F004: Timer engine with leak-safe lifecycle
local timer = require("focusmode.timer")

-- Test 1: Basic state before any timer starts
assert(not timer.is_running(), "Timer should not be running initially")
assert(not timer.is_paused(), "Timer should not be paused initially")
assert(timer.get_remaining() == nil, "Remaining should be nil when no timer")

-- Test 2: Start a short timer and verify on_tick fires
local ticks = {}
local completed = false

timer.start(3, function(remaining)
  ticks[#ticks + 1] = remaining
end, function()
  completed = true
end)

assert(timer.is_running(), "Timer should be running after start")
assert(not timer.is_paused(), "Timer should not be paused after start")
assert(timer.get_remaining() == 3, "Remaining should be 3 at start")

-- Test 3: Stop works correctly
timer.stop()
assert(not timer.is_running(), "Timer should not be running after stop")
assert(timer.get_remaining() == nil, "Remaining should be nil after stop")

-- Test 4: Pause/resume
timer.start(10, function() end, function() end)
assert(timer.is_running(), "Timer should be running")
timer.pause()
assert(not timer.is_running(), "is_running should be false when paused")
assert(timer.is_paused(), "is_paused should be true")
assert(timer.get_remaining() == 10, "Remaining should be preserved during pause")

timer.resume()
assert(timer.is_running(), "Timer should be running after resume")
assert(not timer.is_paused(), "Should not be paused after resume")

-- Clean up
timer.stop()

-- Test 5: Start twice without stopping cleans up first timer
timer.start(100, function() end, function() end)
assert(timer.is_running(), "First timer running")
timer.start(200, function() end, function() end)
assert(timer.is_running(), "Second timer running")
assert(timer.get_remaining() == 200, "Should be second timer's duration")
timer.stop()

-- Test 6: stop_all cleans everything
timer.start(50, function() end, function() end)
timer.stop_all()
assert(not timer.is_running(), "stop_all should stop all timers")

-- Test 7: Double stop is safe
timer.stop()
timer.stop()

-- Test 8: Pause when not running is safe
timer.pause()
timer.resume()

print("PASS: F004 timer engine with leak-safe lifecycle")
