-- F013: Achievement-tracker integration
local config = require("focusmode.config")
config.setup({})
local integrations = require("focusmode.integrations")

-- Test 1: award_xp with no tracker installed is no-op (no error)
integrations.award_xp(25)

-- Test 2: earn_daily_achievement with no tracker is no-op
integrations.earn_daily_achievement()

-- Test 3: award_xp with achievements disabled is no-op
config.setup({ achievements = { enabled = false } })
integrations.award_xp(25)

-- Test 4: lualine_component returns callable
local component = integrations.lualine_component()
assert(type(component) == "function", "lualine_component should return a function")

-- Test 5: Component returns string
local result = component()
assert(type(result) == "string", "Component should return a string")

print("PASS: F013 achievement-tracker integration")
