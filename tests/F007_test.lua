-- F007: Highlight groups
local api = vim.api
local hl = require("focusmode.hl")

-- Test 1: setup() creates namespace
assert(hl.ns ~= nil, "Namespace should exist")
assert(type(hl.ns) == "number", "Namespace should be a number")

-- Test 2: setup() creates highlight groups
hl.setup()

local groups = {
  "FocusTimerText", "FocusTimerLabel", "FocusTimerBarOn", "FocusTimerBarOff",
  "FocusPhaseFocus", "FocusPhaseBreak", "FocusPhasePaused",
  "FocusToastTitle", "FocusToastBody",
  "FocusDashTitle", "FocusDashHeading", "FocusDashSep",
  "FocusDashStatVal", "FocusDashStatLabel",
  "FocusDashBarOn", "FocusDashBarOff", "FocusDashStreak",
  "FocusDashGoalMet", "FocusDashGoalUnmet", "FocusDim",
}

for _, name in ipairs(groups) do
  local group = api.nvim_get_hl(hl.ns, { name = name })
  -- Just verify it exists (has at least one property set)
  local has_prop = group.fg ~= nil or group.bg ~= nil or group.bold ~= nil
  assert(has_prop, "Highlight group " .. name .. " should have properties set")
end

-- Test 3: Namespace isolation - Normal in our ns has custom bg
local our_normal = api.nvim_get_hl(hl.ns, { name = "Normal" })
assert(our_normal.bg ~= nil, "Our Normal should have a custom bg")

-- Test 4: Can call setup() twice without error
hl.setup()

print("PASS: F007 highlight groups")
