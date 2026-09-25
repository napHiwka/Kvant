--!native
--!optimize 2

-- KvantUI - v0.9.4
-- github.com/napHiwka/Kvant - MIT License
-- You'll probably want to turn world wrap on or format code, good luck
-- API breakege can still happen - use right version; sob
--　　／l、
--　（ﾟ､ ｡ ７
--　⠀l、~ ヽﾉｼ
--　⠀じじと ）

--TODO:
--api?: change Input api
--api: test all properties on every element visually :(
--feat?: Custom elements (that's probably nightmare to implement).
--docs: deploy docs.

-----------------------------------------------------------
-- Services, assets & helpers
-----------------------------------------------------------
local cloneref = cloneref or function(f) return f end
local TweenService: TweenService = cloneref(game:GetService("TweenService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local TextService: TextService = cloneref(game:GetService("TextService"))

local debug = debug or {} -- stub; if no debug.traceback in environment
if not debug.traceback then
	function debug.traceback(message)
		return message ~= nil and tostring(message) or ""
	end
end

local supported = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
local GameId = tostring(cloneref(game).GameId)

local ASSET = { -- icons yoinked at github.com/Footagesus/Icons
	Kvant = "rbxassetid://73167696981648", Tab = "rbxassetid://97419752870313",
	Button = "rbxassetid://107150227368485", Toggle = "rbxassetid://90411952142550",
	Slider = "rbxassetid://135684703553372", Keybind = "rbxassetid://121474456068237",
	Text = "rbxassetid://133543553793564", Settings = "rbxassetid://80758916183665",
	Dropdown = "rbxassetid://134243273101015", Color = "rbxassetid://86350350950064",
	Input = "rbxassetid://107551944047171", Search = "rbxassetid://121018724060431",
	Minimize = "rbxassetid://118026365011536", Close = "rbxassetid://110786993356448",
	Success = "rbxassetid://85262178816537", Error = "rbxassetid://76821953846248",
	Warning = "rbxassetid://125920361880643", Info = "rbxassetid://124560466474914",
}

local TEXT_ICONS = {
	Small_Down = "chevron-small-down", Small_Up = "chevron-small-up",
	Large_Down = "chevron-large-down", Large_Right = "chevron-large-right",
	Small_Right = "chevron-small-right", Small_Left = "chevron-small-left",
	Kvant = "cube", Tab = "folder-tabs",
	Button = "cursor", Toggle = "toggle-right",
	Slider = "three-sliders-horizontal", Keybind = "keyboard",
	Text = "text-uppercase-a-lowercase-a", Settings = "gear",
	Dropdown = "chevron-small-down", Color = "paint-brush",
	Input = "pencil", Search = "magnifying-glass",
	Minimize = "windows-app-minimize", Close = "windows-app-close",
	Success = "check", Error = "circle-x",
	Warning = "triangle-exclamation", Info = "circle-i",
}

local FONT_ASSETS = {
	Roboto = "rbxasset://fonts/families/Roboto.json", Ubuntu = "rbxasset://fonts/families/Ubuntu.json",
	Inter = "rbxassetid://12187365364", Icon = "rbxasset://luapackages/packages/_index/buildericons/buildericons/buildericons.json",
}

local PERSIST = { -- persistance paths
	Root = "Kvant",
	Games = "Kvant/games",
	Kvant = "Kvant/settings.json",
	Game = function(id) return "Kvant/games/" .. tostring(id) .. ".json" end,
}

local MOTION = { Fast = 0.08, Normal = 0.14, Panel = 0.18 }
local SEARCH_POOL, SAVE_DEBOUNCE, NOTIFY_DEFAULT_DURATION, TOOLTIP_DELAY = 6, 0.5, 3, 0.12
local PILL_MIN_W, PILL_MAX_W, TOOLTIP_OFFSET, SEARCH_BAR_H = 110, 280, 24, 46
local WIN_SIZE_SIDE, WIN_SIZE_TOP = UDim2.new(0.42, 0, 0.62, 0), UDim2.new(0.3, 0, 0.6, 0)
local WIN_MIN_SIDE, WIN_MIN_TOP = Vector2.new(460, 400), Vector2.new(320, 400)
local WIN_MAX_SIDE, WIN_MAX_TOP = Vector2.new(620, 560), Vector2.new(420, 520)

local DECLARATIVE_METHODS = { "Tab", "Section", "Divider", "Text", "Button", "Toggle", "Slider", "Dropdown", "Keybind", "Input", "Color", "Textarea" }
local REQUIRED_THEME_KEYS = { "Background", "Secondary", "Accent", "Stroke", "Text", "SubText" }

local DEFAULT_THEMES = {
	Dark = {
		Background = Color3.fromRGB(24, 24, 27),    Secondary  = Color3.fromRGB(34, 34, 39),
		Accent     = Color3.fromRGB(34, 197, 94),   Stroke     = Color3.fromRGB(50, 50, 58),
		Text       = Color3.fromRGB(245, 245, 247), SubText    = Color3.fromRGB(160, 160, 170),
		AccentText = Color3.fromRGB(255, 255, 255),
	},
	Darker = {
		Background = Color3.fromRGB(9, 9, 11),      Secondary  = Color3.fromRGB(18, 18, 22),
		Accent     = Color3.fromRGB(34, 197, 94),   Stroke     = Color3.fromRGB(32, 32, 38),
		Text       = Color3.fromRGB(240, 240, 243), SubText    = Color3.fromRGB(140, 140, 150),
		AccentText = Color3.fromRGB(255, 255, 255),
	},
	Vesper = {
		Background = Color3.fromRGB(16, 16, 16),    Secondary  = Color3.fromRGB(24, 24, 24),
		Accent     = Color3.fromRGB(255, 199, 153), Stroke     = Color3.fromRGB(40, 40, 40),
		Text       = Color3.fromRGB(255, 255, 255), SubText    = Color3.fromRGB(160, 160, 160),
		AccentText = Color3.fromRGB(0, 0, 0),
	},
	Light = {
		Background = Color3.fromRGB(246, 246, 246), Secondary  = Color3.fromRGB(255, 255, 255),
		Accent     = Color3.fromRGB(25, 118, 210),  Stroke     = Color3.fromRGB(225, 225, 228),
		Text       = Color3.fromRGB(33, 33, 33),    SubText    = Color3.fromRGB(117, 117, 117),
		AccentText = Color3.fromRGB(255, 255, 255),
	},
	SolarizedLight = {
		Background = Color3.fromRGB(253, 246, 227), Secondary  = Color3.fromRGB(238, 232, 213),
		Accent     = Color3.fromRGB(172, 157, 87),  Stroke     = Color3.fromRGB(221, 214, 193),
		Text       = Color3.fromRGB(101, 123, 131), SubText    = Color3.fromRGB(147, 161, 161),
		AccentText = Color3.fromRGB(253, 246, 227),
	},
}

local ICON_GUESS = {
	Kvant = { "main", "home", "general", "overview", "hub", "game", "player", "character", "farm", "autofarm" },
	Settings = { "settings", "config", "configuration", "options", "preferences", "setup" },
	Search = { "search", "find", "scanner", "filter", "explorer" },
	Color = { "color", "colors", "colour", "colours", "theme", "themes", "style", "visuals", "visual", "esp", "chams", "cham", "render" },
	Text = { "text", "about", "credits", "notes", "log", "logs", "changelog", "status", "stats" },
	Keybind = { "keybind", "keybinds", "binds", "hotkeys", "controls", "keys", "shortcuts" },
	Toggle = { "toggle", "toggles", "features", "modules", "combat", "aimbot", "silent", "pvp" },
	Slider = { "slider", "sliders", "tuning", "tweaks", "speed", "walkspeed", "movement", "teleports", "teleport", "tp" },
	Dropdown = { "dropdown", "list", "lists", "select", "selection", "modes", "mode", "target", "targets" },
	Input = { "input", "inputs", "fields", "command", "commands", "chat", "textbox" },
	Button = { "button", "buttons", "actions", "misc", "extra", "extras", "utilities", "utils", "tools", "spawn" },
	Success = { "success", "ok", "done", "check", "complete" },
	Error = { "error", "fail", "failed", "danger", "critical" },
	Warning = { "warning", "warn", "caution", "alert" },
	Info = { "info", "information", "notice", "help" },
}

local function buildIconMap(source)
	local map = {}
	for k, v in source do map[string.lower(k)] = v end
	for target, aliases in ICON_GUESS do
		local asset = source[target]
		if asset then
			for _, alias in aliases do map[string.lower(alias)] = asset end
		end
	end
	return map
end

local function resolveFrom(id, defaultKind, map, source, numeric)
	if id == false or id == "none" or id == "nil" then return "" end
	if not id or id == "" then return defaultKind and source[defaultKind] or "" end
	if numeric then
		if type(id) == "number" then return "rbxassetid://" .. tostring(id) end
		if type(id) ~= "string" then return "" end
	end
	local lower = string.lower(tostring(id))
	local mapped = map[lower]
	if mapped then return mapped end
	for word in string.gmatch(lower, "%a+") do
		if map[word] then return map[word] end
	end
	if numeric then
		if tonumber(id) and not string.find(id, "://", 1, true) then return "rbxassetid://" .. id end
		return id
	end
	return source[id] or (defaultKind and source[defaultKind]) or ""
end

local ICON_MAP = buildIconMap(ASSET)
local TEXT_ICON_MAP = buildIconMap(TEXT_ICONS)

local function resolveIcon(id, defaultKind) return resolveFrom(id, defaultKind, ICON_MAP, ASSET, true) end
local function resolveTextIcon(id, defaultKind) return resolveFrom(id, defaultKind, TEXT_ICON_MAP, TEXT_ICONS, false) end

local function isLight(c) return (0.299 * c.R + 0.587 * c.G + 0.114 * c.B) > 0.5 end
local function validateTheme(t)
	if type(t) ~= "table" then warn("[Kvant] Theme must be a table"); return false end
	local missing = {}
	for _, k in REQUIRED_THEME_KEYS do if typeof(t[k]) ~= "Color3" then table.insert(missing, k) end end
	if #missing > 0 then warn("[Kvant] Missing Color3 fields in theme: " .. table.concat(missing, ", ")); return false end
	return true
end

local function sanitizeTheme(t)
	local th, light = table.clone(t), isLight(t.Background)
	th.Icon = (not th.Icon or isLight(th.Icon) == light) and (light and Color3.fromRGB(33, 33, 33) or Color3.fromRGB(245, 245, 247)) or th.Icon
	th.IconMuted = (not th.IconMuted or isLight(th.IconMuted) == light) and (light and Color3.fromRGB(130, 130, 130) or Color3.fromRGB(160, 160, 170)) or th.IconMuted
	th.AccentText = th.AccentText or (isLight(th.Accent) and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(255, 255, 255))
	return th
end

local Library = {
	_theme = nil,
	_themes = DEFAULT_THEMES,
	Icons = ICON_MAP,
	_windows = setmetatable({}, { __mode = "v" })
}
Library._theme = sanitizeTheme(DEFAULT_THEMES.Darker)

function Library:GetTheme() return Library._theme end
function Library:GetThemeNames()
	local names = {}
	for k in Library._themes do table.insert(names, k) end
	return names
end
function Library:GetThemePreset(name) return Library._themes[name] end

function Library:SetTheme(theme)
	local t = typeof(theme) == "table" and theme or Library._themes[theme]
	if not t or not validateTheme(t) then return end
	Library._theme = sanitizeTheme(t)
	for _, w in Library._windows do if w then w.applyTheme() end end
end

Library.Config = {
	Text = { Title = 18, Label = 17, Body = 16, Small = 15 },
	Fonts = {
		Bold = Font.new(FONT_ASSETS.Roboto, Enum.FontWeight.Bold),
		Medium = Font.new(FONT_ASSETS.Roboto, Enum.FontWeight.Medium),
		Regular = Font.new(FONT_ASSETS.Roboto, Enum.FontWeight.Regular),
		Icons = Font.new(FONT_ASSETS.Icon)
	},
	Motion = {
		Fast = TweenInfo.new(MOTION.Fast, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Normal = TweenInfo.new(MOTION.Normal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Panel = TweenInfo.new(MOTION.Panel, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	},
}

function Library:SetFont(font)
	local id = FONT_ASSETS[font] or (typeof(font) == "Font" and font.Family) or tostring(font)
	if not id:find("://") and tonumber(id) then id = "rbxassetid://" .. id end
	local F = Library.Config.Fonts
	F.Bold, F.Medium, F.Regular = Font.new(id, Enum.FontWeight.Bold), Font.new(id, Enum.FontWeight.Medium), Font.new(id, Enum.FontWeight.Regular)
	for _, w in Library._windows do if w then w.applyFont() end end
end

-- Signal Engine
local function Signal()
	local listeners = {}
	return {
		Connect = function(_, fn)
			local key = { _fn = fn }
			listeners[key] = true
			return { Disconnect = function() listeners[key] = nil end }
		end,
		Fire = function(_, ...)
			for key in listeners do task.spawn(key._fn, ...) end
		end,
	}
end

-- Scope Dispatch
local contextStack = {}
local function currentScope() return contextStack[#contextStack] end

local function withScope(scope, fn)
	table.insert(contextStack, scope)
	local ok, err = pcall(fn, scope)
	table.remove(contextStack)
	if not ok then error(err, 2) end
end

local function registerDeclaratives(target)
	if type(target) ~= "table" then return end
	for _, name in DECLARATIVE_METHODS do
		target[name] = function(...)
			local scope = currentScope()
			if not scope or not scope[name] then error(string.format("[Kvant] '%s' must be called within an active scope", name), 2) end
			return scope[name](scope, ...)
		end
	end
end
registerDeclaratives(Library)
pcall(function() if type(getfenv) == "function" then registerDeclaratives(getfenv(0)) end end)

local function encodeConfig(d) local ok, r = pcall(HttpService.JSONEncode, HttpService, d); return ok and r or nil end
local function decodeConfig(r) local ok, res = pcall(HttpService.JSONDecode, HttpService, r); return ok and type(res) == "table" and res or nil end
local function ensureFolders()
	if not supported then return end
	if not isfolder(PERSIST.Root) then makefolder(PERSIST.Root) end
	if not isfolder(PERSIST.Games) then makefolder(PERSIST.Games) end
end

local function decimalsOf(n)
	local d = tostring(n):match("%.(%d+)")
	return d and #d or 0
end

local function isTextLong(str, textSize, maxWidth)
	if not str or str == "" then return false end
	return TextService:GetTextSize(str, textSize, Enum.Font.Roboto, Vector2.new(1e5, 1e5)).X > maxWidth
end

  local function valuesEqual(a, b)
  	if a == b then return true end
  	if type(a) ~= "table" or type(b) ~= "table" then return false end
  	local n = 0
  	for k, v in a do if b[k] ~= v then return false end; n += 1 end
  	for _ in b do n -= 1 end
  	return n == 0
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = p
	return p
end

local function pad(p, x, y)
	local pi = Instance.new("UIPadding")
	pi.PaddingLeft, pi.PaddingRight = UDim.new(0, x), UDim.new(0, x)
	pi.PaddingTop, pi.PaddingBottom = UDim.new(0, y or x), UDim.new(0, y or x)
	pi.Parent = p
	return p
end

-----------------------------------------------------------
-- Reactive property system (handle engine)
-----------------------------------------------------------
local function newHandleClass(name, props, methods)
	local getters, setters = {}, {}
	for k, v in props do getters[k], setters[k] = v.get, v.set end
	local mt = {
		__index = function(self, k)
			local g = getters[k]
			if g then return g(self._) end
			local m = methods and methods[k]
			if m then return m end
			error(name .. " has no member '" .. tostring(k) .. "'", 2)
		end,
		__newindex = function(self, k, v)
			local s = setters[k]
			if s then s(self._, v); return end
			error(name .. (getters[k] and " is read-only: '" or " has no property: '") .. tostring(k) .. "'", 2)
		end,
	}
	return function(state) return setmetatable({ _ = state }, mt) end
end

local function safeCall(s, cb, ...)
	local ok, err = xpcall(cb, debug.traceback, ...)
	if not ok then
		warn(string.format("[Kvant] Error in '%s' callback:\n%s", tostring(s.labelLbl and s.labelLbl.Text or "Element"), tostring(err)))
	end
end

-- sync - when true, the callback runs immediately on the calling thread
local function fireEvent(s, eventName, sync, ...)
	local cb = s.callback
	if cb and s.primaryEvent == eventName then
		if sync then safeCall(s, cb, ...) else task.spawn(safeCall, s, cb, ...) end
	end
	local sig = s[eventName]
	if sig then sig:Fire(...) end
end

local function makeEventProp(eventName)
	return {
		get = function(s)
			local sig = s[eventName]
			if not sig then sig = Signal(); s[eventName] = sig end
			return sig
		end
	}
end

local CHANGED_PROP = makeEventProp("Changed")
local PRESSED_PROP = makeEventProp("Pressed")
local ACTIVATED_PROP = makeEventProp("Activated")

local BASE_PROPS = {
	Label = {
		get = function(s) return s.labelLbl.Text end,
		set = function(s, v)
			local val = tostring(v or "")
			if s.labelLbl.Text ~= val then s.labelLbl.Text = val end
		end
	},
	Icon = {
		get = function(s) return s.iconImg.Image ~= "" and s.iconImg.Image or nil end,
		set = function(s, v)
			s.win.SetIcon(s.iconImg, v)
		end
	},
	Tooltip = {
		get = function(s) local d = s.desc; return d and d.text or nil end,
		set = function(s, v) local d = s.desc; if d and d.text ~= v then d.set(v) end end
	},
	Locked = {
		get = function(s) return s.isLocked() end,
		set = function(s, v) local b = v and true or false; if s.isLocked() ~= b then s.setLocked(b) end end
	},
	Instance = { get = function(s) return s.root end }
}

local function withBase(customProps)
	local full = table.clone(BASE_PROPS)
	for k, v in customProps do full[k] = v end
	return full
end

local TextHandle = newHandleClass("Text", {
	Value = {
		get = function(s) return s.contentLbl.Text end,
		set = function(s, v)
			local val = tostring(v or "")
			if s.contentLbl.Text ~= val then s.contentLbl.Text = val end
		end
	},
	Title = {
		get = function(s) return s.head.Visible and s.titleLbl.Text or nil end,
		set = function(s, v)
			local val = v and tostring(v) or ""
			if s.titleLbl.Text ~= val then s.titleLbl.Text = val; s.head.Visible = val ~= "" end
		end,
	},
	Icon = BASE_PROPS.Icon, Tooltip = BASE_PROPS.Tooltip, Instance = BASE_PROPS.Instance,
})

local ButtonHandle = newHandleClass("Button", withBase({ Activated = ACTIVATED_PROP }), {
	Fire = function(self) fireEvent(self._, "Activated", false, false) end
})

local function applyToggle(s, newState, fromUser)
	local st = newState and true or false
	if s.state == st and fromUser == nil then return end
	s.state = st
	s.win.Tween(s.circ, Library.Config.Motion.Normal, { Position = st and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) })
	s.win.Tween(s.sw, Library.Config.Motion.Normal, { BackgroundColor3 = st and Library._theme.Accent or Library._theme.Stroke })
	fireEvent(s, "Changed", false, st, fromUser and true or false)
	if fromUser then s.win.RequestSave(s.registry, s.key) end
end

local ToggleHandle = newHandleClass("Toggle", withBase({
	Value = {
		get = function(s) return s.state end,
		set = function(s, v) local st = v and true or false; if s.state ~= st then applyToggle(s, st, false) end end
	},
	Changed = CHANGED_PROP,
}))

local function sliderRound(c, v)
	local stepped = math.round((v - c.min) / c.step) * c.step + c.min
	return math.round(stepped * c.mult) / c.mult
end

local function sliderFmt(c, v)
	local base = c.decimals > 0 and string.format("%." .. c.decimals .. "f", v) or tostring(v)
	return (c.suffix ~= "") and (base .. " " .. c.suffix) or base
end

local function sliderValueAt(s, x)
	local c = s.cfg
	return c.min + (c.max - c.min) * math.clamp((x - s.bar.AbsolutePosition.X) / s.bar.AbsoluteSize.X, 0, 1)
end

local function sliderSetVisual(s, val, p, animate)
	local targetSize = UDim2.new(p, 0, 1, 0)
	if animate and not s.win.reduceMotion then
		s.win.Tween(s.fill, Library.Config.Motion.Fast, { Size = targetSize })
	else
		s.fill.Size = targetSize
	end
	s.valLbl.Text = sliderFmt(s.cfg, val)
end

local function sliderApply(s, v, dragging, skipSave)
	local c = s.cfg
	if c.max < c.min then c.max = c.min end
	v = sliderRound(c, math.clamp(v, c.min, c.max))
	local prev, prevDrag = c.current, c.dragging
	c.current, c.dragging = v, dragging and true or false
	if v == prev and c.dragging == prevDrag then return end
	local denom = c.max - c.min
	sliderSetVisual(s, v, denom == 0 and 0 or (v - c.min) / denom, not dragging and not s.win.reduceMotion)
	if v ~= prev then
		fireEvent(s, "Changed", c.dragging, v, c.dragging)
		if not skipSave then s.win.RequestSave(s.registry, s.key) end
	end
end

local function sliderReclamp(s) sliderApply(s, s.cfg.current, false, false) end

local SliderHandle = newHandleClass("Slider", withBase({
	Value = {
		get = function(s) return s.cfg.current end,
		set = function(s, v) if v ~= s.cfg.current then sliderApply(s, v, false, false) end end
	},
	Min = {
		get = function(s) return s.cfg.min end,
		set = function(s, v) if s.cfg.min ~= v then s.cfg.min = v; sliderReclamp(s) end end
	},
	Max = {
		get = function(s) return s.cfg.max end,
		set = function(s, v) if s.cfg.max ~= v then s.cfg.max = v; sliderReclamp(s) end end
	},
	Step = {
		get = function(s) return s.cfg.step end,
		set = function(s, v)
			if s.cfg.step ~= v then
				s.cfg.step = v; s.cfg.decimals = decimalsOf(v); s.cfg.mult = 10 ^ s.cfg.decimals; sliderReclamp(s)
			end
		end,
	},
	Dragging = { get = function(s) return s.cfg.dragging end },
	Suffix = {
		get = function(s) return s.cfg.suffix or "" end,
		set = function(s, v)
			local suf = v and tostring(v) or ""
			if s.cfg.suffix ~= suf then s.cfg.suffix = suf; s.valLbl.Text = sliderFmt(s.cfg, s.cfg.current) end
		end,
	},
	Changed = CHANGED_PROP,
}))

local function dropdownSelectedList(s)
	local list = {}
	for _, v in s.options do if s.selected[v] then table.insert(list, v) end end
	return list
end

local function dropdownGetValue(s) return s.multi and dropdownSelectedList(s) or s.default end

local function dropdownDisplayText(s)
	if not s.multi then return tostring(s.default or "Select...") end
	local list = dropdownSelectedList(s)
	return #list == 0 and "Select..." or table.concat(list, ", ")
end

local function dropdownUpdateAlign(s)
	local isLong = isTextLong(dropdownDisplayText(s), Library.Config.Text.Body, 122)
	s.selLabel.TextXAlignment = isLong and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
	s.selLabel.TextTruncate = isLong and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
end

local function dropdownRefreshColors(s)
	s.selLabel.Text = dropdownDisplayText(s)
	dropdownUpdateAlign(s)
	for i, data in s.optData do
		local v = s.options[i]
		local isSel = s.multi and s.selected[v] or (v == s.default)
		data.btn.BackgroundColor3 = isSel and Library._theme.Accent or Library._theme.Background
		data.btn.TextColor3 = isSel and Library._theme.AccentText or Library._theme.SubText
	end
end

local function dropdownOpenHeight(s)
	local count = 0
	for _, data in s.optData do if data.btn.Visible then count += 1 end end
	return count * 38 + 58 + (s.searchable and 38 or 0)
end

local function dropdownSetOpened(s, open)
	if s.openState == open then return end
	s.openState = open
	s.setChevron(open)
	s.win.Tween(s.root, Library.Config.Motion.Normal, { Size = UDim2.new(1, 0, 0, open and dropdownOpenHeight(s) or 50) })
end

local function dropdownApplyFilter(s)
	local q = s.filterText or ""
	for i, data in s.optData do
		local opt = s.options[i]
		data.btn.Visible = (q == "" or string.find(string.lower(tostring(opt)), q, 1, true) ~= nil)
	end
	if s.openState then
		s.win.Tween(s.root, Library.Config.Motion.Fast, { Size = UDim2.new(1, 0, 0, dropdownOpenHeight(s)) })
	end
end

local function dropdownSetSearchable(s, state)
	state = state and true or false
	if state == (s.searchable or false) then return end
	s.searchable = state
	if s.filterWrap then s.filterWrap.Visible = state end
	if not state and s.filterBox then
		s.filterBox.Text = ""; s.filterText = ""; dropdownApplyFilter(s)
	end
	if s.openState then
		s.win.Tween(s.root, Library.Config.Motion.Normal, { Size = UDim2.new(1, 0, 0, dropdownOpenHeight(s)) })
	end
end

local function dropdownBuildOptions(s)
	local optData, options = s.optData, s.options
	for i = 1, #options do
		local v, data = options[i], optData[i]
		if not data then
			local opt = s.optTemplate:Clone()
			opt.LayoutOrder = i
			opt.Parent = s.listHolder
			data = { btn = opt, value = v }; optData[i] = data

			s.win.OnHover(opt, function()
				local isSel = s.multi and s.selected[data.value] or (data.value == s.default)
				if not isSel then
					s.win.Tween(opt, Library.Config.Motion.Fast, { BackgroundColor3 = Library._theme.Stroke, TextColor3 = Library._theme.Text })
				end
			end, function()
				local isSel = s.multi and s.selected[data.value] or (data.value == s.default)
				if not isSel then
					s.win.Tween(opt, Library.Config.Motion.Fast, { BackgroundColor3 = Library._theme.Background, TextColor3 = Library._theme.SubText })
				end
			end)

			opt.Activated:Connect(function()
				if s.multi then s.selected[data.value] = not s.selected[data.value] or nil
				else s.default = data.value; dropdownSetOpened(s, false) end
				dropdownRefreshColors(s); fireEvent(s, "Changed", false, dropdownGetValue(s), true); s.win.RequestSave(s.registry, s.key)
			end)
		else data.value = v end
		data.btn.Text = tostring(v)
	end
	for i = #options + 1, #optData do optData[i].btn:Destroy(); optData[i] = nil end
	dropdownRefreshColors(s)
end

local function dropdownSetValue(s, v, fromUser)
	if valuesEqual(dropdownGetValue(s), v) and fromUser == nil then return end
	if s.multi and type(v) == "table" then
		table.clear(s.selected)
		for _, item in v do if table.find(s.options, item) then s.selected[item] = true end end
	elseif table.find(s.options, v) then s.default = v end
	dropdownRefreshColors(s)
	fireEvent(s, "Changed", false, dropdownGetValue(s), fromUser and true or false)
	if fromUser then s.win.RequestSave(s.registry, s.key) end
end

local function dropdownSetMulti(s, multi)
	multi = multi and true or false
	if s.multi == multi then return end
	s.multi = multi
	if not multi then
		local firstSel
		for _, opt in s.options do
			if s.selected[opt] then firstSel = opt; break end
		end
		s.default = firstSel or s.options[1]
		table.clear(s.selected)
	else
		table.clear(s.selected)
		if s.default then s.selected[s.default] = true end
	end
	dropdownRefreshColors(s)
	fireEvent(s, "Changed", false, dropdownGetValue(s), false)
	s.win.RequestSave(s.registry, s.key)
end

local function dropdownSetOptions(s, newOpts)
	if valuesEqual(s.options, newOpts) then return end
	s.options = newOpts or {}; dropdownBuildOptions(s); dropdownRefreshColors(s)
	s.filterText = ""
	if s.filterBox then s.filterBox.Text = "" end
	dropdownApplyFilter(s)
	if s.openState then s.win.Tween(s.root, Library.Config.Motion.Normal, { Size = UDim2.new(1, 0, 0, dropdownOpenHeight(s)) }) end
end

local DropdownHandle = newHandleClass("Dropdown", withBase({
	Value = {
		get = function(s) return dropdownGetValue(s) end,
		set = function(s, v) dropdownSetValue(s, v, false) end
	},
	Options = {
		get = function(s) return s.options end,
		set = function(s, v) dropdownSetOptions(s, v) end
	},
	Open = {
		get = function(s) return s.openState end,
		set = function(s, v) dropdownSetOpened(s, v and true or false) end
	},
	Multi = {
		get = function(s) return s.multi end,
		set = function(s, v) dropdownSetMulti(s, v) end
	},
	Searchable = {
		get = function(s) return s.searchable or false end,
		set = function(s, v) dropdownSetSearchable(s, v and true or false) end
	},
	Changed = CHANGED_PROP,
}))

local function keybindSetKey(s, newKey, fromUser)
	local val
	if typeof(newKey) == "EnumItem" and newKey.EnumType == Enum.KeyCode then val = newKey
	elseif type(newKey) == "string" then val = (newKey ~= "None" and pcall(function() return Enum.KeyCode[newKey] end) and Enum.KeyCode[newKey]) or nil
	else val = nil end
	if s.value == val and fromUser == nil then return end
	s.value = val
	s.bindBtn.Text = s.value and s.value.Name or "None"
	fireEvent(s, "Changed", false, s.value, fromUser and true or false)
	if fromUser then s.win.RequestSave(s.registry, s.key) end
end

local KeybindHandle = newHandleClass("Keybind", withBase({
	Value = {
		get = function(s) return s.value end,
		set = function(s, v) keybindSetKey(s, v, false) end
	},
	Listening = { get = function(s) return s.listening end },
	Pressed = PRESSED_PROP, Changed = CHANGED_PROP,
}))

local function inputUpdateAlign(s)
	local str = s.box.Text ~= "" and s.box.Text or s.box.PlaceholderText
	s.box.TextXAlignment = isTextLong(str, Library.Config.Text.Body, 140) and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
end

local function inputSetValue(s, v, fromUser)
	local str = tostring(v or "")
	if s.digitsOnly then str = str:gsub("%D", "") end
	if s.maxLength > 0 and #str > s.maxLength then str = string.sub(str, 1, s.maxLength) end
	if s.box.Text == str and fromUser == nil then return end
	s.box.Text = str
	inputUpdateAlign(s)
	fireEvent(s, "Changed", false, str, fromUser and true or false)
	if fromUser then s.win.RequestSave(s.registry, s.key) end
end

local InputHandle = newHandleClass("Input", withBase({
	Value = {
		get = function(s) return s.box.Text end,
		set = function(s, v) inputSetValue(s, v, false) end
	},
	Placeholder = {
		get = function(s) return s.box.PlaceholderText end,
		set = function(s, v)
			local p = v or ""
			if s.box.PlaceholderText ~= p then s.box.PlaceholderText = p; inputUpdateAlign(s) end
		end
	},
	MaxLength = {
		get = function(s) return s.maxLength end,
		set = function(s, v)
			s.maxLength = v or 0
			if s.maxLength > 0 and #s.box.Text > s.maxLength then inputSetValue(s, s.box.Text, false) end
		end,
	},
	DigitsOnly = {
		get = function(s) return s.digitsOnly or false end,
		set = function(s, v)
			local num = v and true or false
			if s.digitsOnly ~= num then
				s.digitsOnly = num
				if s.digitsOnly then
					local stripped = s.box.Text:gsub("%D", "")
					if stripped ~= s.box.Text then s.box.Text = stripped end
				end
			end
		end,
	},
	Changed = CHANGED_PROP,
}))

local function colorUpdateVisuals(s, skipInputs)
	local c = s.hsv
	s.col = Color3.fromHSV(c.h, c.s, c.v)
	s.map.BackgroundColor3 = Color3.fromHSV(c.h, 1, 1)
	s.satCursor.Position = UDim2.new(c.s, 0, 1 - c.v, 0)
	s.hueCursor.Position = UDim2.new(c.h, 0, 0.5, 0)
	s.swatch.BackgroundColor3 = s.col
	if not skipInputs then
		s.hexBox.Text = "#" .. s.col:ToHex():upper()
		for name, b in s.chanBoxes do b.Text = tostring(math.floor(s.col[name] * 255 + 0.5)) end
	end
end

local function colorCommit(s, fromUser)
	if s.lastCommitted == s.col and fromUser == nil then return end
	s.lastCommitted = s.col
	fireEvent(s, "Changed", false, s.col, fromUser and true or false)
	if fromUser then s.win.RequestSave(s.registry, s.key) end
end

-- Color3/{R,G,B}/hex-string normalizer
local function normalizeColor(val)
	if typeof(val) == "Color3" then return val end
	if type(val) == "table" and val.R then return Color3.fromRGB(val.R, val.G or 0, val.B or 0) end
	if type(val) == "string" then
		local ok, col = pcall(Color3.fromHex, val)
		if ok then return col end
	end
	return nil
end

local function colorSetFromValue(s, val, fromUser)
	local res = normalizeColor(val)
	if res and res ~= s.col then
		s.hsv.h, s.hsv.s, s.hsv.v = res:ToHSV()
		colorUpdateVisuals(s, false)
		colorCommit(s, fromUser)
	end
end

local ColorHandle = newHandleClass("Color", withBase({
	Value = {
		get = function(s) return s.col end,
		set = function(s, v) colorSetFromValue(s, v, false) end
	},
	Hex = {
		get = function(s) return "#" .. s.col:ToHex():upper() end,
		set = function(s, hex) colorSetFromValue(s, hex, false) end
	},
	Changed = CHANGED_PROP,
}))

local function textareaSetValue(s, v, fromUser)
	local text = tostring(v or "")
	if s.maxLength > 0 and #text > s.maxLength then text = string.sub(text, 1, s.maxLength) end
	if s.box.Text == text and fromUser == nil then return end
	s.box.Text = text
	fireEvent(s, "Changed", false, text, fromUser and true or false)
	if fromUser then s.win.RequestSave(s.registry, s.key) end
end

local TextareaHandle = newHandleClass("Textarea", withBase({
	Value = {
		get = function(s) return s.box.Text end,
		set = function(s, v) textareaSetValue(s, v, false) end
	},
	Placeholder = {
		get = function(s) return s.box.PlaceholderText end,
		set = function(s, v)
			local p = v or ""
			if s.box.PlaceholderText ~= p then s.box.PlaceholderText = p end
		end
	},
	MaxLength = {
		get = function(s) return s.maxLength end,
		set = function(s, v)
			s.maxLength = v or 0
			if s.maxLength > 0 and #s.box.Text > s.maxLength then textareaSetValue(s, s.box.Text, false) end
		end,
	},
	Changed = CHANGED_PROP,
}))

-- Config get/set dispatch, keyed by control kind
local ConfigOps = {
	Toggle = {
		get = function(s) return s.state end,
		set = function(s, v) if type(v) == "boolean" then applyToggle(s, v, false) end end,
	},
	Slider = {
		get = function(s) return s.cfg.current end,
		set = function(s, v) if type(v) == "number" then sliderApply(s, v, false, false) end end,
	},
	Dropdown = {
		get = dropdownGetValue,
		set = function(s, v) dropdownSetValue(s, v, false) end,
	},
	Keybind = {
		get = function(s) return s.value and s.value.Name or "None" end,
		set = function(s, v) keybindSetKey(s, v, false) end,
	},
	Input = {
		get = function(s) return s.box.Text end,
		set = function(s, v) if type(v) == "string" then inputSetValue(s, v, false) end end,
	},
	Color = {
		get = function(s) return { R = math.floor(s.col.R * 255 + 0.5), G = math.floor(s.col.G * 255 + 0.5), B = math.floor(s.col.B * 255 + 0.5) } end,
		set = function(s, v) colorSetFromValue(s, v, false) end,
	},
	Textarea = {
		get = function(s) return s.box.Text end,
		set = function(s, v) if type(v) == "string" then textareaSetValue(s, v, false) end end,
	},
	Pos = {
		get = function(f) return { f.Position.X.Scale, f.Position.X.Offset, f.Position.Y.Scale, f.Position.Y.Offset } end,
		set = function(f, v) if type(v) == "table" and #v == 4 then f.Position = UDim2.new(v[1], v[2], v[3], v[4]) end end,
	},
}

-----------------------------------------------------------
-- Container prototype
-----------------------------------------------------------
local ContainerMethods = {}
local ContainerMT = { __index = ContainerMethods }

local function createContainer(targetParent, registry, tabName, tabIdx, win)
	return setmetatable({
		targetParent = targetParent,
		registry = registry,
		tabName = tabName,
		tabIdx = tabIdx,
		win = win,
		order = 0,
	}, ContainerMT)
end

function ContainerMethods:nextOrder()
	self.order += 1; return self.order
end

function ContainerMethods:configKey(kind, name, id)
	return self.tabName .. ">" .. kind .. ":" .. (id or name)
end

function ContainerMethods:card(h)
	return pad(corner(self.win.Make("Frame", { LayoutOrder = self:nextOrder(), Size = UDim2.new(1, 0, 0, h) }, { BackgroundColor3 = "Secondary" }), 8), 16, 0)
end

function ContainerMethods:rowLabel(parent, icon, kind, label, rGap)
	local row = self.win.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -(rGap or 0), 1, 0), Parent = parent })
	local rl = Instance.new("UIListLayout")
	rl.FillDirection, rl.VerticalAlignment, rl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 10)
	rl.Parent = row
	local lbl = self.win.Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -26, 1, 0), Text = label, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row }, { TextColor3 = "Text" })
	local iconImg = self.win.Mkicon(icon, kind, row, UDim2.new(0, 16, 0, 16), false, lbl, 10)
	return lbl, iconImg
