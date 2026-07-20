-- F002: Config module with full schema
local config = require("focusmode.config")

-- Test 1: Setup with empty opts applies defaults
config.setup({})
assert(config.options.focus_duration == 25, "Expected default focus_duration=25, got " .. tostring(config.options.focus_duration))
assert(config.options.break_duration == 5, "Expected default break_duration=5")
assert(config.options.timer_ui.position == "top_right", "Expected default position=top_right")

-- Test 2: Override merges correctly
config.setup({ focus_duration = 50 })
assert(config.options.focus_duration == 50, "Expected overridden focus_duration=50, got " .. tostring(config.options.focus_duration))
assert(config.options.break_duration == 5, "Non-overridden defaults should persist")

-- Test 3: Custom mode merges with defaults
config.setup({ modes = { custom = { focus = 10, ["break"] = 2, long_break = 5, long_break_interval = 3 } } })
assert(config.options.modes.custom ~= nil, "Custom mode should exist")
assert(config.options.modes.custom.focus == 10, "Custom mode focus should be 10")
assert(config.options.modes.pomodoro ~= nil, "Default pomodoro mode should persist")

-- Test 4: get_mode resolves correctly
config.setup({})
local pom = config.get_mode("pomodoro")
assert(pom.focus == 25, "Pomodoro focus should be 25")
assert(pom["break"] == 5, "Pomodoro break should be 5")

-- Test 5: get_mode fallback for unknown mode
local fallback = config.get_mode("nonexistent")
assert(fallback.focus == 25, "Unknown mode should fall back to default (pomodoro)")

-- Test 6: Defaults are not mutated by setup
config.setup({ focus_duration = 99 })
assert(config.defaults.focus_duration == 25, "Defaults should not be mutated")

print("PASS: F002 config module with full schema")
