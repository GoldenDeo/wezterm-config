local wezterm = require("wezterm")

local config = {}

-- 🌈 Константи для градієнту
local TAB_BAR_BG = '#1e2030'  -- Catppuccin Macchiato mantle (фон між вкладками і статусом)
local TIME_BG    = '#1a1a1a'  -- Фон секції з годинником

-- 🎨 Динамічний колір вкладки на основі імені репозиторію
local function hash_to_hue(str)
  local h = 0
  for i = 1, #str do
    h = (h * 31 + str:byte(i)) % 360
  end
  return h
end

-- HSL → RGB → hex
local function hsl_to_hex(h, s, l)
  local function hue2rgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1/6 then return p + (q - p) * 6 * t end
    if t < 1/2 then return q end
    if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
    return p
  end
  h = h / 360
  local q = l < 0.5 and l * (1 + s) or l + s - l * s
  local p = 2 * l - q
  local r = math.floor(hue2rgb(p, q, h + 1/3) * 255)
  local g = math.floor(hue2rgb(p, q, h) * 255)
  local b = math.floor(hue2rgb(p, q, h - 1/3) * 255)
  return string.format('#%02x%02x%02x', r, g, b)
end

-- 🌈 Градієнт-хелпери
local function hex_to_rgb(hex)
  hex = hex:gsub('#', '')
  return {
    r = tonumber(hex:sub(1, 2), 16),
    g = tonumber(hex:sub(3, 4), 16),
    b = tonumber(hex:sub(5, 6), 16),
  }
end

local function lerp_color(c1, c2, t)
  local a = hex_to_rgb(c1)
  local b = hex_to_rgb(c2)
  return string.format('#%02x%02x%02x',
    math.floor(a.r + (b.r - a.r) * t),
    math.floor(a.g + (b.g - a.g) * t),
    math.floor(a.b + (b.b - a.b) * t)
  )
end

-- Генерує список формат-елементів для градієнту між кількома кольорами
-- colors = { '#aaa', '#bbb', '#ccc', ... }, steps_each = кроків між кожною парою
local function make_gradient(colors, steps_each)
  local els = {}
  for seg = 1, #colors - 1 do
    local c1, c2 = colors[seg], colors[seg + 1]
    for i = 0, steps_each - 1 do
      local bg = lerp_color(c1, c2, i / steps_each)
      local fg = lerp_color(c1, c2, (i + 1) / steps_each)
      table.insert(els, { Background = { Color = bg } })
      table.insert(els, { Foreground = { Color = fg } })
      table.insert(els, { Text = '█' })
    end
  end
  return els
end

local function get_repo(cwd_uri)
  if not cwd_uri then return 'default' end
  local cwd = cwd_uri.file_path or tostring(cwd_uri)
  return cwd:match('([^/]+)/?$') or 'default'
end

local function get_tab_color(tab)
  local repo = get_repo(tab.active_pane.current_working_dir)
  local hue = hash_to_hue(repo)
  return {
    bg = hsl_to_hex(hue, 0.4, 0.18),
    fg = hsl_to_hex(hue, 0.8, 0.75),
  }
end

-- 📍 Правий статус-бар: репка + годинник
wezterm.on('update-right-status', function(window, pane)
  local cwd_uri = pane:get_current_working_dir()
  local repo = ''
  local path = ''
  if cwd_uri then
    local cwd = cwd_uri.file_path or tostring(cwd_uri)
    local home = os.getenv('HOME') or ''
    path = cwd:gsub(home, '~'):gsub('/$', '')
    repo = cwd:match('([^/]+)/?$') or cwd
  end

  local hue = hash_to_hue(repo ~= '' and repo or 'default')
  local bg  = hsl_to_hex(hue, 0.55, 0.25)
  local fg  = hsl_to_hex(hue, 0.9,  0.82)
  local dim = hsl_to_hex(hue, 0.4,  0.55)
  local parent = path:match('(.+)/[^/]*$') or ''

  local time = wezterm.strftime('%H:%M')

  -- Градієнт: фон вкладок → акцент репо → фон годинника
  local accent = hsl_to_hex(hue, 0.5, 0.28)
  local grad = make_gradient({ TAB_BAR_BG, accent, TIME_BG }, 5)

  local elements = {}
  for _, el in ipairs(grad) do
    table.insert(elements, el)
  end

  -- Годинник
  table.insert(elements, { Background = { Color = TIME_BG } })
  table.insert(elements, { Foreground = { Color = '#666666' } })
  table.insert(elements, { Text = '  ' .. time .. '  ' })
  -- Стрілка-роздільник
  table.insert(elements, { Foreground = { Color = bg } })
  table.insert(elements, { Text = '' })
  -- Шлях (приглушений)
  table.insert(elements, { Background = { Color = bg } })
  table.insert(elements, { Foreground = { Color = dim } })
  table.insert(elements, { Text = '   ' .. parent .. '/' })
  -- Назва репки (жирна, яскрава)
  table.insert(elements, { Foreground = { Color = fg } })
  table.insert(elements, { Attribute = { Intensity = 'Bold' } })
  table.insert(elements, { Text = repo .. '   ' })

  window:set_right_status(wezterm.format(elements))
end)


