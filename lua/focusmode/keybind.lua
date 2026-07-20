local config = require("focusmode.config")

local M = {}

local blocking = false
local saved_maps = {}

function M.block()
  if blocking then return end

  local keys = config.options.keybind_blocking.blocked_keys
  if not keys or #keys == 0 then return end

  blocking = true
  saved_maps = {}

  for _, key in ipairs(keys) do
    -- Save existing mapping
    local existing = vim.fn.maparg(key, "n", false, true)
    if existing and existing.lhs then
      saved_maps[key] = existing
    else
      saved_maps[key] = false -- mark as "had no mapping"
    end
    -- Replace with no-op
    vim.keymap.set("n", key, "<Nop>", { desc = "focusmode: blocked", nowait = true })
  end
end

function M.unblock()
  if not blocking then return end
  blocking = false

  for key, saved in pairs(saved_maps) do
    -- Delete the no-op mapping first
    pcall(vim.keymap.del, "n", key)
    -- Restore original if it existed
    if saved and saved.lhs then
      local rhs = saved.callback or saved.rhs
      if rhs then
        local opts = {
          silent = saved.silent == 1,
          noremap = saved.noremap == 1,
          expr = saved.expr == 1,
          nowait = saved.nowait == 1,
          desc = saved.desc,
        }
        if saved.callback then
          opts.callback = saved.callback
          vim.keymap.set("n", key, "", opts)
        else
          vim.keymap.set("n", key, rhs, opts)
        end
      end
    end
  end

  saved_maps = {}
end

function M.is_blocking()
  return blocking
end

return M
