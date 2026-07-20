local config = require("focusmode.config")

local M = {}

local autocmd_id = nil

local function is_focus_active()
  local ok, session = pcall(require, "focusmode.session")
  if not ok then return false end
  local state = session.get_state()
  return state and state.phase == "focus"
end

local function handle_quit()
  if not config.options.focus_lock.enabled then return end
  if not is_focus_active() then return end

  local severity = config.options.focus_lock.severity
  local message = config.options.focus_lock.message

  if severity == "block" then
    vim.notify(message, vim.log.levels.WARN, { title = "Focus Lock" })
    -- Abort the quit by throwing
    error("Focus lock: quit blocked during focus session")
  else
    -- "warn" - confirm dialog
    local choice = vim.fn.confirm(message, "&Yes\n&No", 2)
    if choice ~= 1 then
      error("Focus lock: quit cancelled by user")
    end
    -- choice == 1 means user confirmed quit, let it proceed
  end
end

function M.enable()
  if autocmd_id then return end

  autocmd_id = vim.api.nvim_create_autocmd("QuitPre", {
    group = vim.api.nvim_create_augroup("FocusModeLock", { clear = true }),
    callback = function()
      local ok, err = pcall(handle_quit)
      if not ok and err then
        -- Abort the quit
        vim.api.nvim_err_writeln("")
        return true -- returning true from QuitPre prevents quit in some contexts
      end
    end,
    desc = "focusmode: focus lock quit protection",
  })
end

function M.disable()
  if autocmd_id then
    pcall(vim.api.nvim_del_autocmd, autocmd_id)
    autocmd_id = nil
  end
  pcall(vim.api.nvim_del_augroup_by_name, "FocusModeLock")
end

function M.is_active()
  return autocmd_id ~= nil
end

return M
