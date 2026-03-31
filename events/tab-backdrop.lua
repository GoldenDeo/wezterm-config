local wezterm = require('wezterm')
local backdrops = require('utils.backdrops')

local tab_backdrops = {}  -- tab_id -> backdrop_idx
local last_active = {}    -- window_id -> tab_id

local M = {}

function M.set_for_tab(pane, idx)
   tab_backdrops[pane:tab():tab_id()] = idx
end

function M.setup()
   wezterm.on('update-status', function(window, pane)
      local win_id = window:window_id()
      local tab_id = window:active_tab():tab_id()

      if last_active[win_id] == tab_id then
         return
      end
      last_active[win_id] = tab_id

      local idx = tab_backdrops[tab_id]
      if idx then
         backdrops:set_img(window, idx)
      else
         backdrops:random(window)
         tab_backdrops[tab_id] = backdrops.current_idx
      end
   end)
end

return M
