local wezterm = require('wezterm')
local backdrops = require('utils.backdrops')

local tab_backdrops = {} -- tab_id -> backdrop_idx

local M = {}

function M.set_for_tab(pane, idx)
   tab_backdrops[pane:tab():tab_id()] = idx
end

function M.apply_for_tab(window)
   local tab_id = window:active_tab():tab_id()
   local idx = tab_backdrops[tab_id]
   if idx then
      backdrops:set_img(window, idx)
   end
end

return M
