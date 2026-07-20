local config = require("focusmode.config")
local modes = require("focusmode.modes")

local M = {}

-- TODO: Implement this - decides how each mode appears in the picker.
-- Receives: name (string), mode (table with focus, break, long_break, long_break_interval)
-- Returns: display string for the picker entry
-- Consider: compact vs descriptive vs visual approach
local function format_entry(name, mode)
  return name
end

local function get_entries()
  local names = modes.list()
  local entries = {}
  for _, name in ipairs(names) do
    local mode = modes.get(name)
    entries[#entries + 1] = {
      name = name,
      mode = mode,
      display = format_entry(name, mode),
    }
  end
  return entries
end

local function on_select(entry)
  if entry then
    require("focusmode.session").start(entry.name)
  end
end

-- ── Telescope ─────────────────────────────────────────────────

local function pick_telescope(entries)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local previewers = require("telescope.previewers")

  pickers.new({}, {
    prompt_title = "Focus Mode",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.name,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Mode Details",
      define_preview = function(self, entry)
        local mode = entry.value.mode
        local lines = {
          "  " .. entry.value.name:upper(),
          "",
          "  Focus:       " .. mode.focus .. " min",
          "  Break:       " .. mode["break"] .. " min",
          "  Long break:  " .. mode.long_break .. " min",
          "  Rounds:      " .. mode.long_break_interval,
          "",
          "  Total cycle: " .. (mode.focus * mode.long_break_interval + mode["break"] * (mode.long_break_interval - 1) + mode.long_break) .. " min",
        }
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      end,
    }),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          on_select(selection.value)
        end
      end)
      return true
    end,
  }):find()
end

-- ── fzf-lua ───────────────────────────────────────────────────

local function pick_fzf_lua(entries)
  local fzf = require("fzf-lua")
  local display_to_entry = {}
  local displays = {}
  for _, entry in ipairs(entries) do
    display_to_entry[entry.display] = entry
    displays[#displays + 1] = entry.display
  end

  fzf.fzf_exec(displays, {
    prompt = "Focus Mode> ",
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          local entry = display_to_entry[selected[1]]
          on_select(entry)
        end
      end,
    },
  })
end

-- ── vim.ui.select fallback ────────────────────────────────────

local function pick_select(entries)
  local displays = {}
  for _, entry in ipairs(entries) do
    displays[#displays + 1] = entry.display
  end

  vim.ui.select(displays, {
    prompt = "Select focus mode:",
  }, function(choice)
    if not choice then return end
    for _, entry in ipairs(entries) do
      if entry.display == choice then
        on_select(entry)
        return
      end
    end
  end)
end

-- ── Public ────────────────────────────────────────────────────

function M.pick()
  local entries = get_entries()
  if #entries == 0 then
    vim.notify("No focus modes configured", vim.log.levels.WARN, { title = "Focus Mode" })
    return
  end

  local backend = config.options.picker.backend

  if backend == "auto" then
    local has_telescope = pcall(require, "telescope")
    if has_telescope then
      pick_telescope(entries)
      return
    end

    local has_fzf = pcall(require, "fzf-lua")
    if has_fzf then
      pick_fzf_lua(entries)
      return
    end

    pick_select(entries)
  elseif backend == "telescope" then
    pick_telescope(entries)
  elseif backend == "fzf_lua" then
    pick_fzf_lua(entries)
  else
    pick_select(entries)
  end
end

return M
