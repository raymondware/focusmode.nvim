# focusmode.nvim

A pomodoro and deep-work timer for Neovim with session persistence, stats, focus lock (suppresses interrupting keymaps), Do Not Disturb integration, and a floating dashboard.

## Features

- **Timer + modes** - Pomodoro, deep work, custom intervals. Configurable per-mode timing in `modes.lua`.
- **Focus lock** - Suppress or warn on configured "interrupting" keymaps during a session.
- **DND integration** - Toggle macOS Do Not Disturb / notification silencing during focus blocks.
- **Session persistence** - State survives Neovim restarts; resume an in-flight pomodoro.
- **Stats** - Track focus minutes, sessions per day, streaks. Floating dashboard for review.
- **Lualine indicator** - Active timer + remaining time in your statusline.
- **Picker UI** - Pick a mode and target duration via telescope-style picker.
- **Editor integrations** - Hooks for other plugins to react to focus state changes.
- **Colorscheme adaptive** - Accent highlights pulled from your active theme.

## Requirements

- Neovim >= 0.9
- macOS (for DND integration; other features cross-platform)

## Installation

### lazy.nvim

```lua
{
  "raymondware/focusmode.nvim",
  config = function()
    require("focusmode").setup({})
  end,
}
```


