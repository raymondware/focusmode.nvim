local config = require("focusmode.config")

local M = {}

local setup_done = false

function M.setup(opts)
  config.setup(opts)

  -- Load persisted state
  local persist = require("focusmode.persist")
  persist.load()

  -- Register user commands (idempotent - del existing first)
  local cmds = {
    { "FocusStart", function(cmd)
      M.start(cmd.args ~= "" and cmd.args or nil)
    end, { nargs = "?", complete = function()
      return require("focusmode.modes").list()
    end, desc = "Start a focus session" } },

    { "FocusStop", function() M.stop() end,
      { desc = "Stop current session" } },

    { "FocusPause", function() M.pause() end,
      { desc = "Pause current session" } },

    { "FocusResume", function() M.resume() end,
      { desc = "Resume paused session" } },

    { "FocusToggle", function() M.toggle() end,
      { desc = "Toggle focus session" } },

    { "FocusSkip", function() M.skip() end,
      { desc = "Skip to next phase" } },

    { "FocusDashboard", function() M.dashboard() end,
      { desc = "Open statistics dashboard" } },

    { "FocusStatus", function()
      local s = M.status()
      vim.notify(
        string.format("Focus: %s | Mode: %s", s.phase, s.mode or "none"),
        vim.log.levels.INFO,
        { title = "Focus Mode" }
      )
    end, { desc = "Show focus status" } },

    { "FocusPick", function() M.pick() end,
      { desc = "Pick focus mode with Telescope/fzf" } },

    { "FocusReset", function()
      vim.ui.input({ prompt = "Reset all focus data? (yes/no): " }, function(input)
        if input == "yes" then
          require("focusmode.persist").reset()
          vim.notify("Focus data reset", vim.log.levels.INFO, { title = "Focus Mode" })
        end
      end)
    end, { desc = "Reset all persisted data" } },
  }

  -- Remove setup reminder command
  pcall(vim.api.nvim_del_user_command, "FocusmodeSetup")

  for _, cmd in ipairs(cmds) do
    -- Delete if exists (idempotent setup)
    pcall(vim.api.nvim_del_user_command, cmd[1])
    vim.api.nvim_create_user_command(cmd[1], cmd[2], cmd[3])
  end

  -- Set up keymaps if configured
  local keymaps = config.options.keymaps
  if keymaps.toggle then
    vim.keymap.set("n", keymaps.toggle, M.toggle, { desc = "Focus: toggle" })
  end
  if keymaps.start then
    vim.keymap.set("n", keymaps.start, function() M.start() end, { desc = "Focus: start" })
  end
  if keymaps.stop then
    vim.keymap.set("n", keymaps.stop, M.stop, { desc = "Focus: stop" })
  end
  if keymaps.pause then
    vim.keymap.set("n", keymaps.pause, M.pause, { desc = "Focus: pause" })
  end
  if keymaps.dashboard then
    vim.keymap.set("n", keymaps.dashboard, M.dashboard, { desc = "Focus: dashboard" })
  end

  setup_done = true
end

function M.start(mode)
  if not setup_done then
    vim.notify("Call require('focusmode').setup({}) first", vim.log.levels.ERROR, { title = "Focus Mode" })
    return
  end
  require("focusmode.session").start(mode)
end

function M.stop()
  require("focusmode.session").stop()
end

function M.pause()
  require("focusmode.session").pause()
end

function M.resume()
  require("focusmode.session").resume()
end

function M.toggle()
  if not setup_done then
    vim.notify("Call require('focusmode').setup({}) first", vim.log.levels.ERROR, { title = "Focus Mode" })
    return
  end
  require("focusmode.session").toggle()
end

function M.skip()
  require("focusmode.session").skip()
end

function M.dashboard()
  require("focusmode.dashboard").toggle()
end

function M.status()
  if not setup_done then
    return { phase = "idle", mode = nil }
  end
  return require("focusmode.session").get_state()
end

function M.lualine()
  return require("focusmode.lualine").component()
end

function M.pick()
  require("focusmode.picker").pick()
end

return M
