local config = require("focusmode.config")

local M = {}

local active = false
local original_notify = nil
local queued = {}

function M.enable()
  if active then return end
  if not config.options.dnd.suppress_notify then return end

  active = true
  queued = {}
  original_notify = vim.notify

  vim.notify = function(msg, level, opts)
    -- Queue for later delivery
    queued[#queued + 1] = { msg = msg, level = level, opts = opts }
  end
end

function M.disable()
  if not active then return end
  active = false

  -- Restore original notify
  if original_notify then
    vim.notify = original_notify
  end

  -- Flush queued notifications
  if #queued > 0 then
    vim.schedule(function()
      for _, item in ipairs(queued) do
        vim.notify(item.msg, item.level, item.opts)
      end
      queued = {}
    end)
  end

  original_notify = nil
end

function M.is_active()
  return active
end

return M
