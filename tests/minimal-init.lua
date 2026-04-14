-- Minimal init for headless testing of focusmode.nvim
-- Usage: nvim --headless -u tests/minimal-init.lua -c "luafile tests/FXXX_test.lua" -c "qa!"

-- Add plugin to runtime path
local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.rtp:prepend(plugin_root)

-- Add plenary if available (for busted-style tests)
local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 1 then
  vim.opt.rtp:prepend(plenary_path)
end

-- Add achievement-tracker if available (for integration tests)
local tracker_path = vim.fn.expand("~/achievement-tracker.nvim")
if vim.fn.isdirectory(tracker_path) == 1 then
  vim.opt.rtp:prepend(tracker_path)
end

-- Minimal settings for testing
vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false
