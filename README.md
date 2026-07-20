# focusmode.nvim

A Pomodoro and deep-work timer that lives inside Neovim. Structured focus/break intervals, distraction blocking, session stats, and a dashboard.

## Features

- **Timer engine** -- pomodoro, deep work, and custom interval modes. Configurable per-mode timing.
- **Focus lock** -- warns or blocks `:q` / `:qa` during active focus sessions.
- **Do Not Disturb** -- suppresses `vim.notify` during focus. Queued notifications flush when focus ends.
- **Keybind blocking** -- temporarily replaces distracting keymaps with `<Nop>` during sessions.
- **Auto-pause** -- pauses on `FocusLost`, resumes on `FocusGained`. Optional idle timeout.
- **Stats dashboard** -- floating window with today's progress, weekly breakdown, streaks, per-mode stats, lifetime totals, and recent sessions.
- **Lualine component** -- statusline widget showing timer, progress bar, mode name, and session count.
- **Mode picker** -- telescope, fzf-lua, or native `vim.ui.select` to choose a focus mode.
- **Toast notifications** -- auto-dismissing popups for session milestones.
- **Sound alerts** -- terminal bell or custom shell command on phase transitions.
- **Achievement tracker** -- optional integration with `achievement-tracker.nvim` for XP and daily achievements.
- **Colorscheme adaptive** -- UI highlights pull accent colors from the active theme.

## Requirements

- Neovim >= 0.9
- macOS (for DND integration; all other features are cross-platform)

## Installation

### lazy.nvim

```lua
{
  "raymondware/focusmode.nvim",
  config = function()
    require("focusmode").setup({
      keymaps = {
        toggle = "<leader>ft",
        start = "<leader>fs",
        stop = "<leader>fx",
        pause = "<leader>fp",
        dashboard = "<leader>fd",
      },
    })
  end,
}
```

### Optional dependencies

| Plugin | Unlocks |
|---|---|
| `nvim-telescope/telescope.nvim` | Rich mode picker with preview |
| `ibhagwan/fzf-lua` | Alternative mode picker |
| `nvim-lualine/lualine.nvim` | Statusline timer component |
| `raymondware/achievement-tracker.nvim` | XP and daily achievements |

## Usage

### Commands

| Command | Description |
|---|---|
| `:FocusStart [mode]` | Start a focus session. Mode name autocompletes from available modes. |
| `:FocusStop` | Stop the current session. |
| `:FocusPause` | Pause the current session. |
| `:FocusResume` | Resume a paused session. |
| `:FocusToggle` | Smart toggle -- idle starts timer, running pauses, paused resumes. |
| `:FocusSkip` | Skip to the next phase (focus to break, break to focus). |
| `:FocusDashboard` | Open the stats dashboard. |
| `:FocusStatus` | Show current state in a notification. |
| `:FocusPick` | Open the mode picker. |
| `:FocusReset` | Reset all persisted data (prompts for confirmation). |

### Keymaps

No default mappings. Set `keymaps` in your config to register the following:

| Config key | Action |
|---|---|
| `keymaps.toggle` | Toggle focus: idle -> start, running -> pause, paused -> resume |
| `keymaps.start` | Start a focus session |
| `keymaps.stop` | Stop the current session |
| `keymaps.pause` | Pause or resume the current session |
| `keymaps.dashboard` | Open the stats dashboard |

Dashboard keymaps (always active):

| Key | Action |
|---|---|
| `q` / `<Esc>` | Close dashboard |

### Lua API

```lua
local focus = require("focusmode")

focus.start("deep_work")  -- Start a session with a named mode
focus.stop()              -- Stop current session
focus.pause()             -- Pause current session
focus.resume()            -- Resume paused session
focus.toggle()            -- Smart toggle
focus.skip()              -- Skip to next phase
focus.dashboard()         -- Toggle stats dashboard
focus.status()            -- Returns { phase, mode, remaining_seconds, ... }
focus.pick()              -- Open mode picker
```

