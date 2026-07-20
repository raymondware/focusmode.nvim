-- F011: Keybind blocking
local config = require("focusmode.config")
local keybind = require("focusmode.keybind")

-- Test 1: Not blocking initially
assert(not keybind.is_blocking(), "Should not be blocking initially")

-- Test 2: Block with configured keys
config.setup({ keybind_blocking = { enabled = true, blocked_keys = { "<C-z>" } } })
keybind.block()
assert(keybind.is_blocking(), "Should be blocking after block()")

-- Test 3: Unblock restores state
keybind.unblock()
assert(not keybind.is_blocking(), "Should not be blocking after unblock()")

-- Test 4: Block with no keys is safe
config.setup({ keybind_blocking = { enabled = true, blocked_keys = {} } })
keybind.block()
assert(not keybind.is_blocking(), "Empty key list should not activate blocking")

-- Test 5: Double block is safe
config.setup({ keybind_blocking = { enabled = true, blocked_keys = { "<C-z>" } } })
keybind.block()
keybind.block()
assert(keybind.is_blocking(), "Should still be blocking after double block")
keybind.unblock()

-- Test 6: Unblock when not blocking is safe
keybind.unblock()

print("PASS: F011 keybind blocking")