wezterm.on('format-tab-title', function(tab)
  local colors = get_tab_color(tab)
  local title = tab.active_pane.title
  local cwd_uri = tab.active_pane.current_working_dir
  if cwd_uri then
    local cwd = cwd_uri.file_path or ''
    title = cwd:match('([^/]+)/?$') or title
  end
  return {
    { Background = { Color = colors.bg } },
    { Foreground = { Color = colors.fg } },
    { Text = '  ' .. title .. '  ' },
  }
end)

-- 🎨 Тема
--config.color_scheme = 'Catppuccin Latte'
config.color_scheme = 'Catppuccin Macchiato'

-- 🖥️ Рамка: padding + темний фон (видно тільки у padding зонах, не ламає тему)
config.window_padding = { left = 10, right = 10, top = 10, bottom = 10 }
config.background = {
  { source = { Color = '#181926' }, width = '100%', height = '100%' },  -- Catppuccin crust
}


-- 🔤 Шрифт
config.font = wezterm.font('JetBrains Mono', { weight = 'Medium' })
config.font_size = 14.0

-- Більший шрифт у таб-барі
config.window_frame = {
  font = wezterm.font('JetBrains Mono', { weight = 'Bold' }),
  font_size = 18.0,
  active_titlebar_bg = TAB_BAR_BG,
}

-- Напівпрозорість та розмиття фону
--config.window_background_opacity = 0.75
--config.macos_window_background_blur = 20

-- 📂 Плавний скрол
config.scrollback_lines = 5000

-- Директорія за замовчуванням
config.default_cwd = "/Users/absolutusdeo/PhpstormProjects"

-- Dimming неактивних панелей
config.inactive_pane_hsb = {
  saturation = 0.5,
  brightness = 0.6,
}

-- Курсор
config.default_cursor_style = 'SteadyBlock'

-- ⌨️ Клавіатурні скорочення
config.keys = {
  -- CMD + D → вертикальний split
  {
    key = "d",
    mods = "CMD",
    action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" })
  },
  -- CMD + Shift + D → горизонтальний split
  {
    key = "d",
    mods = "CMD|SHIFT",
    action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" })
  },
  -- CMD + [ / ] → перемикання між панелями
  {
    key = '[',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection('Prev'),
  },
  {
    key = ']',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection('Next'),
  },
  -- CMD + 1..9 → перемикання між вкладками
  { key = '1', mods = 'CMD', action = wezterm.action.ActivateTab(0) },
  { key = '2', mods = 'CMD', action = wezterm.action.ActivateTab(1) },
  { key = '3', mods = 'CMD', action = wezterm.action.ActivateTab(2) },
  { key = '4', mods = 'CMD', action = wezterm.action.ActivateTab(3) },
  { key = '5', mods = 'CMD', action = wezterm.action.ActivateTab(4) },
  { key = '6', mods = 'CMD', action = wezterm.action.ActivateTab(5) },
  { key = '7', mods = 'CMD', action = wezterm.action.ActivateTab(6) },
  { key = '8', mods = 'CMD', action = wezterm.action.ActivateTab(7) },
  { key = '9', mods = 'CMD', action = wezterm.action.ActivateTab(8) },
  -- Ctrl + V → whisper
  {
    key = 'v',
    mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
      wezterm.background_child_process {
        os.getenv('HOME') .. '/whisper_wezterm.sh',
        tostring(pane:pane_id()),
      }
    end),
  },
}

return config