### Lualine

Add the component to your lualine config:

```lua
require("lualine").setup({
  sections = {
    lualine_x = { require("focusmode").lualine() },
  },
})
```

## Configuration

Full defaults shown below. Pass overrides to `setup()`.

```lua
require("focusmode").setup({
  -- Timing
  focus_duration = 25,          -- minutes
  break_duration = 5,
  long_break_duration = 15,
  long_break_interval = 4,      -- sessions before a long break
  auto_start_break = true,
  auto_start_focus = false,
  default_mode = "pomodoro",

  -- Mode presets (focus, break, long_break, long_break_interval in minutes)
  modes = {
    pomodoro   = { focus = 25, break = 5,  long_break = 15, long_break_interval = 4 },
    deep_work  = { focus = 50, break = 10, long_break = 20, long_break_interval = 2 },
    review     = { focus = 15, break = 3,  long_break = 10, long_break_interval = 4 },
    learning   = { focus = 30, break = 10, long_break = 15, long_break_interval = 3 },
  },

  -- Floating timer window
  timer_ui = {
    enabled = true,
    position = "top_right",     -- top_left, bottom_right, bottom_left, center_top, center_bottom
    row_offset = 0,
    col_offset = 0,
    width = 22,
    border = "rounded",
    zindex = 50,
    blend = 10,
    show_mode = true,
    show_session_count = true,
  },

  -- Toast notifications
  toast = {
    enabled = true,
    duration_ms = 4000,
    width = 40,
    position = "bottom_right",  -- bottom_left, top_right, top_left
  },

  -- Sound alerts
  sound = {
    enabled = false,
    on_focus_end = true,
    on_break_end = true,
    bell = true,                -- terminal bell (\a); set false and provide command for custom sound
    command = nil,              -- shell command, e.g. "afplay /path/to/sound.wav"
  },

  -- Distraction blocking
  keybind_blocking = {
    enabled = false,
    blocked_keys = {},          -- keys to disable during focus, e.g. { "<C-n>", "<C-p>" }
    allow_override = true,
  },

  -- Auto-pause
  auto_pause = {
    enabled = false,
    on_focus_lost = true,       -- pause when Neovim loses focus
    on_idle = false,
    idle_timeout = 120,         -- seconds
  },

  -- Daily/weekly goals
  goals = {
    daily_minutes = 120,
    weekly_minutes = 600,
  },

  -- Achievement tracker integration
  achievements = {
    enabled = true,
    xp_per_focus_minute = 4,
    bonus_streak_multiplier = 1.5,
    daily_achievement_id = "deep_focus_session",
  },

  -- Do Not Disturb
  dnd = {
    enabled = false,
    suppress_notify = true,     -- block vim.notify during focus
    suppress_diagnostics = false,
  },

  -- Quit protection
  focus_lock = {
    enabled = false,
    severity = "warn",          -- "warn" shows confirm dialog, "block" prevents quit
    message = "You're in a focus session! Are you sure you want to quit?",
  },

  -- Mode picker
  picker = {
    backend = "auto",           -- "auto", "telescope", "fzf_lua", "select"
  },

  -- Keymap bindings (set to nil to skip)
  keymaps = {
    toggle = nil,
    start = nil,
    stop = nil,
    pause = nil,
    dashboard = nil,
  },

  -- Data directory for persistence
  data_dir = vim.fn.stdpath("data") .. "/focusmode",

  -- Lualine component
  lualine = {
    icon_focus = "󰔛",
    icon_break = "󰾴",
    icon_paused = "󰏤",
    icon_idle = "",
    show_progress = true,
    show_session_count = true,
    show_mode = true,
    progress_width = 6,
    format_focus = "{icon} {time} {bar} ({mode} {session})",
    format_break = "{icon} {time} {bar}",
    format_paused = "{icon} PAUSED {time}",
  },
})
```