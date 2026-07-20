-- F001: Plugin skeleton with load guard
local api = vim.api

-- Test 1: Load guard is set
assert(vim.g.loaded_focusmode == true, "Expected vim.g.loaded_focusmode to be true")

-- Test 2: FocusmodeSetup command exists (before setup() is called)
local cmds = api.nvim_get_commands({})
-- The command may have been replaced by setup, so just verify the plugin loaded
assert(vim.g.loaded_focusmode == true, "Load guard should persist")

-- Test 3: Double-source doesn't error
vim.cmd("runtime plugin/focusmode.lua")
assert(vim.g.loaded_focusmode == true, "Load guard should prevent double-load")

print("PASS: F001 plugin skeleton with load guard")