end

function ContainerMethods:Section(title, collapsed, bld)
	if type(collapsed) == "function" then bld, collapsed = collapsed, false end
	collapsed = collapsed and true or false
	local win = self.win

	local header = win.Make("TextButton", { BackgroundTransparency = 1, LayoutOrder = self:nextOrder(), Size = UDim2.new(1, 0, 0, 24) })
	local hl = Instance.new("UIListLayout")
	hl.FillDirection, hl.VerticalAlignment, hl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 6)
	hl.Parent = header
	local holder, setChevron = win.NewIndicator(header, false)
	local titleLbl = win.Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -20, 1, 0), FontWeight = "Bold", Text = title, Parent = header }, { TextColor3 = "SubText" })

	win.OnHover(header, function() win.Tween(titleLbl, Library.Config.Motion.Fast, { TextColor3 = Library._theme.Text }) end, function() win.Tween(titleLbl, Library.Config.Motion.Fast, { TextColor3 = Library._theme.SubText }) end)

	local subFrame = win.Make("Frame", { BackgroundTransparency = 1, LayoutOrder = self:nextOrder(), AutomaticSize = Enum.AutomaticSize.None, Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true, Visible = not collapsed })
	local cl = Instance.new("UIListLayout")
	cl.SortOrder, cl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 10)
	cl.Parent = subFrame

	local section = createContainer(subFrame, self.registry, self.tabName, self.tabIdx, win)
	section.Instance, section.Header = subFrame, header

	local function updateIndicator()
		local hasChildren = #subFrame:GetChildren() > 1
		holder.Visible, header.Active = hasChildren, hasChildren
	end
	subFrame.ChildAdded:Connect(updateIndicator)
	subFrame.ChildRemoved:Connect(updateIndicator)

	local isSectionAnimating = false
	local function setOpen(open)
		collapsed = not open
		setChevron(open)
		if win.reduceMotion then
			subFrame.Visible = open
			subFrame.AutomaticSize = open and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
			subFrame.Size = UDim2.new(1, 0, 0, 0)
			return
		end
		if isSectionAnimating then return end
		isSectionAnimating = true
		if open then
			subFrame.Visible = true
			subFrame.AutomaticSize = Enum.AutomaticSize.None
			subFrame.Size = UDim2.new(1, 0, 0, 0)
			local targetH = cl.AbsoluteContentSize.Y
			local t = TweenService:Create(subFrame, Library.Config.Motion.Normal, { Size = UDim2.new(1, 0, 0, targetH) })
			t:Play()
			t.Completed:Once(function()
				if not collapsed then
					subFrame.Size = UDim2.new(1, 0, 0, 0)
					subFrame.AutomaticSize = Enum.AutomaticSize.Y
				end
				isSectionAnimating = false
			end)
		else
			subFrame.AutomaticSize = Enum.AutomaticSize.None
			subFrame.Size = UDim2.new(1, 0, 0, cl.AbsoluteContentSize.Y)
			local t = TweenService:Create(subFrame, Library.Config.Motion.Normal, { Size = UDim2.new(1, 0, 0, 0) })
			t:Play()
			t.Completed:Once(function()
				if collapsed then subFrame.Visible = false end
				isSectionAnimating = false
			end)
		end
	end

	header.Activated:Connect(function() setOpen(collapsed) end)
    -- Per-section metatable so `section.Open = true/false` reads/writes reactively
	setmetatable(section, {
		__index = function(t, k) if k == "Open" then return not collapsed end; return ContainerMethods[k] end,
		__newindex = function(t, k, v) if k == "Open" then setOpen(v and true or false) else rawset(t, k, v) end end,
	})
	if bld then withScope(section, bld) end
	updateIndicator()

	subFrame.Visible = not collapsed
	subFrame.AutomaticSize = (not collapsed) and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
	subFrame.Size = UDim2.new(1, 0, 0, 0)
	setChevron(not collapsed)

	header.Parent = self.targetParent
	subFrame.Parent = self.targetParent

	win.AddSearchEntry(title, "Section", self.tabName, self.tabIdx, header, function(open) if open then setOpen(true) end end)
	return section
