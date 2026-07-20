-- F003: Focus mode definitions
local config = require("focusmode.config")
config.setup({})
local modes = require("focusmode.modes")

-- Test 1: Get pomodoro mode
local pom = modes.get("pomodoro")
assert(pom.focus == 25, "Pomodoro focus should be 25, got " .. tostring(pom.focus))
assert(pom["break"] == 5, "Pomodoro break should be 5")
assert(pom.long_break == 15, "Pomodoro long_break should be 15")
assert(pom.long_break_interval == 4, "Pomodoro long_break_interval should be 4")

-- Test 2: Get nonexistent falls back to default
local fb = modes.get("nonexistent")
assert(fb.focus == 25, "Nonexistent mode should fall back to pomodoro defaults")

-- Test 3: List returns all mode names
local names = modes.list()
assert(#names >= 4, "Should have at least 4 default modes, got " .. #names)
local found_pomodoro = false
for _, n in ipairs(names) do
  if n == "pomodoro" then found_pomodoro = true end
end
assert(found_pomodoro, "Mode list should include 'pomodoro'")

-- Test 4: List includes user-defined modes
config.setup({ modes = { sprint = { focus = 15, ["break"] = 2, long_break = 5, long_break_interval = 6 } } })
names = modes.list()
local found_sprint = false
for _, n in ipairs(names) do
  if n == "sprint" then found_sprint = true end
end
assert(found_sprint, "Mode list should include user-defined 'sprint'")

-- Test 5: Validate catches missing fields
local ok, err = modes.validate({ focus = 10 })
assert(not ok, "Validate should fail for incomplete mode")
assert(err:find("missing"), "Error should mention missing field")

-- Test 6: Validate accepts complete mode
ok, err = modes.validate({ focus = 10, ["break"] = 2, long_break = 5, long_break_interval = 3 })
assert(ok, "Validate should pass for complete mode: " .. tostring(err))

print("PASS: F003 focus mode definitions")
