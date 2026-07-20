-- F012: Do Not Disturb mode
local config = require("focusmode.config")
config.setup({})
local dnd = require("focusmode.dnd")

-- Test 1: Not active initially
assert(not dnd.is_active(), "DND should not be active initially")

-- Test 2: Enable suppresses vim.notify
local original = vim.notify
dnd.enable()
assert(dnd.is_active(), "DND should be active after enable")

-- Test 3: vim.notify is replaced
assert(vim.notify ~= original, "vim.notify should be replaced during DND")

-- Test 4: Disable restores vim.notify
dnd.disable()
assert(not dnd.is_active(), "DND should not be active after disable")
assert(vim.notify == original, "vim.notify should be restored after disable")

-- Test 5: Double enable is safe
dnd.enable()
dnd.enable()
assert(dnd.is_active(), "Should still be active after double enable")
dnd.disable()

-- Test 6: Disable when not active is safe
dnd.disable()

print("PASS: F012 Do Not Disturb mode")
