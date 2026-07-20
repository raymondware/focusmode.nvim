-- F014: Sound/bell on transitions
local config = require("focusmode.config")
local integrations = require("focusmode.integrations")

-- Test 1: play_sound with sound disabled is no-op
config.setup({ sound = { enabled = false } })
integrations.play_sound()

-- Test 2: play_sound with bell enabled writes bell char (just verify no error)
config.setup({ sound = { enabled = true, bell = true } })
integrations.play_sound()

-- Test 3: play_sound with command executes (use echo as safe command)
config.setup({ sound = { enabled = true, bell = false, command = "echo focusmode_bell" } })
integrations.play_sound()

print("PASS: F014 sound/bell on transitions")