end

function ContainerMethods:Divider()
	local d = self.win.Make("Frame", { LayoutOrder = self:nextOrder(), Size = UDim2.new(1, 0, 0, 1), Parent = self.targetParent }, { BackgroundColor3 = "Stroke" })
	return { Instance = d }
end

function ContainerMethods:Text(title, content, icon, tooltip)
	if content == nil then content, title = title, nil end
	local win = self.win
	local f = pad(corner(win.Make("Frame", { LayoutOrder = self:nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, { BackgroundColor3 = "Secondary" }), 8), 16, 14)
	win.Stroke(f, "Stroke", 0.65, f, 0.2)
	local vl = Instance.new("UIListLayout")
	vl.Padding = UDim.new(0, 8); vl.Parent = f
	local head = win.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Library.Config.Text.Title + 4), Visible = title ~= nil, Parent = f })
	local hl = Instance.new("UIListLayout")
	hl.FillDirection, hl.VerticalAlignment, hl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8); hl.Parent = head
	local titleLbl = win.Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -26, 1, 0), FontWeight = "Bold", Text = title or "", TextSize = Library.Config.Text.Title, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head }, { TextColor3 = "Text" })
	local iconImg = win.Mkicon(icon, "Text", head, UDim2.new(0, 18, 0, 18), false, titleLbl, 8)
	local contentLbl = win.Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = Library.Config.Text.Body, TextWrapped = true, Text = content, Parent = f }, { TextColor3 = "SubText" })

	f.Parent = self.targetParent
	return TextHandle({
		root = f, head = head, titleLbl = titleLbl, contentLbl = contentLbl,
		iconImg = iconImg, desc = win.AttachTooltip(f, tooltip), win = win
	})
end

function ContainerMethods:Button(label, callback, icon, tooltip, opts)
	opts = opts or {}
	local win = self.win
	local f = self:card(46)
	local labelLbl, iconImg = self:rowLabel(f, icon, "Button", label, 0)
	local clickBtn = win.Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = f })
	win.Stroke(f, "Stroke", 0.65, clickBtn, 0.2)
	local setLocked, isLocked = win.AddLock(f)

	local state = {
		root = f, callback = callback, labelLbl = labelLbl, iconImg = iconImg,
		setLocked = setLocked, isLocked = isLocked, desc = win.AttachTooltip(f, tooltip),
		win = win, primaryEvent = "Activated"
	}
	if opts.Locked then setLocked(true) end

	clickBtn.Activated:Connect(function()
		win.Tween(f, Library.Config.Motion.Fast, { BackgroundColor3 = Library._theme.Stroke })
		task.delay(0.08, function() if f.Parent then win.Tween(f, Library.Config.Motion.Normal, { BackgroundColor3 = Library._theme.Secondary }) end end)
		fireEvent(state, "Activated", false, false)
	end)

	f.Parent = self.targetParent
	win.AddSearchEntry(label, "Button", self.tabName, self.tabIdx, f)
	return ButtonHandle(state)
end

