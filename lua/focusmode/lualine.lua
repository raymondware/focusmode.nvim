local config = require("focusmode.config")

local M = {}

local function progress_bar(pct, width)
  local filled = math.floor(pct * width)
  local empty = width - filled
  return string.rep("▓", filled) .. string.rep("░", empty)
end

local function get_phase_color()
  local api = vim.api
  local phase_hl_map = {
    focus = "DiagnosticOk",
    ["break"] = "Function",
    long_break = "Function",
    paused = "WarningMsg",
  }

  local ok, session = pcall(require, "focusmode.session")
  if not ok then return nil end

  local state = session.get_state()
  local hl_name = phase_hl_map[state.phase]
  if not hl_name then return nil end

  local hl = api.nvim_get_hl(0, { name = hl_name })
  if hl.fg then
    local fg = type(hl.fg) == "number" and string.format("#%06x", hl.fg) or hl.fg
    return { fg = fg }
  end

  -- Fallbacks
  local fallbacks = {
    focus = "#9ece6a",
    ["break"] = "#7aa2f7",
    long_break = "#7aa2f7",
    paused = "#e0af68",
  }
  return { fg = fallbacks[state.phase] or "#c0caf5" }
end

local function format_template(template, tokens)
  local result = template
  for key, value in pairs(tokens) do
    result = result:gsub("{" .. key .. "}", value)
  end
  -- Collapse multiple spaces from empty tokens
  result = result:gsub("  +", " ")
  -- Clean up empty parens/brackets from missing tokens
  result = result:gsub("%(%s*%)", "")
  result = result:gsub("%[%s*%]", "")
  return vim.trim(result)
end

function M.component()
  return {
    function()
      local ok, session = pcall(require, "focusmode.session")
      if not ok then return "" end

      local state = session.get_state()
      if not state or state.phase == "idle" then
        return config.options.lualine.icon_idle
      end

      local opts = config.options.lualine
      local remaining = state.remaining_seconds or 0
      local minutes = math.floor(remaining / 60)
      local seconds = remaining % 60
      local time_str = string.format("%02d:%02d", minutes, seconds)

      local total = state.total_seconds or 1
      if total <= 0 then total = 1 end
      local pct = 1 - (remaining / total)

      local tokens = {
        icon = "",
        time = time_str,
        bar = opts.show_progress and progress_bar(pct, opts.progress_width) or "",
        mode = opts.show_mode and (state.mode or ""):upper() or "",
        session = "",
      }

      if opts.show_session_count and state.session_number and state.total_sessions and state.total_sessions > 0 then
        tokens.session = string.format("%d/%d", state.session_number, state.total_sessions)
      end

      local icons = config.options.lualine
      local template

      if state.phase == "focus" then
        tokens.icon = icons.icon_focus
        template = opts.format_focus
      elseif state.phase == "break" or state.phase == "long_break" then
        tokens.icon = icons.icon_break
        template = opts.format_break
      elseif state.phase == "paused" then
        tokens.icon = icons.icon_paused
        template = opts.format_paused
      else
        return ""
      end

      return format_template(template, tokens)
    end,
    color = get_phase_color,
    cond = function()
      local ok, session = pcall(require, "focusmode.session")
      if not ok then return false end
      local state = session.get_state()
      return state and state.phase ~= "idle"
    end,
  }
end

return M
