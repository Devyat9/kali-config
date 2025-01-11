-- tdrop -x 0% -w 2544 -h 1240 wezterm
-- Pull in the wezterm API
local wezterm = require "wezterm"

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- Color scheme and font
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 14

-- Window decorations
config.window_decorations = "NONE"

-- Default window size
config.initial_rows = 30
config.initial_cols = 100

-- Leader key
config.leader = { key = "s", mods = "CTRL", timeout_milliseconds = 2000 }

-- Key bindings
config.keys = {
    -- Window and pane management
    { mods = "LEADER", key = "c", action = wezterm.action.SpawnTab "DefaultDomain" },
    { mods = "LEADER", key = ",", action = wezterm.action.PromptInputLine {
        description = "Rename Tab",
        action = wezterm.action_callback(function(window, pane, line)
            if line then
                window:active_tab():set_title(line)
            end
        end),
    } },
    { mods = "LEADER", key = "w", action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" } },
    { mods = "LEADER", key = "q", action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" } },
    { mods = "LEADER", key = "z", action = wezterm.action.TogglePaneZoomState },
    { mods = "LEADER", key = "x", action = wezterm.action.CloseCurrentPane { confirm = true } },
    { mods = "LEADER|SHIFT", key = "!", action = wezterm.action_callback(function(win, pane)
        local tab, window = pane:move_to_new_tab()
    end) },

    -- Copy and Paste
    { mods = "CTRL|SHIFT", key = "C", action = wezterm.action.CopyTo "ClipboardAndPrimarySelection" },
    { mods = "CTRL|SHIFT", key = "V", action = wezterm.action.PasteFrom "Clipboard" },

    -- Pane navigation
    { mods = "LEADER", key = "h", action = wezterm.action.ActivatePaneDirection "Left" },
    { mods = "LEADER", key = "j", action = wezterm.action.ActivatePaneDirection "Down" },
    { mods = "LEADER", key = "k", action = wezterm.action.ActivatePaneDirection "Up" },
    { mods = "LEADER", key = "l", action = wezterm.action.ActivatePaneDirection "Right" },

    -- Switch to specific tabs with Alt+number
    { key = "1", mods = "ALT", action = wezterm.action.ActivateTab(0) },
    { key = "2", mods = "ALT", action = wezterm.action.ActivateTab(1) },
    { key = "3", mods = "ALT", action = wezterm.action.ActivateTab(2) },
    { key = "4", mods = "ALT", action = wezterm.action.ActivateTab(3) },
    { key = "5", mods = "ALT", action = wezterm.action.ActivateTab(4) },
    { key = "6", mods = "ALT", action = wezterm.action.ActivateTab(5) },
    { key = "7", mods = "ALT", action = wezterm.action.ActivateTab(6) },
    { key = "8", mods = "ALT", action = wezterm.action.ActivateTab(7) },
    { key = "9", mods = "ALT", action = wezterm.action.ActivateTab(8) },

    -- Move windows
    { mods = "CTRL|SHIFT", key = "LeftArrow", action = wezterm.action.MoveTabRelative(-1) },
    { mods = "CTRL|SHIFT", key = "RightArrow", action = wezterm.action.MoveTabRelative(1) },
}

-- Start tabs and panes at 1
config.tab_and_split_indices_are_zero_based = false

-- Tab bar settings
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false

-- Customize tab titles with Catppuccin colors
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local title = tab.active_pane.title
    if tab.is_active then
        return {
            { Background = { Color = "#fab387" } }, -- Active background (orange)
            { Foreground = { Color = "#1e2030" } }, -- Active foreground (dark)
            { Text = " " .. tab.tab_index + 1 .. ": " .. title .. " " },
        }
    elseif hover then
        return {
            { Background = { Color = "#f5c2e7" } }, -- Hover background (pink)
            { Foreground = { Color = "#1e2030" } }, -- Hover foreground (dark)
            { Text = " " .. tab.tab_index + 1 .. ": " .. title .. " " },
        }
    else
        return {
            { Background = { Color = "#45475a" } }, -- Inactive background (grayish)
            { Foreground = { Color = "#cdd6f4" } }, -- Inactive foreground (light blue)
            { Text = " " .. tab.tab_index + 1 .. ": " .. title .. " " },
        }
    end
end)

-- and finally, return the configuration to wezterm
return config