function ContainerMethods:Toggle(label, default, callback, icon, tooltip, opts)
	opts = opts or {}
	local win = self.win
	local f = self:card(46)
	local labelLbl, iconImg = self:rowLabel(f, icon, "Toggle", label, 46)
	local sw = corner(win.Make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 40, 0, 22), Parent = f }), 11)
	win.Stroke(sw, "Stroke", 0.5)
	local circ = corner(win.Make("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), Size = UDim2.new(0, 16, 0, 16), Parent = sw }), 8)
	local clickBtn = win.Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = f })
	win.Stroke(f, "Stroke", 0.65, clickBtn, 0.2)
	local key, setLocked, isLocked = self:configKey("Toggle", label, opts.Id), win.AddLock(f)

	local state = {
		root = f, callback = callback, registry = self.registry, key = key, state = default and true or false,
		sw = sw, circ = circ, labelLbl = labelLbl, iconImg = iconImg, setLocked = setLocked, isLocked = isLocked,
		desc = win.AttachTooltip(f, tooltip), win = win, primaryEvent = "Changed"
	}
	if opts.Locked then setLocked(true) end

	win.BindTheme(sw, "BackgroundColor3", function(th) return state.state and th.Accent or th.Stroke end)
	clickBtn.Activated:Connect(function() applyToggle(state, not state.state, true) end)
	win.RegConfig(self.registry, key, state.state, state, "Toggle")

	f.Parent = self.targetParent
	win.AddSearchEntry(label, "Toggle", self.tabName, self.tabIdx, f)
	return ToggleHandle(state)
end

function ContainerMethods:Slider(label, min, max, default, step, callback, icon, tooltip, opts)
	if type(step) == "function" then callback, step = step, 1 else step = step or 1 end
	opts = opts or {}
	min, max, default = min or 0, max or 100, default or min or 0
	local win = self.win
	local f = self:card(70)
	local row = win.Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 10), Size = UDim2.new(1, 0, 0, 22), Parent = f })
	local rl = Instance.new("UIListLayout")
	rl.FillDirection, rl.VerticalAlignment, rl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8); rl.Parent = row
	local labelLbl = win.Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(0.6, -22, 1, 0), Text = label, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row }, { TextColor3 = "Text" })
	local iconImg = win.Mkicon(icon, "Slider", row, UDim2.new(0, 14, 0, 14), false, labelLbl, 8)
	local valLbl = win.Make("TextLabel", { Size = UDim2.new(0.3, 0, 0, 22), Position = UDim2.new(0.7, 0, 0, 10), FontWeight = "Bold", TextXAlignment = Enum.TextXAlignment.Right, Parent = f }, { TextColor3 = "Accent" })
	local bar = corner(win.Make("Frame", { Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 0, 6), Parent = f }, { BackgroundColor3 = "Stroke" }), 3)
	local fill = corner(win.Make("Frame", { Parent = bar }, { BackgroundColor3 = "Accent" }), 3)
	local knob = corner(win.Make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Color3.new(1, 1, 1), Parent = fill }), 6)
	win.Stroke(f, "Stroke", 0.65, f, 0.2)

	local key, decimals, setLocked, isLocked = self:configKey("Slider", label, opts.Id), decimalsOf(step), win.AddLock(f)
	local state = {
		root = f, callback = callback, registry = self.registry, key = key,
		cfg = { min = min, max = max, step = step, decimals = decimals, mult = 10 ^ decimals, current = default, dragging = false, suffix = opts.Suffix or "" },
		bar = bar, fill = fill, valLbl = valLbl, labelLbl = labelLbl, iconImg = iconImg, setLocked = setLocked, isLocked = isLocked,
		desc = win.AttachTooltip(f, tooltip), win = win, primaryEvent = "Changed"
	}
	if opts.Locked then setLocked(true) end

	win.OnHover(bar, function() win.Tween(knob, Library.Config.Motion.Fast, { Size = UDim2.new(0, 14, 0, 14) }) end, function()
		if not state.cfg.dragging then win.Tween(knob, Library.Config.Motion.Fast, { Size = UDim2.new(0, 12, 0, 12) }) end
	end)

	local c = state.cfg
	c.current = sliderRound(c, math.clamp(default, min, max))
	local denom = c.max - c.min
	sliderSetVisual(state, c.current, denom == 0 and 0 or (c.current - c.min) / denom, false)

	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			win.ClaimMove(bar, function(pos) sliderApply(state, sliderValueAt(state, pos.X), true, true) end, function()
				state.cfg.dragging = false
				win.Tween(knob, Library.Config.Motion.Fast, { Size = UDim2.new(0, 12, 0, 12) })
				win.RequestSave(state.registry, state.key)
			end)
			sliderApply(state, sliderValueAt(state, i.Position.X), true, true)
		end
	end)

	win.RegConfig(self.registry, key, default, state, "Slider")

	f.Parent = self.targetParent
	win.AddSearchEntry(label, "Slider", self.tabName, self.tabIdx, f)
	return SliderHandle(state)
end

function ContainerMethods:Dropdown(label, options, default, callback, icon, tooltip, opts)
	opts = opts or {}
	options = options or {}
	local multi, selected = (opts.Multi or type(default) == "table") and true or false, {}
	if multi then
		if type(default) == "table" then
			for _, v in default do selected[v] = true end
		elseif default ~= nil then
			selected[default] = true
		end
		default = nil
	else
		default = default or options[1]
	end

	local win = self.win
	local f = self:card(50); f.ClipsDescendants = true
	local head = win.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), Parent = f })
	local labelLbl, iconImg = self:rowLabel(head, icon, "Dropdown", label, 170)
	local clickBtn = win.Make("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Parent = f })
	local selector = corner(win.Make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 160, 0, 34), ClipsDescendants = true, Parent = head }, { BackgroundColor3 = "Background" }), 6)
	win.Stroke(selector, "Stroke", 0.6, clickBtn, 0.2)
	win.Stroke(f, "Stroke", 0.65, clickBtn, 0.2)
	local selLabel = win.Make("TextLabel", { Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -28, 1, 0), TextSize = Library.Config.Text.Body, Parent = selector }, { TextColor3 = "Text" })
	local _, setChevron = win.NewIndicator(selector, true)
	local listHolder = win.Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 50), Size = UDim2.new(1, 0, 0, 0), Parent = f })
	local vl = Instance.new("UIListLayout")
	vl.SortOrder, vl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 6); vl.Parent = listHolder

	local filterWrap = pad(win.Stroke(corner(win.Make("Frame", { LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 30), Visible = false, Parent = listHolder }, { BackgroundColor3 = "Background" }), 6), "Stroke", 0.6), 8, 0)
	local filterBox = win.Make("TextBox", { Size = UDim2.new(1, 0, 1, 0), PlaceholderText = "Search...", Text = "", TextSize = Library.Config.Text.Body, ClearTextOnFocus = false, Parent = filterWrap }, { BackgroundColor3 = "Background", TextColor3 = "Text", PlaceholderColor3 = "SubText" })
	local optTemplate = corner(win.Make("TextButton", { Size = UDim2.new(1, 0, 0, 32), TextSize = Library.Config.Text.Body }), 6)

	local key, setLocked, isLocked = self:configKey("Dropdown", label, opts.Id), win.AddLock(f)
	local state = {
		root = f, callback = callback, registry = self.registry, key = key, multi = multi, options = options, selected = selected, default = default,
		openState = false, optData = {}, selLabel = selLabel, setChevron = setChevron, listHolder = listHolder,
		filterWrap = filterWrap, filterBox = filterBox, optTemplate = optTemplate,
		labelLbl = labelLbl, iconImg = iconImg, setLocked = setLocked, isLocked = isLocked, desc = win.AttachTooltip(f, tooltip),
		win = win, searchable = false, filterText = "", primaryEvent = "Changed"
	}
	if opts.Locked then setLocked(true) end

	filterBox:GetPropertyChangedSignal("Text"):Connect(function()
		state.filterText = string.lower(filterBox.Text)
		dropdownApplyFilter(state)
	end)

	table.insert(win.activeDropdowns, state)
	dropdownBuildOptions(state)
	if opts.Searchable then dropdownSetSearchable(state, true) end
	clickBtn.Activated:Connect(function() dropdownSetOpened(state, not state.openState) end)
	win.RegConfig(self.registry, key, dropdownGetValue(state), state, "Dropdown")

	f.Parent = self.targetParent
	win.AddSearchEntry(label, "Dropdown", self.tabName, self.tabIdx, f, function(open) if open then dropdownSetOpened(state, true) end end)
	return DropdownHandle(state)
end

