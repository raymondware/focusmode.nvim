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

-- Test 4: lualine_component returns a lualine component table
local component = integrations.lualine_component()
assert(type(component) == "table", "lualine_component should return a component table")
assert(type(component[1]) == "function", "lualine component table should expose a callable at index 1")
assert(type(component.color) == "function", "lualine component should expose a color callback")
assert(type(component.cond) == "function", "lualine component should expose a cond callback")

-- Test 5: Component callable returns string
local result = component[1]()
assert(type(result) == "string", "Component callable should return a string")

print("PASS: F013 achievement-tracker integration")
