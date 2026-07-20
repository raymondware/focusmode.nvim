local M = {}

local timer_handle = nil
local remaining = 0
local paused = false
local on_tick_cb = nil
local on_complete_cb = nil
local autocmd_id = nil

-- Tick callback shared between start and resume
local function make_tick()
  return vim.schedule_wrap(function()
    if not timer_handle then return end
    remaining = remaining - 1
    if on_tick_cb then
      on_tick_cb(remaining)
    end
    if remaining <= 0 then
      local cb = on_complete_cb
      M.stop()
      if cb then
        cb()
      end
    end
  end)
end

function M.start(duration_seconds, on_tick, on_complete)
  -- Always clean up existing timer first
  M.stop()

  remaining = duration_seconds
  paused = false
  on_tick_cb = on_tick
  on_complete_cb = on_complete

  timer_handle = vim.uv.new_timer()
  timer_handle:start(1000, 1000, make_tick())
end

function M.pause()
  if not timer_handle or paused then return end
  timer_handle:stop()
  paused = true
end

function M.resume()
  if not timer_handle or not paused then return end
  timer_handle:start(1000, 1000, make_tick())
  paused = false
end

function M.stop()
  if timer_handle then
    if timer_handle:is_active() then
      timer_handle:stop()
    end
    if not timer_handle:is_closing() then
      timer_handle:close()
    end
    timer_handle = nil
  end
  remaining = 0
  paused = false
  on_tick_cb = nil
  on_complete_cb = nil
end

function M.stop_all()
  M.stop()
end

function M.get_remaining()
  if not timer_handle then return nil end
  return remaining
end

function M.is_running()
  return timer_handle ~= nil and not paused
end

function M.is_paused()
  return timer_handle ~= nil and paused
end

function M.cleanup()
  M.stop_all()
  if autocmd_id then
    vim.api.nvim_del_autocmd(autocmd_id)
    autocmd_id = nil
  end
end

-- Register VimLeavePre cleanup to prevent timer leaks
autocmd_id = vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    M.stop_all()
  end,
  desc = "focusmode: clean up timers on exit",
})

return M
