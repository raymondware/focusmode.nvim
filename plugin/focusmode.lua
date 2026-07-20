if vim.g.loaded_focusmode then
  return
end
vim.g.loaded_focusmode = true

vim.api.nvim_create_user_command("FocusmodeSetup", function()
  vim.notify(
    'Call require("focusmode").setup({}) in your init.lua',
    vim.log.levels.WARN,
    { title = "Focus Mode" }
  )
end, { desc = "Focus Mode setup reminder" })
