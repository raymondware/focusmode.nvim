local api = vim.api

local M = {}

M.ns = api.nvim_create_namespace("FocusMode")

local function hex_to_rgb(hex)
  hex = type(hex) == "number" and string.format("#%06x", hex) or hex
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  return r, g, b
end

local function rgb_to_hex(r, g, b)
  return string.format("#%02x%02x%02x", math.floor(r), math.floor(g), math.floor(b))
end

local function mix(fg, bg, pct)
  local fr, fg_, fb = hex_to_rgb(fg)
  local br, bg_, bb = hex_to_rgb(bg)
  local t = pct / 100
  return rgb_to_hex(
    br + (fr - br) * t,
    bg_ + (fg_ - bg_) * t,
    bb + (fb - bb) * t
  )
end

local function lighten(hex, amount)
  local r, g, b = hex_to_rgb(hex)
  r = math.min(255, r + amount)
  g = math.min(255, g + amount)
  b = math.min(255, b + amount)
  return rgb_to_hex(r, g, b)
end

local function get_bg()
  local normal = api.nvim_get_hl(0, { name = "Normal" })
  if normal.bg then
    return type(normal.bg) == "number" and string.format("#%06x", normal.bg) or normal.bg
  end
  return "#1a1b26"
end

local function get_fg()
  local normal = api.nvim_get_hl(0, { name = "Normal" })
  if normal.fg then
    return type(normal.fg) == "number" and string.format("#%06x", normal.fg) or normal.fg
  end
  return "#c0caf5"
end

local function get_accent(hl_name, fallback)
  local hl = api.nvim_get_hl(0, { name = hl_name })
  if hl.fg then
    return type(hl.fg) == "number" and string.format("#%06x", hl.fg) or hl.fg
  end
  return fallback
end

function M.setup()
  local ns = M.ns
  local bg = get_bg()
  local fg = get_fg()
  local win_bg = lighten(bg, 4)

  local green = get_accent("DiagnosticOk", "#9ece6a")
  local blue = get_accent("Function", "#7aa2f7")
  local yellow = get_accent("WarningMsg", "#e0af68")
  local cyan = get_accent("Keyword", "#7dcfff")
  local red = get_accent("DiagnosticError", "#f7768e")

  local hl = function(name, opts)
    api.nvim_set_hl(ns, name, opts)
  end

  -- Window base
  hl("Normal", { bg = win_bg, fg = fg })
  hl("FloatBorder", { bg = win_bg, fg = mix(fg, win_bg, 20) })
  hl("FloatTitle", { bg = win_bg, fg = yellow, bold = true })

  -- Timer display
  hl("FocusTimerBg", { bg = win_bg })
  hl("FocusTimerText", { fg = fg, bg = win_bg, bold = true })
  hl("FocusTimerLabel", { fg = mix(fg, win_bg, 60), bg = win_bg })
  hl("FocusTimerSession", { fg = mix(fg, win_bg, 45), bg = win_bg })
  hl("FocusTimerBarOn", { fg = green, bg = win_bg })
  hl("FocusTimerBarOff", { fg = mix(green, win_bg, 15), bg = win_bg })

  -- Phase indicators
  hl("FocusPhaseFocus", { fg = green, bg = win_bg, bold = true })
  hl("FocusPhaseBreak", { fg = blue, bg = win_bg, bold = true })
  hl("FocusPhasePaused", { fg = yellow, bg = win_bg, bold = true })

  -- Toast popup
  local toast_bg = lighten(bg, 8)
  hl("FocusToastTitle", { fg = yellow, bg = toast_bg, bold = true })
  hl("FocusToastBody", { fg = mix(fg, toast_bg, 70), bg = toast_bg })
  hl("FocusToastIcon", { fg = green, bg = toast_bg })

  -- Dashboard
  hl("FocusDashTitle", { fg = yellow, bg = win_bg, bold = true })
  hl("FocusDashHeading", { fg = cyan, bg = win_bg, bold = true })
  hl("FocusDashSep", { fg = mix(fg, win_bg, 12), bg = win_bg })
  hl("FocusDashStatVal", { fg = fg, bg = win_bg, bold = true })
  hl("FocusDashStatLabel", { fg = mix(fg, win_bg, 45), bg = win_bg })
  hl("FocusDashBarOn", { fg = green, bg = win_bg })
  hl("FocusDashBarOff", { fg = mix(green, win_bg, 15), bg = win_bg })
  hl("FocusDashStreak", { fg = yellow, bg = win_bg, bold = true })
  hl("FocusDashGoalMet", { fg = green, bg = win_bg, bold = true })
  hl("FocusDashGoalUnmet", { fg = red, bg = win_bg })

  -- Dimming overlay
  hl("FocusDim", { bg = bg })
end

return M
