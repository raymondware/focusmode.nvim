-- F006: Init module with setup() and commands
local fm = require("focusmode")

-- Test 1: Status before setup returns idle
local s = fm.status()
assert(s.phase == "idle", "Status before setup should be idle, got " .. tostring(s.phase))

-- Test 2: Setup registers commands
fm.setup({})

-- Verify commands exist by checking if they can be called
local commands = vim.api.nvim_get_commands({})
assert(commands["FocusStart"] ~= nil, "FocusStart command should exist after setup")
assert(commands["FocusStop"] ~= nil, "FocusStop command should exist after setup")
assert(commands["FocusPause"] ~= nil, "FocusPause command should exist after setup")
assert(commands["FocusResume"] ~= nil, "FocusResume command should exist after setup")
assert(commands["FocusToggle"] ~= nil, "FocusToggle command should exist after setup")
assert(commands["FocusSkip"] ~= nil, "FocusSkip command should exist after setup")
assert(commands["FocusDashboard"] ~= nil, "FocusDashboard command should exist after setup")
assert(commands["FocusStatus"] ~= nil, "FocusStatus command should exist after setup")
assert(commands["FocusReset"] ~= nil, "FocusReset command should exist after setup")

-- Test 3: FocusmodeSetup reminder was removed
assert(commands["FocusmodeSetup"] == nil, "FocusmodeSetup should be removed after setup()")

-- Test 4: Status after setup
s = fm.status()
assert(s.phase == "idle", "Status after setup should be idle")

-- Test 5: Setup is idempotent
fm.setup({})
commands = vim.api.nvim_get_commands({})
assert(commands["FocusStart"] ~= nil, "Commands should still exist after second setup")

-- Test 6: lualine returns a lualine component table
local component = fm.lualine()
assert(type(component) == "table", "lualine() should return a component table")
assert(type(component[1]) == "function", "lualine component table should expose a callable at index 1")
assert(type(component.color) == "function", "lualine component should expose a color callback")
assert(type(component.cond) == "function", "lualine component should expose a cond callback")
local result = component[1]()
assert(type(result) == "string", "lualine component callable should return a string")

print("PASS: F006 init module with setup() and commands")