function ContainerMethods:Keybind(label, default, callback, icon, tooltip, opts)
	opts = opts or {}
	local win = self.win
	local f = self:card(46)
	local labelLbl, iconImg = self:rowLabel(f, icon, "Keybind", label, 110)
	local bind = pad(corner(win.Make("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 30), FontWeight = "Bold", Text = default and default.Name or "None", TextSize = Library.Config.Text.Body, Parent = f }, { BackgroundColor3 = "Background", TextColor3 = "Text" }), 6), 8, 0)
	local _, bs = win.Stroke(bind, "Stroke", 0.5, bind, 0.2)
	win.Stroke(f, "Stroke", 0.65, f, 0.2)

	local key, setLocked, isLocked = self:configKey("Keybind", label, opts.Id), win.AddLock(f)
	local state = {
		root = f, callback = callback, registry = self.registry, key = key, value = default, listening = false, bindBtn = bind,
		labelLbl = labelLbl, iconImg = iconImg, setLocked = setLocked, isLocked = isLocked, desc = win.AttachTooltip(f, tooltip),
		win = win, primaryEvent = "Pressed"
	}
	if opts.Locked then setLocked(true) end

	bind.Activated:Connect(function()
		state.listening = true
		bind.Text = "..."
		if bs then win.Tween(bs, Library.Config.Motion.Fast, { Color = Library._theme.Accent, Transparency = 0 }) end
	end)

	win.Conn(UserInputService.InputBegan, function(i, gpe)
		if state.listening and i.UserInputType == Enum.UserInputType.Keyboard then
			local newKey = (i.KeyCode == Enum.KeyCode.Backspace or i.KeyCode == Enum.KeyCode.Escape) and nil or i.KeyCode
			state.listening = false
			if bs then win.Tween(bs, Library.Config.Motion.Fast, { Color = Library._theme.Stroke, Transparency = 0.5 }) end
			keybindSetKey(state, newKey, true)
		elseif not gpe and state.value and i.KeyCode == state.value then
			fireEvent(state, "Pressed", false, state.value)
		end
	end)

	win.RegConfig(self.registry, key, default and default.Name or "None", state, "Keybind")

	f.Parent = self.targetParent
	win.AddSearchEntry(label, "Keybind", self.tabName, self.tabIdx, f)
	return KeybindHandle(state)
end

function ContainerMethods:Input(label, placeholder, default, callback, icon, tooltip, opts)
	opts = opts or {}
	local win = self.win
	local f = self:card(50)
	win.Stroke(f, "Stroke", 0.65, f, 0.2)
	local labelLbl, iconImg = self:rowLabel(f, icon, "Input", label, 170)
	local box = pad(corner(win.Make("TextBox", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 160, 0, 34), PlaceholderText = placeholder or "", Text = default or "", TextSize = Library.Config.Text.Body, ClipsDescendants = true, Parent = f }, { BackgroundColor3 = "Background", TextColor3 = "Text", PlaceholderColor3 = "SubText" }), 6), 10, 0)
	local _, boxStroke = win.Stroke(box, "Stroke", 0.6, box, 0.2)

	local key, setLocked, isLocked = self:configKey("Input", label, opts.Id), win.AddLock(f)
	local state = {
		root = f, callback = callback, registry = self.registry, key = key, box = box, maxLength = opts.MaxLength or 0, digitsOnly = opts.DigitsOnly and true or false,
		labelLbl = labelLbl, iconImg = iconImg, setLocked = setLocked, isLocked = isLocked, desc = win.AttachTooltip(f, tooltip),
		win = win, primaryEvent = "Changed"
	}
	if opts.Locked then setLocked(true) end

	box:GetPropertyChangedSignal("Text"):Connect(function()
		if state.digitsOnly then
			local stripped = box.Text:gsub("%D", "")
			if stripped ~= box.Text then box.Text = stripped; return end
		end
		if state.maxLength > 0 and #box.Text > state.maxLength then
			box.Text = string.sub(box.Text, 1, state.maxLength)
			return
		end
		inputUpdateAlign(state)
	end)

	box.Focused:Connect(function()
		if boxStroke then win.Tween(boxStroke, Library.Config.Motion.Fast, { Color = Library._theme.Accent, Transparency = 0 }) end
		task.defer(function() box.CursorPosition = #box.Text + 1 end)
	end)

	box.FocusLost:Connect(function()
		if boxStroke then win.Tween(boxStroke, Library.Config.Motion.Fast, { Color = Library._theme.Stroke, Transparency = 0.6 }) end
		inputSetValue(state, box.Text, true)
	end)

	inputUpdateAlign(state)
	win.RegConfig(self.registry, key, default or "", state, "Input")

	f.Parent = self.targetParent
	win.AddSearchEntry(label, "Input", self.tabName, self.tabIdx, f)
	return InputHandle(state)
end

function ContainerMethods:Color(label, default, callback, icon, tooltip, opts)
	opts = opts or {}
	local win = self.win
	local f = self:card(46); f.ClipsDescendants = true
	local head = win.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Parent = f })
	local labelLbl, iconImg = self:rowLabel(head, icon, "Color", label, 48)
	local col = normalizeColor(default) or Color3.fromRGB(255, 255, 255)
	local h, s, v = col:ToHSV()

	local headClick = win.Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = head })
	win.Stroke(f, "Stroke", 0.65, headClick, 0.2)

	local swatch = corner(win.Make("TextButton", { BackgroundColor3 = col, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 34, 0, 22), Parent = head }), 6)
	win.Stroke(swatch, "Stroke", 0.5, swatch, 0.1)

	local content = win.Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 0, 130), Visible = false, Parent = f })
	local cl = Instance.new("UIListLayout")
	cl.SortOrder, cl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 8); cl.Parent = content

	local map = corner(win.Make("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 74), BackgroundColor3 = Color3.fromHSV(h, 1, 1), Parent = content }), 6)
	local satOverlay = corner(win.Make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = map }), 6)
	local sGrad = Instance.new("UIGradient", satOverlay)
	sGrad.Transparency = NumberSequence.new(0, 1)
	local valOverlay = corner(win.Make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), Parent = map }), 6)
	local vGrad = Instance.new("UIGradient", valOverlay)
	vGrad.Rotation, vGrad.Transparency = 90, NumberSequence.new(1, 0)
	local satCursor = win.Stroke(corner(win.Make("Frame", { Size = UDim2.new(0, 10, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s, 0, 1 - v, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = map }), 5), "Stroke", 0.3)

	local hueBar = corner(win.Make("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = Color3.new(1, 1, 1), Parent = content }), 5)
	local hGrad = Instance.new("UIGradient", hueBar)
	hGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	})
	local hueCursor = win.Stroke(corner(win.Make("Frame", { Size = UDim2.new(0, 8, 1, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(h, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = hueBar }), 3), "Stroke", 0.4)

	local inRow = win.Make("Frame", { LayoutOrder = 3, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Parent = content })
	local irl = Instance.new("UIListLayout")
	irl.FillDirection, irl.Padding = Enum.FillDirection.Horizontal, UDim.new(0, 6); irl.Parent = inRow
	local hexBox, hexStroke = win.Stroke(corner(win.Make("TextBox", { LayoutOrder = 1, Size = UDim2.new(0.4, -4, 1, 0), Text = "#" .. col:ToHex():upper(), TextSize = Library.Config.Text.Small, TextXAlignment = Enum.TextXAlignment.Center, Parent = inRow }, { BackgroundColor3 = "Background", TextColor3 = "Text" }), 6), "Stroke", 0.6)

	local chanBoxes = {}
	local function addBoxFocus(b, bs)
		b.Focused:Connect(function() if bs then win.Tween(bs, Library.Config.Motion.Fast, { Color = Library._theme.Accent, Transparency = 0 }) end end)
		b.FocusLost:Connect(function() if bs then win.Tween(bs, Library.Config.Motion.Fast, { Color = Library._theme.Stroke, Transparency = 0.6 }) end end)
	end
	addBoxFocus(hexBox, hexStroke)

	for idx, name in { "R", "G", "B" } do
		local b, bs = win.Stroke(corner(win.Make("TextBox", { LayoutOrder = idx + 1, Size = UDim2.new(0.2, -4, 1, 0), PlaceholderText = name, Text = tostring(math.floor(col[name] * 255 + 0.5)), TextSize = Library.Config.Text.Small, TextXAlignment = Enum.TextXAlignment.Center, Parent = inRow }, { BackgroundColor3 = "Background", TextColor3 = "Text", PlaceholderColor3 = "SubText" }), 6), "Stroke", 0.6)
		chanBoxes[name] = b
		addBoxFocus(b, bs)
	end

	local key, setLocked, isLocked = self:configKey("Color", label, opts.Id), win.AddLock(f)
	local state = {
		root = f, callback = callback, registry = self.registry, key = key, col = col, hsv = { h = h, s = s, v = v },
		map = map, hueBar = hueBar, satCursor = satCursor, hueCursor = hueCursor, swatch = swatch, hexBox = hexBox, chanBoxes = chanBoxes,
		labelLbl = labelLbl, iconImg = iconImg, setLocked = setLocked, isLocked = isLocked, desc = win.AttachTooltip(f, tooltip),
		win = win, lastCommitted = col, primaryEvent = "Changed"
	}
	if opts.Locked then setLocked(true) end

	local opened = false
	local function toggleOpen()
		opened = not opened
		content.Visible = opened
		win.Tween(f, Library.Config.Motion.Normal, { Size = UDim2.new(1, 0, 0, opened and 184 or 46) })
	end
	swatch.Activated:Connect(toggleOpen)
	headClick.Activated:Connect(toggleOpen)

	local function bindPick(target, updateFn)
		target.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				local function pick(pos) updateFn(pos); colorUpdateVisuals(state, true) end
				win.ClaimMove(target, pick, function()
					colorUpdateVisuals(state, false)
					colorCommit(state, true)
				end)
				pick(i.Position)
			end
		end)
	end

	bindPick(map, function(pos)
		state.hsv.s = math.clamp((pos.X - map.AbsolutePosition.X) / map.AbsoluteSize.X, 0, 1)
		state.hsv.v = 1 - math.clamp((pos.Y - map.AbsolutePosition.Y) / map.AbsoluteSize.Y, 0, 1)
	end)
	bindPick(hueBar, function(pos)
		state.hsv.h = math.clamp((pos.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
	end)

	hexBox.FocusLost:Connect(function()
		local ok, newCol = pcall(Color3.fromHex, hexBox.Text)
		if ok and newCol then
			state.hsv.h, state.hsv.s, state.hsv.v = newCol:ToHSV()
			colorUpdateVisuals(state, false)
			colorCommit(state, true)
		else
			hexBox.Text = "#" .. state.col:ToHex():upper()
		end
	end)

	local function commitRgb()
		state.hsv.h, state.hsv.s, state.hsv.v = Color3.fromRGB(tonumber(chanBoxes.R.Text) or 0, tonumber(chanBoxes.G.Text) or 0, tonumber(chanBoxes.B.Text) or 0):ToHSV()
		colorUpdateVisuals(state, false)
		colorCommit(state, true)
	end
	for _, b in chanBoxes do b.FocusLost:Connect(commitRgb) end

	win.RegConfig(self.registry, key, { R = math.floor(col.R * 255 + 0.5), G = math.floor(col.G * 255 + 0.5), B = math.floor(col.B * 255 + 0.5) }, state, "Color")

	f.Parent = self.targetParent
	win.AddSearchEntry(label, "Color", self.tabName, self.tabIdx, f)
	return ColorHandle(state)
end

function ContainerMethods:Textarea(label, placeholder, default, callback, icon, tooltip, opts)
    opts = opts or {}
    local win = self.win
    local hasLabel = label ~= nil and label ~= ""
    local f = pad(corner(win.Make("Frame", { LayoutOrder = self:nextOrder(), Size = UDim2.new(1, 0, 0, hasLabel and 146 or 118) }, { BackgroundColor3 = "Secondary" }), 8), 16, 14)
    win.Stroke(f, "Stroke", 0.65, f, 0.2)

    local inner = win.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = f })
    local vl = Instance.new("UIListLayout")
    vl.Padding = UDim.new(0, 8); vl.Parent = inner

    local head = win.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, Library.Config.Text.Title), Visible = hasLabel, Parent = inner })
    local hl = Instance.new("UIListLayout")
    hl.FillDirection, hl.VerticalAlignment, hl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8); hl.Parent = head
    local labelLbl = win.Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -24, 1, 0), FontWeight = "Bold", Text = label or "", TextTruncate = Enum.TextTruncate.AtEnd, Parent = head }, { TextColor3 = "Text" })
    local iconImg = win.Mkicon(icon, "Text", head, UDim2.new(0, 16, 0, 16), false, labelLbl, 8)

    local boxHolder = corner(win.Make("ScrollingFrame", { Size = UDim2.new(1, 0, 0, 90), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = inner }, { BackgroundColor3 = "Background" }), 6)
    win.StyleScroll(boxHolder, false)
    local _, boxStroke = win.Stroke(boxHolder, "Stroke", 0.6, boxHolder, 0.2)
    local box = pad(win.Make("TextBox", {
        Size = UDim2.new(1, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.Y, Text = default or "", PlaceholderText = placeholder or "",
        TextSize = Library.Config.Text.Body, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        MultiLine = true, ClearTextOnFocus = false, BackgroundTransparency = 1, Parent = boxHolder,
    }, { TextColor3 = "Text", PlaceholderColor3 = "SubText" }), 8, 6)

    local baseSetLocked, isLocked = win.AddLock(f)
    local function setLocked(st)
        baseSetLocked(st)
        box.TextEditable = not st
    end

    local key = self:configKey("Textarea", label or "", opts.Id)
    local state = {
        root = f, callback = callback, registry = self.registry, key = key, box = box, head = head, maxLength = opts.MaxLength or 0,
        labelLbl = labelLbl, iconImg = iconImg, setLocked = setLocked, isLocked = isLocked, desc = win.AttachTooltip(f, tooltip),
        win = win, primaryEvent = "Changed"
    }
    if opts.Locked then setLocked(true) end

    boxHolder.InputBegan:Connect(function(i)
        if (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and not isLocked() then
            box:CaptureFocus()
        end
    end)

    box:GetPropertyChangedSignal("Text"):Connect(function()
        if state.maxLength > 0 and #box.Text > state.maxLength then
            box.Text = string.sub(box.Text, 1, state.maxLength)
        end
    end)
    box.Focused:Connect(function()
        if boxStroke then win.Tween(boxStroke, Library.Config.Motion.Fast, { Color = Library._theme.Accent, Transparency = 0 }) end
        task.defer(function() box.CursorPosition = #box.Text + 1 end)
    end)
    box.FocusLost:Connect(function()
        if boxStroke then win.Tween(boxStroke, Library.Config.Motion.Fast, { Color = Library._theme.Stroke, Transparency = 0.6 }) end
        textareaSetValue(state, box.Text, true)
    end)

    win.RegConfig(self.registry, key, default or "", state, "Textarea")

    f.Parent = self.targetParent
    win.AddSearchEntry(label or "Textarea", "Textarea", self.tabName, self.tabIdx, f)
    return TextareaHandle(state)
end

-----------------------------------------------------------
-- Window subsystems
-----------------------------------------------------------
local Defaults = {
	Frame = { BorderSizePixel = 0 }, ScrollingFrame = { BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0) },
	TextLabel = { BackgroundTransparency = 1, BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left },
	TextButton = { BorderSizePixel = 0, AutoButtonColor = false, Text = "" },
	TextBox = { Text = "", BorderSizePixel = 0, ClearTextOnFocus = false },
	ImageLabel = { BackgroundTransparency = 1, BorderSizePixel = 0 }, ImageButton = { BackgroundTransparency = 1, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Fit },
}

local lockedElements = setmetatable({}, { __mode = "k" })
local function isElementLocked(inst)
	return lockedElements[inst] or (inst.Parent and lockedElements[inst.Parent]) or false
end

-----------------------------------------------------------
-- Window factory
-----------------------------------------------------------
function Library:CreateWindow(opt)
	opt = opt or {}
	local builder = opt.Builder
	if opt.Globals then
		local ok, callerEnv = pcall(getfenv, 2)
		if ok and type(callerEnv) == "table" then registerDeclaratives(callerEnv) end
		if type(getgenv) == "function" then pcall(registerDeclaratives, getgenv()) end
	end

	local kvantData = nil
	if supported and isfile(PERSIST.Kvant) then
		local ok, raw = pcall(readfile, PERSIST.Kvant)
		kvantData = ok and decodeConfig(raw) or nil
	end

	local function getPreloaded(kind, name, default)
		if not kvantData then return default end
		local key = "Settings>" .. kind .. ":" .. name
		if kvantData[key] ~= nil then return kvantData[key] end
		for k, v in kvantData do
			if string.find(k, kind .. ":" .. name, 1, true) then return v end
		end
		return default
	end

	local secure = opt.Secure and true or false
	local savedTheme = getPreloaded("Dropdown", "Theme", nil)
	if savedTheme then Library:SetTheme(savedTheme)
	elseif opt.Theme then Library:SetTheme(opt.Theme) end

	local savedFont = getPreloaded("Dropdown", "Font", nil)
    if secure and (savedFont == "Inter" or opt.Font == "Inter") then savedFont, opt.Font = "Roboto", "Roboto" end -- inter requires assetid than can leak
    if savedFont then Library:SetFont(savedFont)
    elseif opt.Font then Library:SetFont(opt.Font) end

	local baseScale = 1
	local savedScale = getPreloaded("Slider", "UI Scale", nil)
	if savedScale then baseScale = savedScale / 100 end

	local reduceMotion = getPreloaded("Toggle", "Reduce Motion", false)
	local hoverEffects = getPreloaded("Toggle", "Hover Animations", true)
    local iconsOn = getPreloaded("Toggle", "Show Icons", true)
	local autoload = getPreloaded("Toggle", "Autoload Settings", true)
	local notificationsEnabled = getPreloaded("Toggle", "Notifications", true)
	local closeBtnDefault = getPreloaded("Toggle", "Close Button", false)
	local unlockCursor = getPreloaded("Toggle", "Unlock Cursor", true)

	local T, F, Motion = Library.Config.Text, Library.Config.Fonts, Library.Config.Motion
	local isSide, isDev, searchEnabled, autoTabIcons = opt.SideTabs or false, opt.Dev and true or false, opt.ShowSearch ~= false, opt.AutoIcons and true or false

	local win = {
		secure = secure,
		reduceMotion = reduceMotion,
		hoverEffects = hoverEffects,
		iconsOn = iconsOn,
		notificationsEnabled = notificationsEnabled,
		autoload = autoload,
		baseScale = baseScale,
		minimized = false,
		unlockCursor = unlockCursor,
		isAnimating = false,
		boundInstances = {},
		fontRegistry = setmetatable({}, { __mode = "k" }),
		themeBindings = setmetatable({}, { __mode = "k" }),
		icons = {},
		iconMap = setmetatable({}, { __mode = "k" }),
		indicators = {},
		conns = {},
		activeDropdowns = {},
		KvantConfig = {},
		GameConfig = {},
		dirtyKeys = {},
		lastWritten = {},
		savePending = {},
		isApplyingConfig = false,
	}

	local function conn(sig, fn) local c = sig:Connect(fn); table.insert(win.conns, c); return c end
	win.Conn = conn

	function win.BindTheme(inst, prop, key)
		local bindings = win.themeBindings[inst] or {}
		win.themeBindings[inst] = bindings
		if #bindings == 0 then table.insert(win.boundInstances, inst) end
		table.insert(bindings, { prop, key })
		local val = type(key) == "function" and key(Library._theme) or Library._theme[key]
		if val then inst[prop] = val end
		return inst
	end

	function win.BindFont(inst, weight)
		table.insert(win.fontRegistry, { inst = inst, weight = weight })
		inst.FontFace = F[weight] or F.Regular
		return inst
	end

	function win.Tween(inst, info, props)
		if win.reduceMotion then for k, v in props do inst[k] = v end else TweenService:Create(inst, info, props):Play() end
	end

	function win.OnHover(trigger, onEnter, onLeave)
		trigger.MouseEnter:Connect(function()
			if win.hoverEffects and not isElementLocked(trigger) then onEnter() end
		end)
		trigger.MouseLeave:Connect(function()
			if not isElementLocked(trigger) then onLeave() end
		end)
	end

	local function applyTheme()
		for i = #win.boundInstances, 1, -1 do
			local inst = win.boundInstances[i]
			if inst.Parent then
				for _, b in win.themeBindings[inst] do
					local prop, key = b[1], b[2]
					local val = type(key) == "function" and key(Library._theme) or Library._theme[key]
					if val then
						if win.reduceMotion then inst[prop] = val else win.Tween(inst, Motion.Normal, { [prop] = val }) end
					end
				end
			else
				win.themeBindings[inst] = nil
				win.boundInstances[i] = win.boundInstances[#win.boundInstances]
				win.boundInstances[#win.boundInstances] = nil
			end
		end
		for _, s in win.activeDropdowns do dropdownRefreshColors(s) end
	end

	local function applyFont()
		for i = #win.fontRegistry, 1, -1 do
			local e = win.fontRegistry[i]
			if e.inst.Parent then e.inst.FontFace = F[e.weight] or F.Regular
			else win.fontRegistry[i] = win.fontRegistry[#win.fontRegistry]; win.fontRegistry[#win.fontRegistry] = nil end
		end
	end

	local windowEntry = { applyTheme = applyTheme, applyFont = applyFont }
	table.insert(Library._windows, windowEntry)

	function win.Make(class, props, themeBinds)
		local inst = Instance.new(class)
		inst.Name = class
		local d = Defaults[class]
		if d then for k, v in d do inst[k] = v end end
		if class == "TextLabel" then inst.FontFace = F.Medium; inst.TextSize = T.Label end
		if class == "TextBox" then inst.FontFace = F.Medium; inst.TextSize = T.Body end
		for k, v in props do if k ~= "Parent" and k ~= "FontWeight" then inst[k] = v end end
		if themeBinds then for prop, key in themeBinds do win.BindTheme(inst, prop, key) end end
		if (class == "TextLabel" or class == "TextButton" or class == "TextBox") and inst.FontFace ~= F.Icons then
			win.BindFont(inst, props and props.FontWeight or (inst.FontFace == F.Bold and "Bold" or "Medium"))
		end
		if props and props.Parent then inst.Parent = props.Parent end
		return inst
	end

	function win.MakeIcon(id, defaultKind, props, colorKey, isButton, trackVisibility, pairedLabel, gap)
		local p = table.clone(props or {})
		local prop = win.secure and "TextColor3" or "ImageColor3"
		if win.secure then
			p.FontFace = F.Icons
			p.Text = resolveTextIcon(id, defaultKind)
			p.TextXAlignment = p.TextXAlignment or Enum.TextXAlignment.Center
		else
			p.TextSize, p.TextXAlignment = nil, nil
			p.Image = resolveIcon(id, defaultKind)
		end
		local class = win.secure and (isButton and "TextButton" or "TextLabel") or (isButton and "ImageButton" or "ImageLabel")
		local inst = win.Make(class, p, colorKey and { [prop] = colorKey } or nil)
		if trackVisibility or pairedLabel then
			local shown = win.secure and (inst.Text ~= "") or (inst.Image ~= "")
			local function sync()
				local show = shown and win.iconsOn
				inst.Visible = show
				if pairedLabel then
					pairedLabel.Size = UDim2.new(pairedLabel.Size.X.Scale, show and -gap or 0, pairedLabel.Size.Y.Scale, pairedLabel.Size.Y.Offset)
				end
			end
			table.insert(win.icons, { inst = inst, sync = sync })
			sync()
		end
		return inst
	end

	function win.Stroke(p, colKey, trans, triggerBtn, transHover)
		local s = Instance.new("UIStroke")
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		local restTrans, hoverTrans = trans or 0.65, transHover or 0.2
		s.Transparency = restTrans
		win.BindTheme(s, "Color", colKey or "Stroke")
		s.Parent = p

		if triggerBtn then
			win.OnHover(triggerBtn, function() win.Tween(s, Motion.Fast, { Transparency = hoverTrans }) end, function() win.Tween(s, Motion.Fast, { Transparency = restTrans }) end)
		end
		return p, s
	end

	function win.HoverIcon(btn)
        local prop = (btn:IsA("ImageLabel") or btn:IsA("ImageButton")) and "ImageColor3" or "TextColor3"
        win.OnHover(btn,
            function() win.Tween(btn, Motion.Fast, { [prop] = Library._theme.Accent }) end,
            function() win.Tween(btn, Motion.Fast, { [prop] = Library._theme.Icon }) end
        )
	end

	function win.Mkicon(id, kind, parent, size, isMuted, pairedLabel, padding)
		local gap = size.X.Offset + (padding or 10)
        local img = win.Make("ImageLabel", { LayoutOrder = 1, Size = size, Image = not win.secure and resolveIcon(id, kind) or "", Parent = parent }, { ImageColor3 = isMuted and "IconMuted" or "Icon" })
		local function sync()
			local show = img.Image ~= "" and win.iconsOn
			img.Visible = show
			if pairedLabel then
				pairedLabel.Size = UDim2.new(pairedLabel.Size.X.Scale, show and -gap or 0, pairedLabel.Size.Y.Scale, pairedLabel.Size.Y.Offset)
			end
		end
		local entry = { inst = img, lbl = pairedLabel, gap = gap, muted = isMuted or false, sync = sync }
		table.insert(win.icons, entry)
		win.iconMap[img] = entry
		sync()
		return img
	end

	function win.SetIcon(img, id)
		local entry = win.iconMap[img]
        local resolved = not win.secure and resolveIcon(id) or ""
		if entry then
			entry.inst.Image = resolved
			entry.sync()
		else
			img.Image = resolved
			img.Visible = (resolved ~= "") and win.iconsOn
		end
	end

	function win.NewIndicator(parent, isDropdown)
		local holder = win.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), AnchorPoint = isDropdown and Vector2.new(1, 0.5) or Vector2.new(0.5, 0.5), Position = isDropdown and UDim2.new(1, -7, 0.5, 0) or UDim2.new(0.5, 0, 0.5, 0), Parent = parent })
        local icon = win.MakeIcon(nil, "Dropdown", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = win.secure and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 12, 0, 12),
            TextSize = T.Small, Parent = holder,
        }, "SubText")

		local function setOpen(open)
            if win.secure then
                icon.Text = isDropdown and (open and TEXT_ICONS.Small_Up or TEXT_ICONS.Small_Down) or (open and TEXT_ICONS.Large_Down or TEXT_ICONS.Large_Right)
            else
                win.Tween(icon, Motion.Normal, { Rotation = isDropdown and (open and 180 or 0) or (open and 0 or -90) })
            end
		end
        setOpen(false)
		return holder, setOpen
	end

	function win.StyleScroll(f, horiz)
		f.ScrollBarThickness = 3; win.BindTheme(f, "ScrollBarImageColor3", "SubText"); f.ScrollBarImageTransparency = 0.25
		f[horiz and "HorizontalScrollBarInset" or "VerticalScrollBarInset"] = Enum.ScrollBarInset.Always
	end

	function win.AddLock(f)
		local p = f:FindFirstChildOfClass("UIPadding")
		local pl, pr = p and p.PaddingLeft.Offset or 0, p and p.PaddingRight.Offset or 0
		local pt, pb = p and p.PaddingTop.Offset or 0, p and p.PaddingBottom.Offset or 0
		local blocker = corner(win.Make("TextButton", {
			Position = UDim2.new(0, -pl, 0, -pt),
			Size = UDim2.new(1, pl + pr, 1, pt + pb),
			BackgroundTransparency = 1, Text = "",
			Active = false, Visible = false, ZIndex = 90, Parent = f
		}, { BackgroundColor3 = "Background" }), 8)
		local locked = false
		return function(st)
			locked = st and true or false
			lockedElements[f] = locked or nil
			blocker.Visible, blocker.Active = locked, locked
			win.Tween(blocker, Motion.Normal, { BackgroundTransparency = locked and 0.5 or 1 })
			local s = f:FindFirstChildOfClass("UIStroke")
			if locked and s then win.Tween(s, Motion.Fast, { Transparency = 0.65 }) end
		end, function() return locked end
	end

	function win.RegConfig(registry, key, default, state, kind)
		registry[key] = { default = default, state = state, kind = kind }
	end

	local function markDirty(registry, key)
		local d = win.dirtyKeys[registry] or {}; win.dirtyKeys[registry] = d; d[key] = true
	end

	local function flushSave(registry)
		win.savePending[registry] = nil
		local dirty = win.dirtyKeys[registry]
		if not dirty then return end
		local snapshot = win.lastWritten[registry] or {}; win.lastWritten[registry] = snapshot
		local changed = false
		for k in dirty do
			local entry = registry[k]
			if entry then
				local ok, res = pcall(ConfigOps[entry.kind].get, entry.state)
				if ok and not valuesEqual(snapshot[k], res) then snapshot[k] = res; changed = true end
			end
		end
		table.clear(dirty)
		if changed then
			ensureFolders()
			local encoded = encodeConfig(snapshot)
			if encoded then pcall(writefile, registry == win.KvantConfig and PERSIST.Kvant or PERSIST.Game(GameId), encoded) end
		end
	end

	function win.RequestSave(registry, key)
		if win.isApplyingConfig then return end
		if key then markDirty(registry, key) end
		if not supported or win.savePending[registry] then return end
		win.savePending[registry] = true
		task.delay(SAVE_DEBOUNCE, function() flushSave(registry) end)
	end

	local function applyConfig(registry, pathOrData)
		if not supported then return end
		local decoded = nil
		if type(pathOrData) == "table" then decoded = pathOrData
		elseif type(pathOrData) == "string" and isfile(pathOrData) then
			local ok, raw = pcall(readfile, pathOrData)
			decoded = ok and decodeConfig(raw) or nil
		end
		if not decoded then return end

		local prevApplying = win.isApplyingConfig
		win.isApplyingConfig = true
		win.lastWritten[registry] = table.clone(decoded)
		for k, entry in registry do
			if decoded[k] ~= nil then pcall(ConfigOps[entry.kind].set, entry.state, decoded[k]) end
		end
		win.isApplyingConfig = prevApplying
	end

	local activeMove, activeMoveOwner, activeMoveEnd, dragMoved = nil, nil, nil, false
	function win.ClaimMove(owner, fn, onEnd)
		if activeMove == nil or activeMoveOwner == owner then activeMove, activeMoveOwner, activeMoveEnd = fn, owner, onEnd end
	end

	conn(UserInputService.InputChanged, function(i)
		if activeMove and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then activeMove(i.Position) end
	end)
	conn(UserInputService.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			if activeMoveEnd then activeMoveEnd() end
			activeMove, activeMoveOwner, activeMoveEnd = nil, nil, nil
			task.defer(function() dragMoved = false end)
		end
	end)

	local gui = win.Make("ScreenGui", { ResetOnSpawn = false, Parent = gethui and gethui() or cloneref(game:FindFirstChild("CoreGui")) or cloneref(game:GetService("Players")).LocalPlayer:WaitForChild("PlayerGui") })

	local function makeDraggable(frame, handle, key)
		(handle or frame).InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				local sx, sy = i.Position.X, i.Position.Y
				local ox, oy = frame.Position.X.Offset, frame.Position.Y.Offset
				local sp = frame.AbsolutePosition
				dragMoved = false
				win.ClaimMove(frame, function(pos)
					local dx, dy = pos.X - sx, pos.Y - sy
					if math.abs(dx) > 3 or math.abs(dy) > 3 then dragMoved = true end
					local screen, sz = gui.AbsoluteSize, frame.AbsoluteSize
                    local pad = 10 -- keeps grip + topbar edge locked at screen boundary
					local tx = math.clamp(sp.X + dx, pad - sz.X, screen.X - pad)
					local ty = math.clamp(sp.Y + dy, pad - sz.Y, screen.Y - pad)
					frame.Position = UDim2.new(frame.Position.X.Scale, ox + (tx - sp.X), frame.Position.Y.Scale, oy + (ty - sp.Y))
				end, function()
					if dragMoved and key then win.RequestSave(win.KvantConfig, key) end
				end)
			end
		end)
	end

	local main = win.Stroke(corner(win.Make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = opt.Size or (isSide and WIN_SIZE_SIDE or WIN_SIZE_TOP), Active = true, ClipsDescendants = false, Parent = gui }, { BackgroundColor3 = "Background" }), 10), "Stroke")
	local defaultPosition = main.Position

	local modalBtn = win.Make("TextButton", { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, Text = "", Modal = win.unlockCursor and not win.minimized, Parent = main })

	local function setCursor(active)
		modalBtn.Modal = active
		pcall(function()
			UserInputService.OverrideMouseIconBehavior = active and Enum.OverrideMouseIconBehavior.ForceShow or Enum.OverrideMouseIconBehavior.None
			if active and UserInputService.MouseIcon ~= "" then UserInputService.MouseIcon = "" end
		end)
	end

	conn(UserInputService:GetPropertyChangedSignal("MouseIcon"), function()
		if modalBtn.Modal and UserInputService.MouseIcon ~= "" then
			pcall(function() UserInputService.MouseIcon = "" end)
		end
	end)

	local mainConstraint = Instance.new("UISizeConstraint", main)
	mainConstraint.MinSize = opt.MinSize or (isSide and WIN_MIN_SIDE or WIN_MIN_TOP)
	mainConstraint.MaxSize = opt.MaxSize or (isSide and WIN_MAX_SIDE or WIN_MAX_TOP)
	local uiScale = Instance.new("UIScale", main)
	uiScale.Scale = win.baseScale

	local notifHolder = win.Make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 260, 1, -32), Parent = gui })
	local notifLayout = Instance.new("UIListLayout", notifHolder)
	notifLayout.VerticalAlignment, notifLayout.HorizontalAlignment, notifLayout.Padding = Enum.VerticalAlignment.Bottom, Enum.HorizontalAlignment.Right, UDim.new(0, 8)
	local notifScale = Instance.new("UIScale", notifHolder)
	notifScale.Scale = win.baseScale

	local topbar = corner(win.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), ZIndex = 5, Parent = main }, { BackgroundColor3 = "Secondary" }), 10)
	local titleRow = win.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 16, 0, 0), Parent = topbar })
	local trl = Instance.new("UIListLayout", titleRow); trl.FillDirection, trl.VerticalAlignment, trl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 10)
	win.Mkicon(opt.Icon, "Kvant", titleRow, UDim2.new(0, 20, 0, 20))
	win.Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -30, 1, 0), FontWeight = "Bold", Text = opt.Name or "Kvant", TextSize = T.Title, TextTruncate = Enum.TextTruncate.AtEnd, Parent = titleRow }, { TextColor3 = "Text" })

	local controls = win.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), Position = UDim2.new(1, -12, 0, 0), Parent = topbar })
	local ctrlList = Instance.new("UIListLayout", controls)
	ctrlList.FillDirection, ctrlList.VerticalAlignment, ctrlList.HorizontalAlignment, ctrlList.SortOrder, ctrlList.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, Enum.HorizontalAlignment.Right, Enum.SortOrder.LayoutOrder, UDim.new(0, 10)

	-- topbar buttons
	local searchBtn = win.MakeIcon(nil, "Search", { Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1, TextSize = T.Label, Visible = searchEnabled, LayoutOrder = 0, Parent = controls }, "Icon", true)
	local settingsBtn = win.MakeIcon(nil, "Settings", { Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1, TextSize = T.Label, LayoutOrder = 1, Parent = controls }, "Icon", true)
	local minBtn = win.MakeIcon(nil, "Minimize", { Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1, TextSize = T.Label, LayoutOrder = 2, Parent = controls }, "Icon", true)
	local closeBtn = win.MakeIcon(nil, "Close", { Size = UDim2.new(0, 22, 0, 22), BackgroundTransparency = 1, TextSize = T.Title, Visible = closeBtnDefault, LayoutOrder = 3, Parent = controls }, "Icon", true)
    for _, b in { searchBtn, settingsBtn, minBtn, closeBtn } do if b then win.HoverIcon(b) end end

    local defaultPillPos = UDim2.new(0.5, 0, 0.04, 0)
	makeDraggable(main, topbar, "_MainPos")
	local gripHit = win.Make("TextButton", { Size = UDim2.new(0, 64, 0, 22), BackgroundTransparency = 1, Parent = main })
	local grip = corner(win.Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 52, 0, 5), Parent = gripHit,
	}, { BackgroundColor3 = "Stroke" }), 3)

	win.OnHover(gripHit,
		function() win.Tween(grip, Motion.Fast, { BackgroundColor3 = Library._theme.Accent, Size = UDim2.new(0, 52, 0, 5) }) end,
		function() win.Tween(grip, Motion.Fast, { BackgroundColor3 = Library._theme.Stroke, Size = UDim2.new(0, 44, 0, 5) }) end
	)
	local function updateGrip()
		local screen = gui.AbsoluteSize
		local isHigh = main.AbsolutePosition.Y < (screen.Y * 0.5)
		gripHit.AnchorPoint = Vector2.new(0.5, isHigh and 0 or 1)
		gripHit.Position = UDim2.new(0.5, 0, isHigh and 1 or 0, isHigh and 4 or -4)
	end

	main:GetPropertyChangedSignal("Position"):Connect(updateGrip)
	makeDraggable(main, gripHit, "_MainPos")
	updateGrip()

	local isCirclePill = opt.PillCircle == true
	local pill
	if isCirclePill then
        pill = corner(win.Make("TextButton", { Visible = false, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.04, 0), Size = UDim2.new(0, 36, 0, 36), Parent = gui }, { BackgroundColor3 = "Secondary" }), 18)
        local pillIcon = win.MakeIcon(opt.PillIcon or opt.Icon, "Kvant", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 20, 0, 20), TextSize = T.Label, Parent = pill,
        }, "Icon", false, true)
        win.Stroke(pill, "Stroke", 0.6, pill, 0.2)
        local iconProp = win.secure and "TextColor3" or "ImageColor3"
        win.OnHover(pill, function() win.Tween(pillIcon, Motion.Fast, { [iconProp] = Library._theme.Accent }) end, function() win.Tween(pillIcon, Motion.Fast, { [iconProp] = Library._theme.Icon }) end)
	else
        pill = corner(win.Make("TextButton", { Visible = false, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.04, 0), Size = UDim2.new(0, 0, 0, 36), AutomaticSize = Enum.AutomaticSize.X, Parent = gui }, { BackgroundColor3 = "Secondary" }), 18)
        pad(pill, 14, 0)
        local pillConstraint = Instance.new("UISizeConstraint", pill); pillConstraint.MinSize, pillConstraint.MaxSize = Vector2.new(PILL_MIN_W, 36), Vector2.new(PILL_MAX_W, 36)
        local pillLayout = Instance.new("UIListLayout", pill)
        pillLayout.FillDirection, pillLayout.HorizontalAlignment, pillLayout.VerticalAlignment, pillLayout.Padding = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center, UDim.new(0, 8)
        local pillIcon = win.MakeIcon(opt.PillIcon or opt.Icon, "Kvant", {
            LayoutOrder = 1, Size = UDim2.new(0, 16, 0, 16), TextSize = T.Label, Parent = pill,
        }, "Icon", false, true)

        local pillLabel = win.Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = opt.Name or "Kvant", TextSize = T.Label, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = pill }, { TextColor3 = "Text" })
        local labelConstraint = Instance.new("UISizeConstraint", pillLabel); labelConstraint.MaxSize = Vector2.new(220, math.huge)
        win.Stroke(pill, "Stroke", 0.6, pill, 0.2)

        local iconProp = win.secure and "TextColor3" or "ImageColor3"
        win.OnHover(pill, function()
            win.Tween(pillLabel, Motion.Fast, { TextColor3 = Library._theme.Accent })
            if pillIcon then win.Tween(pillIcon, Motion.Fast, { [iconProp] = Library._theme.Accent }) end
        end, function()
            win.Tween(pillLabel, Motion.Fast, { TextColor3 = Library._theme.Text })
            if pillIcon then win.Tween(pillIcon, Motion.Fast, { [iconProp] = Library._theme.Icon }) end
        end)
    end

	makeDraggable(pill, nil, "_PillPos")
	-- Position saving
	win.RegConfig(win.KvantConfig, "_MainPos", { 0.5, 0, 0.5, 0 }, main, "Pos")
	win.RegConfig(win.KvantConfig, "_PillPos", { 0.5, 0, 0.04, 0 }, pill, "Pos")

	local tabHolder, pageHolder
	if isSide then
		tabHolder = corner(win.Make("ScrollingFrame", { Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(0.30, 0, 1, -44), ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = main }, { BackgroundColor3 = "Secondary" }), 10)
		win.StyleScroll(tabHolder, false); pad(tabHolder, 0, 10)
		local tabList = Instance.new("UIListLayout", tabHolder); tabList.SortOrder, tabList.HorizontalAlignment, tabList.Padding = Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Center, UDim.new(0, 6)
		win.Make("Frame", { Position = UDim2.new(0.30, 0, 0, 44), Size = UDim2.new(0, 1, 1, -44), Parent = main }, { BackgroundColor3 = "Stroke" })
		pageHolder = win.Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.30, 0, 0, 44), Size = UDim2.new(0.7, 0, 1, -44), Parent = main })
	else
		tabHolder = win.Make("ScrollingFrame", { BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 54), Size = UDim2.new(1, -32, 0, 46), ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, Parent = main })
		win.StyleScroll(tabHolder, true)
		local tabList = Instance.new("UIListLayout", tabHolder); tabList.FillDirection, tabList.VerticalAlignment, tabList.SortOrder, tabList.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, Enum.SortOrder.LayoutOrder, UDim.new(0, 8)
		pageHolder = win.Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 108), Size = UDim2.new(1, 0, 1, -102), Parent = main })
	end
	pad(pageHolder, 16, 12)

	local function toggleWindow()
        if win.isAnimating then return end
        win.minimized = not win.minimized
        setCursor(win.unlockCursor and not win.minimized)
        if win.reduceMotion then
            main.Visible, pill.Visible = not win.minimized, win.minimized
            return
        end
        win.isAnimating = true
        local curPos = main.Position
        if win.minimized then
            local t = TweenService:Create(main, Motion.Panel, { Position = UDim2.new(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, curPos.Y.Offset - 10) })
            t:Play()
            t.Completed:Once(function()
                main.Visible, main.Position = false, curPos
                local pPos = pill.Position
                pill.Position = UDim2.new(pPos.X.Scale, pPos.X.Offset, pPos.Y.Scale, pPos.Y.Offset - 8)
                pill.Visible = true
                TweenService:Create(pill, Motion.Panel, { Position = pPos }):Play()
                win.isAnimating = false
            end)
        else
            pill.Visible, main.Visible = false, true
            main.Position = UDim2.new(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, curPos.Y.Offset - 10)
            local t = TweenService:Create(main, Motion.Panel, { Position = curPos })
            t:Play()
            t.Completed:Once(function() win.isAnimating = false end)
        end
    end
	minBtn.Activated:Connect(toggleWindow)
	pill.Activated:Connect(function() if not dragMoved then toggleWindow() end end)

    local tabPages, tabBtns, tabLabels, tabIcons, tabActivators = {}, {}, {}, {}, {}
	local activeIndex, lastUserIndex, settingsIndex

	local searchEntries, searchByFirst = {}, {}
	function win.AddSearchEntry(name, kind, tabName, tabIdx, inst, expand)
		if not searchEnabled then return end
		local lower = string.lower(name)
		local idx = #searchEntries + 1
		searchEntries[idx] = { name = name, lower = lower, kind = kind, tabName = tabName, tabIdx = tabIdx, inst = inst, expand = expand }
		local first = string.sub(lower, 1, 1)
		local bucket = searchByFirst[first] or {}; searchByFirst[first] = bucket; bucket[#bucket + 1] = idx
	end
	if not searchEnabled then searchBtn = nil end

	local currentMatched, seenSearch = table.create(SEARCH_POOL), {}
	local function runSearch(q)
		table.clear(currentMatched); table.clear(seenSearch)
		if q == "" then return currentMatched, nil end
		local prefixMatch, count = nil, 0
		local bucket = searchByFirst[string.sub(q, 1, 1)]
		if bucket then
			for _, idx in bucket do
				if count >= SEARCH_POOL then break end
				local entry = searchEntries[idx]
				if entry and string.sub(entry.lower, 1, #q) == q then
					count += 1; currentMatched[count] = entry; seenSearch[entry] = true
					prefixMatch = prefixMatch or entry
				end
			end
		end
		if count < SEARCH_POOL then
			for _, entry in searchEntries do
				if count >= SEARCH_POOL then break end
				if not seenSearch[entry] and string.find(entry.lower, q, 1, true) then
					count += 1; currentMatched[count] = entry; seenSearch[entry] = true
				end
			end
		end
		return currentMatched, prefixMatch
	end

	local searchOverlay = win.Stroke(corner(win.Make("Frame", { Size = UDim2.new(1, -24, 0, SEARCH_BAR_H), Position = UDim2.new(0, 12, 0, 48), Visible = false, ZIndex = 30, Parent = main }, { BackgroundColor3 = "Secondary" }), 8), "Stroke", 0.4)
	local soStroke = searchOverlay:FindFirstChildOfClass("UIStroke")
	win.MakeIcon(nil, "Search", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 10, 0.5, -8), TextSize = T.Small, ZIndex = 31, Parent = searchOverlay }, "SubText")
	local searchCloseBtn = win.MakeIcon(nil, "Close", { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -26, 0.5, -8), TextSize = T.Body, BackgroundTransparency = 1, ZIndex = 32, Parent = searchOverlay }, "SubText", true)
    if searchCloseBtn then win.HoverIcon(searchCloseBtn) end

	local autocompleteLbl = win.Make("TextLabel", { Text = "", Size = UDim2.new(1, -56, 1, 0), Position = UDim2.new(0, 32, 0, 0), TextSize = T.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 31, Parent = searchOverlay }, { TextColor3 = "SubText" })
	local searchBox = win.Make("TextBox", { Text = "", Size = UDim2.new(1, -56, 1, 0), Position = UDim2.new(0, 32, 0, 0), PlaceholderText = "Search...", TextSize = T.Body, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, ZIndex = 32, Parent = searchOverlay }, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })

	local searchResults = win.Stroke(corner(win.Make("ScrollingFrame", { Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 6), Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 35, ClipsDescendants = true, Parent = searchOverlay }, { BackgroundColor3 = "Secondary" }), 8), "Stroke", 0.4)
	pad(searchResults, 6, 6); win.StyleScroll(searchResults, false)
	local srl = Instance.new("UIListLayout", searchResults); srl.SortOrder, srl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 4)

	local pooledResults, selectedResultIdx = {}, 0
	local function jumpToItem(item)
		searchOverlay.Visible, searchResults.Visible = false, false
		if item.tabIdx and tabActivators[item.tabIdx] then tabActivators[item.tabIdx]() end
		if item.expand then item.expand(true) end
		task.defer(function()
			if item.inst and item.inst.Parent then
				local p = tabPages[item.tabIdx]
				if p then p.CanvasPosition = Vector2.new(0, math.clamp(item.inst.AbsolutePosition.Y - p.AbsolutePosition.Y + p.CanvasPosition.Y - 12, 0, p.AbsoluteCanvasSize.Y)) end
				win.Tween(item.inst, Motion.Fast, { BackgroundColor3 = Library._theme.Accent })
				task.delay(0.2, function() if item.inst.Parent then win.Tween(item.inst, Motion.Normal, { BackgroundColor3 = Library._theme.Secondary }) end end)
			end
		end)
	end

	local function highlightSelected()
		for i = 1, SEARCH_POOL do
			local res = pooledResults[i]
			if res.btn.Visible then win.Tween(res.btn, Motion.Fast, { BackgroundColor3 = (i == selectedResultIdx) and Library._theme.Accent or Library._theme.Background }) end
		end
	end

	for i = 1, SEARCH_POOL do
		local btn = pad(corner(win.Make("TextButton", { Size = UDim2.new(1, 0, 0, 32), Visible = false, LayoutOrder = i, ZIndex = 36, Parent = searchResults }, { BackgroundColor3 = "Background" }), 6), 8, 0)
		local bl = Instance.new("UIListLayout", btn); bl.FillDirection, bl.VerticalAlignment, bl.HorizontalFlex, bl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, Enum.UIFlexAlignment.Fill, UDim.new(0, 6)
		local tagLbl = win.Make("TextLabel", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextSize = T.Small, LayoutOrder = 1, ZIndex = 37, Parent = btn }, { TextColor3 = "Accent" })
		Instance.new("UIFlexItem", tagLbl).FlexMode = Enum.UIFlexMode.None
		local nameLbl = win.Make("TextLabel", { Size = UDim2.new(0, 0, 1, 0), TextSize = T.Body, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 2, ZIndex = 37, Parent = btn }, { TextColor3 = "Text" })
		Instance.new("UIFlexItem", nameLbl).FlexMode = Enum.UIFlexMode.Fill
		local pathLbl = win.Make("TextLabel", { Size = UDim2.new(0, 60, 1, 0), TextSize = T.Small, TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = 3, ZIndex = 37, Parent = btn }, { TextColor3 = "SubText" })
		Instance.new("UIFlexItem", pathLbl).FlexMode = Enum.UIFlexMode.None
		pooledResults[i] = { btn = btn, tag = tagLbl, name = nameLbl, path = pathLbl, item = nil }

		win.OnHover(btn, function()
			if selectedResultIdx ~= i then win.Tween(btn, Motion.Fast, { BackgroundColor3 = Library._theme.Stroke }) end
		end, function()
			if selectedResultIdx ~= i then win.Tween(btn, Motion.Fast, { BackgroundColor3 = Library._theme.Background }) end
		end)
		btn.Activated:Connect(function() selectedResultIdx = i; if pooledResults[i].item then jumpToItem(pooledResults[i].item) end end)
	end

	local function updateSearch()
		local q = string.lower(searchBox.Text)
		selectedResultIdx = 0
		local matched, prefixMatch = runSearch(q)
		autocompleteLbl.Text = (q ~= "" and prefixMatch) and (searchBox.Text .. string.sub(prefixMatch.name, #q + 1)) or ""
		searchResults.Visible = q ~= "" and #matched > 0
		if searchResults.Visible then searchResults.Size = UDim2.new(1, 0, 0, #matched * 36 + 8) end
		for i = 1, SEARCH_POOL do
			local entry, res = matched[i], pooledResults[i]
			res.btn.Visible = entry ~= nil
			if entry then
				res.item = entry; res.tag.Text = "[" .. entry.kind .. "]"; res.name.Text = entry.name; res.path.Text = entry.tabName
				res.btn.BackgroundColor3 = Library._theme.Background
			else res.item = nil end
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(updateSearch)
	searchBox.Focused:Connect(function()
		if soStroke then win.Tween(soStroke, Motion.Fast, { Color = Library._theme.Accent, Transparency = 0 }) end
		if searchBox.Text ~= "" then updateSearch() end
	end)
	searchBox.FocusLost:Connect(function(enter)
		if soStroke then win.Tween(soStroke, Motion.Fast, { Color = Library._theme.Stroke, Transparency = 0.4 }) end
		if enter and searchOverlay.Visible then
			local target = (selectedResultIdx > 0 and currentMatched[selectedResultIdx]) or currentMatched[1]
			if target then jumpToItem(target) end
		end
	end)

	if searchBtn then
		searchBtn.Activated:Connect(function()
			searchOverlay.Visible = not searchOverlay.Visible
			if searchOverlay.Visible then searchBox:CaptureFocus(); updateSearch() else searchResults.Visible = false end
		end)
	end

	searchCloseBtn.Activated:Connect(function() searchBox.Text = ""; searchOverlay.Visible = false; searchResults.Visible = false end)
	conn(UserInputService.InputBegan, function(i)
		if searchOverlay.Visible and searchBox:IsFocused() then
			if i.KeyCode == Enum.KeyCode.Right and currentMatched[1] and searchBox.CursorPosition == #searchBox.Text + 1 then
				searchBox.Text = currentMatched[1].name; searchBox.CursorPosition = #searchBox.Text + 1
			elseif (i.KeyCode == Enum.KeyCode.Down or i.KeyCode == Enum.KeyCode.Up) and #currentMatched > 0 then
				selectedResultIdx = math.clamp(selectedResultIdx + (i.KeyCode == Enum.KeyCode.Down and 1 or -1), 0, #currentMatched)
				highlightSelected()
			elseif i.KeyCode == Enum.KeyCode.Escape then
				searchOverlay.Visible = false; searchResults.Visible = false
			end
		end
	end)

	local tooltip = pad(win.Stroke(corner(win.Make("TextLabel", { BackgroundTransparency = 0.1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(0, 0, 0, 0), Visible = false, ZIndex = 200, TextSize = T.Label, TextWrapped = true, Text = "", Parent = gui }, { BackgroundColor3 = "Secondary", TextColor3 = "Text" }), 6), "Stroke", 0.4), 8, 5)
	local tooltipConstraint = Instance.new("UISizeConstraint", tooltip); tooltipConstraint.MaxSize = Vector2.new(220, math.huge)
	local tooltipScale = Instance.new("UIScale", tooltip)
	tooltipScale.Scale = win.baseScale

	local function updateDockedPosition(inst)
		local pos, sz, vp = inst.AbsolutePosition, inst.AbsoluteSize, workspace.CurrentCamera.ViewportSize
		local scaledOffset = TOOLTIP_OFFSET * win.baseScale
		local tx = pos.X + sz.X + scaledOffset
		local flip = tx + (230 * win.baseScale) > vp.X
		tooltip.AnchorPoint = Vector2.new(flip and 1 or 0, 0.5)
		tooltip.Position = UDim2.fromOffset(flip and (pos.X - scaledOffset) or tx, pos.Y + sz.Y / 2)
	end

    function win.AttachTooltip(inst, initialText)
        local desc = { text = (initialText and initialText ~= "") and initialText or nil }
        function desc.set(t) desc.text = (t and t ~= "") and tostring(t) or nil end
        local hoverToken = 0
        inst.MouseEnter:Connect(function()
            if not desc.text or not win.hoverEffects then return end
            hoverToken += 1
            local cur = hoverToken
            task.delay(TOOLTIP_DELAY, function()
                if cur == hoverToken and desc.text then
                    tooltip.Text = desc.text
                    updateDockedPosition(inst)
                    tooltip.Visible = true
                end
            end)
        end)
        inst.MouseLeave:Connect(function()
            hoverToken += 1
            tooltip.Visible = false
        end)
        return desc
    end

	local window = {}
	function window:Status(statusOpt)
		statusOpt = statusOpt or {}
		local root = corner(win.Make("Frame", {
			Size = statusOpt.Size or UDim2.new(0, 190, 0, 0),
			Position = statusOpt.Position or UDim2.new(0, 24, 0.5, -80),
			BackgroundTransparency = statusOpt.Transparency or 0.15,
			AutomaticSize = Enum.AutomaticSize.Y,
			Active = true,
			Parent = gui,
		}, { BackgroundColor3 = "Secondary" }), 8)
		win.Stroke(root, "Stroke", 0.5)
		pad(root, 10, 8)

		local layout = Instance.new("UIListLayout", root)
		layout.SortOrder, layout.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 6)

		local header = win.Make("TextButton", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 0, Parent = root })
		local hl = Instance.new("UIListLayout", header)
		hl.FillDirection, hl.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center

		win.Make("TextLabel", { Size = UDim2.new(1, -20, 1, 0), FontWeight = "Bold", TextSize = T.Label, Text = statusOpt.Title or "Status", Parent = header }, { TextColor3 = "Text" })
		local chevron = win.MakeIcon(nil, "Dropdown", { Size = UDim2.new(0, 14, 0, 14), TextSize = T.Small, Parent = header }, "SubText")

		local content = win.Make("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 1, Parent = root })
		local cl = Instance.new("UIListLayout", content)
		cl.SortOrder, cl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 4)

		local collapsed = false
		header.Activated:Connect(function()
			if dragMoved then return end
			collapsed = not collapsed
			content.Visible = not collapsed
			if secure then
				chevron.Text = collapsed and TEXT_ICONS.Small_Right or TEXT_ICONS.Small_Down
			else
				win.Tween(chevron, Motion.Fast, { Rotation = collapsed and -90 or 0 })
			end
		end)
		makeDraggable(root, header)

		local rows = {}
		local handle = {}
		function handle:Set(key, value)
			local r = rows[key]
			if not r then
				local f = win.Make("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Parent = content })
				local kLbl = win.Make("TextLabel", { Size = UDim2.new(0.55, 0, 1, 0), TextSize = T.Body, TextTruncate = Enum.TextTruncate.AtEnd, Text = tostring(key), Parent = f }, { TextColor3 = "SubText" })
				local vLbl = win.Make("TextLabel", { Size = UDim2.new(0.45, 0, 1, 0), Position = UDim2.new(0.55, 0, 0, 0), FontWeight = "Bold", TextSize = T.Body, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = f }, { TextColor3 = "Accent" })
				r = { frame = f, valLbl = vLbl }
				rows[key] = r
			end
			r.valLbl.Text = tostring(value)
		end
		function handle:Get(key) return rows[key] and rows[key].valLbl.Text end
		function handle:Remove(key)
			if rows[key] then rows[key].frame:Destroy(); rows[key] = nil end
		end
		function handle:Clear()
			for _, r in rows do r.frame:Destroy() end
			table.clear(rows)
		end
		function handle:Content(builder)
			withScope(createContainer(content, {}, "", nil, win), builder)
		end
		function handle:Destroy() root:Destroy() end
		return handle
	end

	function window:Destroy()
		if isDev then for _, e in win.GameConfig do if e.kind == "Toggle" then pcall(ConfigOps.Toggle.set, e.state, false) end end end
		pcall(function() UserInputService.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None end)
		for i, w in Library._windows do
			if w == windowEntry then
				Library._windows[i] = Library._windows[#Library._windows]; Library._windows[#Library._windows] = nil; break
			end
		end
		for _, c in win.conns do c:Disconnect() end
		gui:Destroy()
	end
	closeBtn.Activated:Connect(function() window:Destroy() end)

	function window:Notify(text, duration, icon)
		if not win.notificationsEnabled then return end
		local n = pad(corner(win.Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = notifHolder }, { BackgroundColor3 = "Secondary" }), 8), 14, 10)
		local _, s = win.Stroke(n, "Stroke", 1)
		local nl = Instance.new("UIListLayout", n)
		nl.FillDirection, nl.VerticalAlignment, nl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 10)

		local iconImg
		if icon then
			iconImg = win.Mkicon(icon, "Kvant", n, UDim2.new(0, 20, 0, 20))
			iconImg.ImageTransparency = 1
		end

		local textWidth = 210 - (icon and 30 or 0)
		local isLong = isTextLong(text, T.Label, textWidth)
		local l = win.Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, icon and -30 or 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = T.Label, TextWrapped = true, TextTransparency = 1, TextXAlignment = isLong and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center, Text = text, Parent = n }, { TextColor3 = "Text" })

		win.Tween(n, Motion.Panel, { BackgroundTransparency = 0 })
		if s then win.Tween(s, Motion.Panel, { Transparency = 0 }) end
		if iconImg then win.Tween(iconImg, Motion.Panel, { ImageTransparency = 0 }) end
		win.Tween(l, Motion.Panel, { TextTransparency = 0 })
		task.delay(duration or NOTIFY_DEFAULT_DURATION, function()
			if not n.Parent then return end
			win.Tween(n, Motion.Normal, { BackgroundTransparency = 1 })
			if s then win.Tween(s, Motion.Normal, { Transparency = 1 }) end
			if iconImg then win.Tween(iconImg, Motion.Normal, { ImageTransparency = 1 }) end
			win.Tween(l, Motion.Normal, { TextTransparency = 1 })
			task.wait(0.2); n:Destroy()
		end)
	end

	local function createTab(tabName, tabIcon, registry, tabBuilder)
		if type(tabIcon) == "function" then tabBuilder, tabIcon = tabIcon, nil end
		local tabIndex, isSettings = #tabPages + 1, registry == win.KvantConfig
		local btn = pad(corner(win.Make("TextButton", {
			Size = isSide and UDim2.new(0.9, 0, 0, 36) or UDim2.new(0, 0, 0, 38),
			AutomaticSize = isSide and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
			LayoutOrder = tabIndex, Visible = not isSettings, Parent = tabHolder,
		}, { BackgroundColor3 = function(th) return activeIndex == tabIndex and th.Accent or th.Secondary end }), isSide and 7 or 19), isSide and 10 or 14, 0)

		local bl = Instance.new("UIListLayout", btn); bl.FillDirection, bl.VerticalAlignment, bl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8)
		local label = win.Make("TextLabel", { LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.X, Size = isSide and UDim2.new(1, -24, 1, 0) or UDim2.new(0, 0, 1, 0), Text = tabName, TextTruncate = Enum.TextTruncate.None, Parent = btn }, {
			TextColor3 = function(th) return activeIndex == tabIndex and th.AccentText or th.SubText end,
		})

        local tabIconInst = win.MakeIcon(tabIcon or (autoTabIcons and tabName or nil),isSettings and "Settings" or "Tab",{ LayoutOrder = 1, Size = UDim2.new(0, 16, 0, 16), TextSize = T.Label, Parent = btn },win.secure and function(th) return activeIndex == tabIndex and th.AccentText or th.SubText end or "Icon",false, true,isSide and label or nil, 8)
		local page = win.Make("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = pageHolder })
		win.StyleScroll(page, false)
		local pl = Instance.new("UIListLayout", page); pl.SortOrder, pl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 10)

		local function activate()
			activeIndex = tabIndex
			if not isSettings then lastUserIndex = tabIndex end
			for i = 1, #tabPages do
				local p, isCur = tabPages[i], (i == activeIndex)
				p.Visible = isCur
				if tabBtns[i].Visible then
					tabBtns[i].BackgroundColor3 = isCur and Library._theme.Accent or Library._theme.Secondary
					tabLabels[i].TextColor3 = isCur and Library._theme.AccentText or Library._theme.SubText
                    if win.secure and tabIcons[i] then
                        tabIcons[i].TextColor3 = isCur and Library._theme.AccentText or Library._theme.SubText
                    end
				end
			end
		end

		win.OnHover(btn, function()
			if activeIndex ~= tabIndex then
				win.Tween(btn, Motion.Fast, { BackgroundColor3 = Library._theme.Stroke })
				win.Tween(label, Motion.Fast, { TextColor3 = Library._theme.Text })
                if win.secure and tabIconInst then win.Tween(tabIconInst, Motion.Fast, { TextColor3 = Library._theme.Text }) end
			end
		end, function()
			if activeIndex ~= tabIndex then
				win.Tween(btn, Motion.Fast, { BackgroundColor3 = Library._theme.Secondary })
				win.Tween(label, Motion.Fast, { TextColor3 = Library._theme.SubText })
                if win.secure and tabIconInst then win.Tween(tabIconInst, Motion.Fast, { TextColor3 = Library._theme.SubText }) end
			end
		end)
		btn.Activated:Connect(activate)

        tabPages[tabIndex], tabBtns[tabIndex], tabLabels[tabIndex], tabIcons[tabIndex], tabActivators[tabIndex] = page, btn, label, tabIconInst, activate
		if isSettings then settingsIndex = tabIndex elseif not lastUserIndex then activate() end

		local tab = createContainer(page, registry, tabName, tabIndex, win)
		tab.Instance, tab.TabButton = page, btn
		if tabBuilder then withScope(tab, tabBuilder) end
		return tab
	end

	function window:Tab(title, icon, tabBuilder) return createTab(title, icon, win.GameConfig, tabBuilder) end

	local settingsTab = createTab("Settings", "Settings", win.KvantConfig)
	settingsTab:Section("Interface", false, function(s)
		s:Dropdown("Theme", { "Darker", "Dark", "Vesper", "Light", "SolarizedLight" }, savedTheme or "Darker", function(v) Library:SetTheme(v) end)
		local fontOpts = win.secure and { "Roboto", "Ubuntu" } or { "Inter", "Roboto", "Ubuntu" }
		s:Dropdown("Font", fontOpts, savedFont or "Roboto", function(v) Library:SetFont(v) end)
		s:Slider("UI Scale", 80, 120, math.floor(win.baseScale * 100 + 0.5), 1, function(v)
			win.baseScale = v / 100
			if not win.minimized then uiScale.Scale = win.baseScale end
			notifScale.Scale = win.baseScale
			tooltipScale.Scale = win.baseScale
		end)
			s:Toggle("Show Icons", win.iconsOn, function(st)
				win.iconsOn = st
            for i = #win.icons, 1, -1 do
                local ic = win.icons[i]
                if ic.inst and not ic.inst.Parent then
                    win.icons[i] = win.icons[#win.icons]; win.icons[#win.icons] = nil
                else
                    ic.sync()
                end
            end
            if not win.secure then
				for _, ind in win.indicators do ind.img.Visible, ind.txt.Visible = st, not st end
		end
        end)
		s:Toggle("Hover Animations", win.hoverEffects, function(st) win.hoverEffects = st end)
		s:Toggle("Close Button", closeBtnDefault, function(st) closeBtn.Visible = st end)
		s:Toggle("Reduce Motion", win.reduceMotion, function(st) win.reduceMotion = st end)
		s:Button("Reset Window", function() main.Position = defaultPosition end)
	end)

	settingsTab:Section("Controls", false, function(s)
		s:Keybind("Collapse Window", Enum.KeyCode.K, toggleWindow)
		s:Toggle("Unlock Cursor", win.unlockCursor, function(st)
			win.unlockCursor = st
			setCursor(st and not win.minimized)
		end)
	end)

	settingsTab:Section("Other", false, function(s)
		s:Toggle("Notifications", win.notificationsEnabled, function(st) win.notificationsEnabled = st end)
		if supported then
			s:Toggle("Autoload Settings", win.autoload, function(st) win.autoload = st end)
			s:Button("Reset Settings", function()
				for key, entry in win.GameConfig do pcall(ConfigOps[entry.kind].set, entry.state, entry.default); markDirty(win.GameConfig, key) end
				win.RequestSave(win.GameConfig)
			end)
		end
	end)

	settingsBtn.Activated:Connect(function()
		if lastUserIndex == nil then return end
		tabActivators[activeIndex == settingsIndex and lastUserIndex or settingsIndex]()
	end)

	if kvantData then applyConfig(win.KvantConfig, kvantData) end
	local function clampFrame(f, def)
		task.defer(function()
			local s, p, sz = gui.AbsoluteSize, f.AbsolutePosition, f.AbsoluteSize
			if (p.Y + sz.Y) < 36 or p.Y > s.Y - 36 or (p.X + sz.X) < 36 or p.X > s.X - 36 then
				f.Position = def
			end
		end)
	end

	clampFrame(main, defaultPosition); clampFrame(pill, defaultPillPos)
	local function loadGameConfig()
		if supported and win.autoload then
			ensureFolders()
			applyConfig(win.GameConfig, PERSIST.Game(GameId))
		end
	end

	if builder then withScope(window, builder); loadGameConfig() else task.defer(loadGameConfig) end
	return window
end

return Library