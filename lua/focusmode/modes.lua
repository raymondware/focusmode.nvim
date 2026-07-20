local config = require("focusmode.config")

local M = {}

local required_fields = { "focus", "break", "long_break", "long_break_interval" }

function M.get(name)
  return config.get_mode(name)
end

function M.list()
  local modes = config.options.modes or config.defaults.modes
  local names = {}
  for k in pairs(modes) do
    names[#names + 1] = k
  end
  table.sort(names)
  return names
end

function M.validate(mode_table)
  if type(mode_table) ~= "table" then
    return false, "mode must be a table"
  end
  for _, field in ipairs(required_fields) do
    if mode_table[field] == nil then
      return false, "missing required field: " .. field
    end
    if type(mode_table[field]) ~= "number" then
      return false, field .. " must be a number"
    end
  end
  return true, nil
end

return M
