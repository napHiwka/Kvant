-- KvantUI - v0.8.0
-- github.com/napHiwka/Kvant - MIT License
-- You'll probably want to turn world wrap on, good luck.
--　　／l、
--　（ﾟ､ ｡ ７
--　⠀l、~ ヽﾉｼ
--　⠀じじと ）

-- TODO:
-- Feat: Slider -add isDragging bool.
-- Feat: Refactor API (something will break, sob).
-- Feat: Add custom assets (getcustomassets) to bypass detection, if supported.
-- Feat?: Cache the library and update it in the background from GitHub when needed. This should improve loading speed. Can be disabled in settings. But can be really inconsistent with big lib updates that breake API and all script loading.
-- Feat?: Custom frame/content support for things like timers, in-game labels, etc...
-- Feat?: Move the window along with the pill while it's minimized?

-- Environment & Services
local cloneref = cloneref or function(f) return f end
local TweenService: TweenService = cloneref(game:GetService("TweenService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService: HttpService = cloneref(game:GetService("HttpService"))

local supported = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
local GameId = tostring(cloneref(game).GameId)

-- Constants
local ASSET = { -- icons yoinked from github.com/Footagesus/Icons
	Kvant = "rbxassetid://73167696981648",
	Tab = "rbxassetid://97419752870313",
	Button = "rbxassetid://107150227368485",
	Toggle = "rbxassetid://90411952142550",
	Slider = "rbxassetid://135684703553372",
	Keybind = "rbxassetid://121474456068237",
	Text = "rbxassetid://133543553793564",
	Settings = "rbxassetid://80758916183665",
	Dropdown = "rbxassetid://134243273101015",
	Color = "rbxassetid://86350350950064",
	Input = "rbxassetid://107551944047171",
	Search = "rbxassetid://121018724060431",
	Minimize = "rbxassetid://118026365011536",
	Close = "rbxassetid://110786993356448",
}

local FONT_ASSETS = {
	Roboto = "rbxasset://fonts/families/Roboto.json",
	Ubuntu = "rbxasset://fonts/families/Ubuntu.json",
	Inter = "rbxassetid://12187365364",
	Icon = "rbxasset://luapackages/packages/_index/buildericons/buildericons/buildericons.json",
}

local TEXT_ICONS = {
	Small_Down = "chevron-small-down",
	Small_Up = "chevron-small-up",
	Large_Down = "chevron-large-down",
	Large_Right = "chevron-large-right",
}

-- Paths
local PERSIST = {
	Root = "Kvant",
	Games = "Kvant/games",
	Kvant = "Kvant/settings.json",
	Game = function(id) return "Kvant/games/" .. tostring(id) .. ".json" end,
}

-- Motion
local MOTION = { Fast = 0.08, Normal = 0.15, Panel = 0.18 }

local SEARCH_POOL = 6
local SAVE_DEBOUNCE = 0.5
local NOTIFY_DEFAULT_DURATION = 3
local TOOLTIP_DELAY = 0.12

local PILL_MIN_W, PILL_MAX_W = 110, 280
local TOOLTIP_OFFSET = 28
local SEARCH_BAR_H = 48

local WIN_SIZE_SIDE = UDim2.new(0.42, 0, 0.62, 0)
local WIN_SIZE_TOP = UDim2.new(0.3,  0, 0.6,  0)
local WIN_MIN_SIDE = Vector2.new(460, 400)
local WIN_MIN_TOP = Vector2.new(320, 400)
local WIN_MAX_SIDE = Vector2.new(620, 560)
local WIN_MAX_TOP = Vector2.new(420, 520)

-- Theme
local BuiltInThemes = {
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

local REQUIRED_THEME_KEYS = { "Background", "Secondary", "Accent", "Stroke", "Text", "SubText" }
local function isLight(c) return (0.299 * c.R + 0.587 * c.G + 0.114 * c.B) > 0.5 end

local function validateTheme(t)
	if type(t) ~= "table" then warn("[Kvant] Theme must be a table"); return false end
	local missing = {}
	for i = 1, #REQUIRED_THEME_KEYS do
		local k = REQUIRED_THEME_KEYS[i]
		if typeof(t[k]) ~= "Color3" then table.insert(missing, k) end
	end
	if #missing > 0 then
		warn("[Kvant] Missing Color3 fields in theme: " .. table.concat(missing, ", "))
		return false
	end
	return true
end

local function sanitizeTheme(t)
	local th = table.clone(t)
	local light = isLight(th.Background)
	if not th.Icon or isLight(th.Icon) == light then
		th.Icon = light and Color3.fromRGB(33, 33, 33) or Color3.fromRGB(245, 245, 247)
	end
	if not th.IconMuted or isLight(th.IconMuted) == light then
		th.IconMuted = light and Color3.fromRGB(130, 130, 130) or Color3.fromRGB(160, 160, 170)
	end
	if not th.AccentText then
		th.AccentText = isLight(th.Accent) and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(255, 255, 255)
	end
	return th
end

local Library = {
	CurrentTheme = nil,
	Themes = BuiltInThemes,
	_windows = setmetatable({}, { __mode = "v" }),
}
Library.CurrentTheme = sanitizeTheme(BuiltInThemes.Darker)

function Library:SetTheme(theme)
	local t = typeof(theme) == "table" and theme or Library.Themes[theme]
	if not t or not validateTheme(t) then return end
	Library.CurrentTheme = sanitizeTheme(t)
	for _, w in Library._windows do
		if w then w.applyTheme() end
	end
end

-- Font system
Library.Config = {
	Text = { Title = 18, Label = 17, Body = 16, Small = 15 },
	Fonts = {
		Bold = Font.new(FONT_ASSETS.Roboto, Enum.FontWeight.Bold),
		Medium = Font.new(FONT_ASSETS.Roboto, Enum.FontWeight.Medium),
		Regular = Font.new(FONT_ASSETS.Roboto, Enum.FontWeight.Regular),
		Icons = Font.new(FONT_ASSETS.Icon),
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
	for _, w in Library._windows do
		if w then w.applyFont() end
	end
end

-- Scope dispatch
local DeclarativeMethods = {
	"Tab", "Section", "Divider", "Text", "Button", "Toggle", "Slider", "Dropdown", "Keybind", "Input", "Color"
}

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
	for i = 1, #DeclarativeMethods do
		local name = DeclarativeMethods[i]
		target[name] = function(...)
			local scope = currentScope()
			if not scope or not scope[name] then
				error(string.format("[Kvant] '%s' must be called within an active scope (Window, Tab, or Section)", name), 2)
			end
			return scope[name](scope, ...)
		end
	end
end

registerDeclaratives(Library)
if type(getgenv) == "function" then pcall(registerDeclaratives, getgenv()) end
if type(_G) == "table" then pcall(registerDeclaratives, _G) end
pcall(function()
	if type(getfenv) == "function" then registerDeclaratives(getfenv(0)) end
end)

-- Serialization & persistence helpers
local function encodeConfig(data)
	local ok, result = pcall(HttpService.JSONEncode, HttpService, data)
	return ok and result or nil
end

local function decodeConfig(raw)
	local ok, result = pcall(HttpService.JSONDecode, HttpService, raw)
	return ok and type(result) == "table" and result or nil
end

local function ensureFolders()
	if not supported then return end
	if not isfolder(PERSIST.Root) then makefolder(PERSIST.Root) end
	if not isfolder(PERSIST.Games) then makefolder(PERSIST.Games) end
end

-- Numeric & text helpers
local function decimalsOf(n)
	if n == math.floor(n) then return 0 end
	local s = string.format("%.6f", n):gsub("0+$", ""):gsub("%.$", "")
	local dot = s:find("%.")
	return dot and (#s - dot) or 0
end

local function isTextLong(str, textSize, maxWidth)
	if not str or str == "" then return false end
	local w = 0
	for i = 1, #str do
		local b = string.byte(str, i)
		if b >= 65 and b <= 90 then w += textSize * 0.65 -- uppercase
		elseif b >= 97 and b <= 122 then w += textSize * 0.52 -- lowercase
		elseif b >= 48 and b <= 57 then w += textSize * 0.55 -- digits
		elseif b == 32 then w += textSize * 0.3 -- space
		else w += textSize * 0.5 end
	end
	return w > maxWidth
end

local function valuesEqual(a, b)
	if a == b then return true end
	if type(a) ~= "table" or type(b) ~= "table" then return false end
	for k, v in a do if b[k] ~= v then return false end end
	for k, v in b do if a[k] ~= v then return false end end
	return true
end

-- Handle prototypes
local ToggleHandle = {}; ToggleHandle.__index = ToggleHandle
local SliderHandle = {}; SliderHandle.__index = SliderHandle
local DropdownHandle = {}; DropdownHandle.__index = DropdownHandle
local KeybindHandle = {}; KeybindHandle.__index = KeybindHandle
local InputHandle = {}; InputHandle.__index = InputHandle
local ColorHandle = {}; ColorHandle.__index = ColorHandle
local ButtonHandle = {}; ButtonHandle.__index = ButtonHandle
local TextHandle = {}; TextHandle.__index = TextHandle

function ToggleHandle:Get() return self._get() end
function ToggleHandle:Set(val)
	if val == nil and type(self) == "boolean" then val = self end
	self._apply(val)
	self._requestSave(self._registry, self._key)
end

function SliderHandle:Get() return self._get() end
function SliderHandle:Set(v)
	if v == nil and type(self) == "number" then v = self end
	if type(v) == "number" then
		self._apply(v)
		self._requestSave(self._registry, self._key)
	end
end

function DropdownHandle:Get() return self._get() end
function DropdownHandle:Set(v)
	if v == nil and getmetatable(self) ~= DropdownHandle then v = self end
	self._set(v)
	self._requestSave(self._registry, self._key)
end
function DropdownHandle:Refresh(newOpts)
	if newOpts == nil and getmetatable(self) ~= DropdownHandle then newOpts = self end
	self._refreshOptions(newOpts)
end

function KeybindHandle:Get() return self._get() end
function KeybindHandle:Set(newKey)
	if newKey == nil and (typeof(self) == "EnumItem" or type(self) == "string") then newKey = self end
	self._setKey(newKey)
	self._requestSave(self._registry, self._key)
end

function InputHandle:Get() return self._get() end
function InputHandle:Set(val)
	if val == nil and type(self) == "string" then val = self end
	self._set(val)
	self._requestSave(self._registry, self._key)
end

function ColorHandle:Get() return self._get() end
function ColorHandle:Set(val)
	if val == nil and getmetatable(self) ~= ColorHandle then val = self end
	self._set(val)
	self._requestSave(self._registry, self._key)
end

function ButtonHandle:Fire() self._callback() end
function ButtonHandle:Lock(state) self._Lock(state) end
function ButtonHandle:Locked() return self._Locked() end

function ToggleHandle:Lock(state) self._Lock(state) end
function ToggleHandle:Locked() return self._Locked() end

function SliderHandle:Lock(state) self._Lock(state) end
function SliderHandle:Locked() return self._Locked() end

function DropdownHandle:Lock(state) self._Lock(state) end
function DropdownHandle:Locked() return self._Locked() end

function KeybindHandle:Lock(state) self._Lock(state) end
function KeybindHandle:Locked() return self._Locked() end

function InputHandle:Lock(state) self._Lock(state) end
function InputHandle:Locked() return self._Locked() end

function ColorHandle:Lock(state) self._Lock(state) end
function ColorHandle:Locked() return self._Locked() end

function TextHandle:Get() return self._contentLbl.Text end
function TextHandle:Set(str)
	if str == nil and type(self) == "string" then str = self end
	self._contentLbl.Text = tostring(str or "")
end
function TextHandle:SetTitle(str)
	if str == nil and type(self) == "string" then str = self end
	if self._titleLbl then self._titleLbl.Text = tostring(str or "") end
end

-- Window factory
function Library:CreateWindow(optOrName, sideTabs, customTheme, customSize, iconId)
	local builder = nil
	if type(optOrName) == "table" and type(optOrName.Builder) == "function" then
		builder = optOrName.Builder
	elseif type(sideTabs) == "function" then
		builder, sideTabs = sideTabs, false
	elseif type(customTheme) == "function" then
		builder, customTheme = customTheme, nil
	elseif type(iconId) == "function" then
		builder, iconId = iconId, nil
	end

	local opt = type(optOrName) == "table" and optOrName or {
		Name = optOrName or "Kvant",
		SideTabs = sideTabs,
		Theme = customTheme,
		Size = customSize,
		Icon = iconId,
	}

	-- registering on the caller's environment is probably risky in sandboxed executors
	if opt.RegisterGlobals ~= false then
		pcall(function()
			if type(getfenv) == "function" then registerDeclaratives(getfenv(2)) end
		end)
	end

	if opt.Theme then Library:SetTheme(opt.Theme) end
	local T, F, Motion = Library.Config.Text, Library.Config.Fonts, Library.Config.Motion
	local isSide = opt.SideTabs or false
	local isDev = opt.Dev and true or false

	-- Window mutable states
	local boundInstances = {}
	local themeBindings = setmetatable({}, { __mode = "k" })
	local fontRegistry = {}
	local icons, indicators, conns = {}, {}, {}
	local KvantConfig, GameConfig, savePending = {}, {}, {}
	local dirtyKeys, lastWritten = {}, {}
	local reduceMotion, iconsOn, notificationsEnabled, autoload = false, true, true, true
	local baseScale = 1
	local nid = 0
	local function getName() nid += 1; return string.format("%X%X", os.clock() * 1e4, nid) end
	local function conn(sig, fn) local c = sig:Connect(fn); table.insert(conns, c); return c end

	-- Per-instance theme binding
	local function bindTheme(inst, prop, key)
		local bindings = themeBindings[inst]
		if not bindings then
			bindings = {}
			themeBindings[inst] = bindings
			table.insert(boundInstances, inst)
		end
		table.insert(bindings, { prop, key })
		local val = type(key) == "function" and key(Library.CurrentTheme) or Library.CurrentTheme[key]
		if val then inst[prop] = val end
		return inst
	end

	local function bindFont(inst, weight)
		table.insert(fontRegistry, { inst = inst, weight = weight })
		inst.FontFace = F[weight] or F.Regular
		return inst
	end

	local function applyTheme()
		for i = #boundInstances, 1, -1 do
			local inst = boundInstances[i]
			if inst.Parent then
				local bindings = themeBindings[inst]
				for j = 1, #bindings do
					local prop, key = bindings[j][1], bindings[j][2]
					local val = type(key) == "function" and key(Library.CurrentTheme) or Library.CurrentTheme[key]
					if val then inst[prop] = val end
				end
			else
				themeBindings[inst] = nil
				local n = #boundInstances
				boundInstances[i] = boundInstances[n]
				boundInstances[n] = nil
			end
		end
	end

	local function applyFont()
		for i = #fontRegistry, 1, -1 do
			local e = fontRegistry[i]
			if e.inst.Parent then
				e.inst.FontFace = F[e.weight] or F.Regular
			else
				local n = #fontRegistry
				fontRegistry[i] = fontRegistry[n]
				fontRegistry[n] = nil
			end
		end
	end

	local windowEntry = { applyTheme = applyTheme, applyFont = applyFont }
	table.insert(Library._windows, windowEntry)

	-- Make & Defaults
	local Defaults = {
		Frame = { BorderSizePixel = 0 },
		ScrollingFrame = { BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0) },
		TextLabel = { BackgroundTransparency = 1, BorderSizePixel = 0, FontFace = F.Medium, TextSize = T.Label, TextXAlignment = Enum.TextXAlignment.Left },
		TextButton = { BorderSizePixel = 0, AutoButtonColor = false, Text = "" },
		TextBox = { BorderSizePixel = 0, ClearTextOnFocus = false, FontFace = F.Medium, TextSize = T.Body },
		ImageLabel = { BackgroundTransparency = 1, BorderSizePixel = 0 },
		ImageButton = { BackgroundTransparency = 1, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Fit },
	}

	local function Make(class, props, themeBinds)
		local inst = Instance.new(class)
		inst.Name = getName()
		local d = Defaults[class]
		if d then for k, v in d do inst[k] = v end end
		for k, v in props do if k ~= "Parent" and k ~= "FontWeight" then inst[k] = v end end
		if themeBinds then
			for prop, key in themeBinds do bindTheme(inst, prop, key) end
		end
		if (class == "TextLabel" or class == "TextButton" or class == "TextBox") and inst.FontFace ~= F.Icons then
			local w = props and props.FontWeight or (inst.FontFace == F.Bold and "Bold" or "Medium")
			bindFont(inst, w)
		end
		if props and props.Parent then inst.Parent = props.Parent end
		return inst
	end

	-- GUI helpers
	local function corner(p, r) local c = Instance.new("UICorner", p); c.CornerRadius = UDim.new(0, r or 8); return c end
	local function pad(p, x, y) local pi = Instance.new("UIPadding", p); pi.PaddingLeft, pi.PaddingRight = UDim.new(0, x), UDim.new(0, x); pi.PaddingTop, pi.PaddingBottom = UDim.new(0, y or x), UDim.new(0, y or x); return pi end
	local function stroke(p, colKey, trans) local s = Instance.new("UIStroke", p); s.Transparency = trans or 0; bindTheme(s, "Color", colKey or "Stroke"); return s end

	-- Motion & connection helpers
	local function tw(inst, info, props)
		if reduceMotion then
			for k, v in props do inst[k] = v end
		else
			TweenService:Create(inst, info, props):Play()
		end
	end

	local function twProp(inst, info, prop, value)
		if reduceMotion then
			inst[prop] = value
		else
			TweenService:Create(inst, info, { [prop] = value }):Play()
		end
	end

	local function hover(btn, target, enterProps, leaveProps)
		btn.MouseEnter:Connect(function() tw(target, Motion.Fast, typeof(enterProps) == "function" and enterProps() or enterProps) end)
		btn.MouseLeave:Connect(function() tw(target, Motion.Fast, typeof(leaveProps) == "function" and leaveProps() or leaveProps) end)
	end

	local function hoverColor(btn, target, prop, enterKey, leaveKey)
		btn.MouseEnter:Connect(function() twProp(target, Motion.Fast, prop, Library.CurrentTheme[enterKey]) end)
		btn.MouseLeave:Connect(function() twProp(target, Motion.Fast, prop, Library.CurrentTheme[leaveKey]) end)
	end

	local function mkicon(id, kind, parent, size, isMuted)
		local imgId = id == nil and ASSET[kind] or id
		if not imgId then return end
		local img = Make("ImageLabel", { LayoutOrder = 1, Size = size, Image = imgId, Visible = iconsOn, Parent = parent }, {
			ImageColor3 = isMuted and "IconMuted" or "Icon"
		})
		table.insert(icons, { inst = img, muted = isMuted or false })
		return img
	end

	local function newIndicator(parent, isDropdown)
		local holder = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 14, 0, 14), AnchorPoint = isDropdown and Vector2.new(1, 0.5) or Vector2.new(0.5, 0.5), Position = isDropdown and UDim2.new(1, -7, 0.5, 0) or UDim2.new(0.5, 0, 0.5, 0), Parent = parent })
		local img = Make("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 12, 0, 12), Image = ASSET.Dropdown, Visible = iconsOn, Parent = holder }, { ImageColor3 = "SubText" })
		local txt = Make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 1, 0), FontFace = F.Icons, Text = "", TextSize = T.Small, TextXAlignment = Enum.TextXAlignment.Center, Visible = not iconsOn, Parent = holder }, { TextColor3 = "SubText" })
		local ind = { img = img, txt = txt, isDropdown = isDropdown }
		local function setOpen(open)
			if isDropdown then
				tw(img, Motion.Normal, { Rotation = open and 180 or 0 })
				txt.Text = open and TEXT_ICONS.Small_Up or TEXT_ICONS.Small_Down
			else
				tw(img, Motion.Normal, { Rotation = open and 0 or -90 })
				txt.Text = open and TEXT_ICONS.Large_Down or TEXT_ICONS.Large_Right
			end
		end
		setOpen(false)
		table.insert(indicators, ind)
		return holder, setOpen
	end

	local function styleScroll(f, horiz)
		f.ScrollBarThickness = 3
		bindTheme(f, "ScrollBarImageColor3", "SubText")
		f.ScrollBarImageTransparency = 0.25
		if horiz then f.HorizontalScrollBarInset = Enum.ScrollBarInset.Always else f.VerticalScrollBarInset = Enum.ScrollBarInset.Always end
	end

	-- Lock
	local function addLock(f)
		local padInst = f:FindFirstChildOfClass("UIPadding") -- Padding fix
		local pl = padInst and padInst.PaddingLeft.Offset or 0
		local pr = padInst and padInst.PaddingRight.Offset or 0
		local pt = padInst and padInst.PaddingTop.Offset or 0
		local pb = padInst and padInst.PaddingBottom.Offset or 0
		local fullPos = UDim2.new(0, -pl, 0, -pt)
    	local fullSize = UDim2.new(1, pl + pr, 1, pt + pb)

		local overlay = Make("Frame", { Size = fullSize,Position = fullPos, BackgroundTransparency = 1, Visible = false, ZIndex = 90, Parent = f }, { BackgroundColor3 = "Background" })
		corner(overlay, 8)
		local blocker = Make("TextButton", { Size = fullSize,Position = fullPos, BackgroundTransparency = 1, Text = "", Active = false, Visible = false, ZIndex = 91, Parent = f })
		local locked = false
		local function Lock(state)
			locked = state and true or false
			overlay.Visible = locked
			blocker.Visible = locked
			blocker.Active = locked
			tw(overlay, Motion.Normal, { BackgroundTransparency = locked and 0.5 or 1 })
		end
		local function Locked() return locked end
		return Lock, Locked
	end

	-- Config registry helpers
	local function regConfig(registry, key, default, getter, setter, kind)
		registry[key] = { default = default, get = getter, set = setter, kind = kind }
	end

	local function markDirty(registry, key)
		local d = dirtyKeys[registry]
		if not d then d = {}; dirtyKeys[registry] = d end
		d[key] = true
	end

	local function flushSave(registry)
		savePending[registry] = nil
		local dirty = dirtyKeys[registry]
		if not dirty then return end
		local snapshot = lastWritten[registry]
		if not snapshot then snapshot = {}; lastWritten[registry] = snapshot end
		local changed = false
		for k in dirty do
			local entry = registry[k]
			if entry then
				local ok, res = pcall(entry.get)
				if ok and not valuesEqual(snapshot[k], res) then
					snapshot[k] = res
					changed = true
				end
			end
		end
		table.clear(dirty)
		if changed then
			ensureFolders()
			local encoded = encodeConfig(snapshot)
			if encoded then
				pcall(writefile, registry == KvantConfig and PERSIST.Kvant or PERSIST.Game(GameId), encoded)
			end
		end
	end

	local function requestSave(registry, key)
		if key then markDirty(registry, key) end
		if not supported or savePending[registry] then return end
		savePending[registry] = true
		task.delay(SAVE_DEBOUNCE, function() flushSave(registry) end)
	end

	local function applyConfig(registry, path)
		if not supported or not isfile(path) then return end
		local ok, raw = pcall(readfile, path)
		if not ok then return end
		local decoded = decodeConfig(raw)
		if not decoded then return end
		for k, entry in registry do
			if decoded[k] ~= nil then pcall(entry.set, decoded[k]) end
		end
		lastWritten[registry] = decoded
	end

	-- Shared drag/slider/colorpicker claimant
	local activeMove, activeMoveOwner, activeMoveEnd, dragMoved = nil, nil, nil, false
	local function claimMove(owner, fn, onEnd)
		if activeMove == nil or activeMoveOwner == owner then
			activeMove = fn
			activeMoveOwner = owner
			activeMoveEnd = onEnd
		end
	end

	conn(UserInputService.InputChanged, function(i)
		if activeMove and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			activeMove(i.Position)
		end
	end)
	conn(UserInputService.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			if activeMoveEnd then activeMoveEnd() end
			activeMove = nil
			activeMoveOwner = nil
			activeMoveEnd = nil
			dragMoved = false
		end
	end)

	local function makeDraggable(frame, handle)
		handle = handle or frame
		handle.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				local sx, sy = i.Position.X, i.Position.Y
				local ox, oy = frame.Position.X.Offset, frame.Position.Y.Offset
				dragMoved = false
				claimMove(frame, function(pos)
					if math.abs(pos.X - sx) > 3 or math.abs(pos.Y - sy) > 3 then dragMoved = true end
					frame.Position = UDim2.new(frame.Position.X.Scale, ox + (pos.X - sx), frame.Position.Y.Scale, oy + (pos.Y - sy))
				end)
			end
		end)
	end

	-- Root Interface
	local gui = Make("ScreenGui", { ResetOnSpawn = false, Parent = gethui and gethui() or cloneref(game:FindFirstChild("CoreGui")) or cloneref(game:GetService("Players")).LocalPlayer:WaitForChild("PlayerGui") })
	local winSize = opt.Size or (isSide and WIN_SIZE_SIDE or WIN_SIZE_TOP)
	local main = Make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = winSize, Active = true, ClipsDescendants = true, Parent = gui }, { BackgroundColor3 = "Background" })
	local defaultPosition = main.Position
	corner(main, 10)
	stroke(main, "Stroke")

	local mainConstraint = Instance.new("UISizeConstraint", main)
	mainConstraint.MinSize = opt.MinSize or (isSide and WIN_MIN_SIDE or WIN_MIN_TOP)
	mainConstraint.MaxSize = opt.MaxSize or (isSide and WIN_MAX_SIDE or WIN_MAX_TOP)
	local uiScale = Instance.new("UIScale", main)

	-- Notifications
	local notifHolder = Make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 260, 1, -32), Parent = gui })
	local notifLayout = Instance.new("UIListLayout", notifHolder)
	notifLayout.VerticalAlignment, notifLayout.HorizontalAlignment, notifLayout.Padding = Enum.VerticalAlignment.Bottom, Enum.HorizontalAlignment.Right, UDim.new(0, 8)

	-- Topbar & Controls
	local topbar = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), ZIndex = 5, Parent = main }, { BackgroundColor3 = "Secondary" })
	corner(topbar, 10)

	local titleRow = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 16, 0, 0), Parent = topbar })
	local trl = Instance.new("UIListLayout", titleRow)
	trl.FillDirection, trl.VerticalAlignment, trl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 10)

	mkicon(opt.Icon, "Kvant", titleRow, UDim2.new(0, 20, 0, 20))
	Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -30, 1, 0), FontWeight = "Bold", Text = opt.Name or "Kvant", TextSize = T.Title, TextTruncate = Enum.TextTruncate.AtEnd, Parent = titleRow }, { TextColor3 = "Text" })

	local controls = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), Position = UDim2.new(1, -12, 0, 0), Parent = topbar })
	local ctrlList = Instance.new("UIListLayout", controls)
	ctrlList.FillDirection, ctrlList.VerticalAlignment, ctrlList.HorizontalAlignment, ctrlList.SortOrder, ctrlList.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, Enum.HorizontalAlignment.Right, Enum.SortOrder.LayoutOrder, UDim.new(0, 10)

	local searchBtn = Make("ImageButton", { Size = UDim2.new(0, 20, 0, 20), Image = ASSET.Search, LayoutOrder = 0, Parent = controls }, { ImageColor3 = "Icon" })
	local settingsBtn = Make("ImageButton", { Size = UDim2.new(0, 20, 0, 20), Image = ASSET.Settings, LayoutOrder = 1, Parent = controls }, { ImageColor3 = "Icon" })
	local minBtn = Make("ImageButton", { Size = UDim2.new(0, 20, 0, 20), Image = ASSET.Minimize, LayoutOrder = 2, Parent = controls }, { ImageColor3 = "Icon" })
	local closeBtn = Make("ImageButton", { Size = UDim2.new(0, 22, 0, 22), Image = ASSET.Close, Visible = false, LayoutOrder = 3, Parent = controls }, { ImageColor3 = "Icon" })

	local ctrlButtons = { searchBtn, settingsBtn, minBtn, closeBtn }
	for i = 1, #ctrlButtons do
		local btn = ctrlButtons[i]
		hoverColor(btn, btn, "ImageColor3", "Accent", "Icon")
	end
	makeDraggable(main, topbar)

	-- Minimized Pill
	local pill = Make("TextButton", { Visible = false, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.04, 0), Size = UDim2.new(0, 0, 0, 36), AutomaticSize = Enum.AutomaticSize.X, Parent = gui }, { BackgroundColor3 = "Secondary" })
	corner(pill, 18)
	pad(pill, 16, 0)
	local pillConstraint = Instance.new("UISizeConstraint", pill)
	pillConstraint.MinSize, pillConstraint.MaxSize = Vector2.new(PILL_MIN_W, 36), Vector2.new(PILL_MAX_W, 36)

	local layout = Instance.new("UIListLayout", pill)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	local label = Make("TextLabel", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = opt.Name or "Kvant", TextSize = T.Label, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, Parent = pill }, { TextColor3 = "Text" })
	local labelConstraint = Instance.new("UISizeConstraint", label)
	labelConstraint.MaxSize = Vector2.new(248, math.huge)
	local pillStroke = stroke(pill, "Stroke")
	hoverColor(pill, pillStroke, "Color", "Accent", "Stroke")
	makeDraggable(pill)

	-- Window Layout Containers
	local tabHolder, pageHolder
	if isSide then
		tabHolder = Make("ScrollingFrame", { Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(0.30, 0, 1, -44), ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = main }, { BackgroundColor3 = "Secondary" })
		corner(tabHolder, 10)
		styleScroll(tabHolder, false)
		pad(tabHolder, 0, 10)

		local tabList = Instance.new("UIListLayout", tabHolder)
		tabList.SortOrder, tabList.HorizontalAlignment, tabList.Padding = Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Center, UDim.new(0, 6)

		Make("Frame", { Position = UDim2.new(0.30, 0, 0, 44), Size = UDim2.new(0, 1, 1, -44), Parent = main }, { BackgroundColor3 = "Stroke" })
		pageHolder = Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.30, 0, 0, 44), Size = UDim2.new(0.7, 0, 1, -44), Parent = main })
	else
		tabHolder = Make("ScrollingFrame", { BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 54), Size = UDim2.new(1, -32, 0, 46), ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, Parent = main })
		styleScroll(tabHolder, true)

		local tabList = Instance.new("UIListLayout", tabHolder)
		tabList.FillDirection, tabList.VerticalAlignment, tabList.SortOrder, tabList.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, Enum.SortOrder.LayoutOrder, UDim.new(0, 8)
		pageHolder = Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 108), Size = UDim2.new(1, 0, 1, -102), Parent = main })
	end
	pad(pageHolder, 16, 12)

	-- Window Behaviors & Controls
	local minimized, unlockCursor, savedMouseBehavior, isAnimating = false, false, nil, false
	local virtualCursor = Make("ImageLabel", { Size = UDim2.new(0, 18, 0, 18), Image = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png", BackgroundTransparency = 1, ZIndex = 1000000, Visible = false, Parent = gui }, { ImageColor3 = "Text" })

	local function applyCursorState()
		if unlockCursor and not minimized then
			savedMouseBehavior = savedMouseBehavior or UserInputService.MouseBehavior
			task.spawn(function()
				while unlockCursor and not minimized do
					local isHoldingRmb = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
					if isHoldingRmb then
						UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
						virtualCursor.Visible = false
					else
						UserInputService.MouseBehavior = Enum.MouseBehavior.Default
						UserInputService.MouseIconEnabled = true
						local isNativeHidden = not UserInputService.MouseIconEnabled
						virtualCursor.Visible = isNativeHidden
						if isNativeHidden then
							local mLoc = UserInputService:GetMouseLocation()
							virtualCursor.Position = UDim2.new(0, mLoc.X, 0, mLoc.Y)
						end
					end
					task.wait()
				end
				virtualCursor.Visible = false
				if savedMouseBehavior then
					UserInputService.MouseBehavior = savedMouseBehavior
					savedMouseBehavior = nil
				end
			end)
		else
			virtualCursor.Visible = false
			if savedMouseBehavior then
				UserInputService.MouseBehavior = savedMouseBehavior
				savedMouseBehavior = nil
			end
		end
	end

	local function toggleWindow()
		if isAnimating then return end
		minimized = not minimized
		local curPos = main.Position
		if minimized then
			if reduceMotion then
				main.Visible, pill.Visible = false, true
			else
				isAnimating = true
				local offPos = UDim2.new(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, curPos.Y.Offset - 8)
				local t = TweenService:Create(main, Motion.Fast, { Position = offPos })
				local ts = TweenService:Create(uiScale, Motion.Fast, { Scale = baseScale * 0.96 })
				t:Play(); ts:Play()
				t.Completed:Once(function()
					if minimized then main.Visible, pill.Visible = false, true end
					main.Position, uiScale.Scale = curPos, baseScale
					isAnimating = false
				end)
			end
		else
			pill.Visible = false
			main.Visible = true
			if reduceMotion then
				uiScale.Scale = baseScale
			else
				isAnimating = true
				main.Position = UDim2.new(curPos.X.Scale, curPos.X.Offset, curPos.Y.Scale, curPos.Y.Offset - 8)
				uiScale.Scale = baseScale * 0.96
				local t = TweenService:Create(main, Motion.Fast, { Position = curPos })
				local ts = TweenService:Create(uiScale, Motion.Fast, { Scale = baseScale })
				t:Play(); ts:Play()
				t.Completed:Once(function() isAnimating = false end)
			end
		end
		applyCursorState()
	end
	minBtn.Activated:Connect(toggleWindow)
	pill.Activated:Connect(function() if not dragMoved then toggleWindow() end end)

	local tabPages, tabBtns, tabLabels, tabActivators = {}, {}, {}, {}
	local activeIndex, lastUserIndex, settingsIndex = nil, nil, nil

	-- Search System
	local searchEntries = {} -- array of { name, lower, kind, tabName, tabIdx, inst, expand }
	local searchByFirst = {} -- [firstChar] = array of indices into searchEntries

	local function addSearchEntry(name, kind, tabName, tabIdx, inst, expand)
		local lower = string.lower(name)
		local idx = #searchEntries + 1
		searchEntries[idx] = { name = name, lower = lower, kind = kind, tabName = tabName, tabIdx = tabIdx, inst = inst, expand = expand }
		local first = string.sub(lower, 1, 1)
		local bucket = searchByFirst[first]
		if not bucket then bucket = {}; searchByFirst[first] = bucket end
		bucket[#bucket + 1] = idx
	end

	local currentMatched = table.create(SEARCH_POOL)
	local function runSearch(q)
		table.clear(currentMatched)
		if q == "" then return currentMatched, nil end
		local prefixMatch, count, seen = nil, 0, {}

		local bucket = searchByFirst[string.sub(q, 1, 1)]
		if bucket then
			for i = 1, #bucket do
				if count >= SEARCH_POOL then break end
				local entry = searchEntries[bucket[i]]
				if entry and string.sub(entry.lower, 1, #q) == q then
					count += 1
					currentMatched[count] = entry
					seen[entry] = true
					if not prefixMatch then prefixMatch = entry end
				end
			end
		end

		if count < SEARCH_POOL then
			for i = 1, #searchEntries do
				if count >= SEARCH_POOL then break end
				local entry = searchEntries[i]
				if not seen[entry] and string.find(entry.lower, q, 1, true) then
					count += 1
					currentMatched[count] = entry
					seen[entry] = true
				end
			end
		end

		return currentMatched, prefixMatch
	end

	local searchOverlay = Make("Frame", { Size = UDim2.new(1, -24, 0, SEARCH_BAR_H), Position = UDim2.new(0, 12, 0, 48), Visible = false, ZIndex = 30, Parent = main }, { BackgroundColor3 = "Secondary" })
	corner(searchOverlay, 8)
	stroke(searchOverlay, "Stroke", 0.4)
	Make("ImageLabel", { Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(0, 10, 0.5, -8), Image = ASSET.Search, ZIndex = 31, Parent = searchOverlay }, { ImageColor3 = "SubText" })
	local autocompleteLbl = Make("TextLabel", { Size = UDim2.new(1, -56, 1, 0), Position = UDim2.new(0, 32, 0, 0), Text = "", TextSize = T.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 31, Parent = searchOverlay }, { TextColor3 = "SubText" })
	local searchBox = Make("TextBox", { Size = UDim2.new(1, -56, 1, 0), Position = UDim2.new(0, 32, 0, 0), Text = "", PlaceholderText = "Search elements...", TextSize = T.Body, TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, ZIndex = 32, Parent = searchOverlay }, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })
	local searchCloseBtn = Make("ImageButton", { Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -26, 0.5, -8), Image = ASSET.Close, BackgroundTransparency = 1, ZIndex = 32, Parent = searchOverlay }, { ImageColor3 = "SubText" })
	hoverColor(searchCloseBtn, searchCloseBtn, "ImageColor3", "Accent", "SubText")

	local searchResults = Make("ScrollingFrame", { Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 6), Visible = false, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 35, ClipsDescendants = true, Parent = searchOverlay }, { BackgroundColor3 = "Secondary" })
	corner(searchResults, 8)
	stroke(searchResults, "Stroke", 0.4)
	pad(searchResults, 6, 6)
	styleScroll(searchResults, false)
	local srl = Instance.new("UIListLayout", searchResults); srl.SortOrder = Enum.SortOrder.LayoutOrder; srl.Padding = UDim.new(0, 4)

	local pooledResults = {}
	local selectedResultIdx = 0

	local function jumpToItem(item)
		searchOverlay.Visible = false
		searchResults.Visible = false
		if item.tabIdx and tabActivators[item.tabIdx] then tabActivators[item.tabIdx]() end
		if item.expand then item.expand(true) end
		task.defer(function()
			if item.inst and item.inst.Parent then
				local p = tabPages[item.tabIdx]
				if p then
					local relY = item.inst.AbsolutePosition.Y - p.AbsolutePosition.Y + p.CanvasPosition.Y
					p.CanvasPosition = Vector2.new(0, math.clamp(relY - 12, 0, p.AbsoluteCanvasSize.Y))
				end
				tw(item.inst, Motion.Fast, { BackgroundColor3 = Library.CurrentTheme.Accent })
				task.delay(0.2, function()
					if item.inst.Parent then tw(item.inst, Motion.Normal, { BackgroundColor3 = Library.CurrentTheme.Secondary }) end
				end)
			end
		end)
	end

	local function highlightSelected()
		for i = 1, SEARCH_POOL do
			local res = pooledResults[i]
			if res.btn.Visible then
				twProp(res.btn, Motion.Fast, "BackgroundColor3", (i == selectedResultIdx) and Library.CurrentTheme.Accent or Library.CurrentTheme.Background)
			end
		end
	end

	for i = 1, SEARCH_POOL do
		local btn = Make("TextButton", { Size = UDim2.new(1, 0, 0, 32), Visible = false, LayoutOrder = i, ZIndex = 36, Parent = searchResults }, { BackgroundColor3 = "Background" })
		corner(btn, 6)
		pad(btn, 8, 0)
		local bl = Instance.new("UIListLayout", btn); bl.FillDirection = Enum.FillDirection.Horizontal; bl.VerticalAlignment = Enum.VerticalAlignment.Center; bl.HorizontalFlex = Enum.UIFlexAlignment.Fill; bl.Padding = UDim.new(0, 6)
		local tagLbl = Make("TextLabel", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = "", TextSize = T.Small, LayoutOrder = 1, ZIndex = 37, Parent = btn }, { TextColor3 = "Accent" })
		Instance.new("UIFlexItem", tagLbl).FlexMode = Enum.UIFlexMode.None
		local nameLbl = Make("TextLabel", { Size = UDim2.new(0, 0, 1, 0), Text = "", TextSize = T.Body, TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 2, ZIndex = 37, Parent = btn }, { TextColor3 = "Text" })
		Instance.new("UIFlexItem", nameLbl).FlexMode = Enum.UIFlexMode.Fill
		local pathLbl = Make("TextLabel", { Size = UDim2.new(0, 60, 1, 0), Text = "", TextSize = T.Small, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.None, LayoutOrder = 3, ZIndex = 37, Parent = btn }, { TextColor3 = "SubText" })
		Instance.new("UIFlexItem", pathLbl).FlexMode = Enum.UIFlexMode.None
		pooledResults[i] = { btn = btn, tag = tagLbl, name = nameLbl, path = pathLbl, item = nil }
		hoverColor(btn, btn, "BackgroundColor3", "Accent", "Background")
		btn.Activated:Connect(function()
			selectedResultIdx = i
			if pooledResults[i].item then jumpToItem(pooledResults[i].item) end
		end)
	end

	local function updateSearch()
		local q = string.lower(searchBox.Text)
		selectedResultIdx = 0
		local matched, prefixMatch = runSearch(q)

		if q == "" then
			autocompleteLbl.Text = ""
			searchResults.Visible = false
			for i = 1, SEARCH_POOL do pooledResults[i].btn.Visible = false end
			return
		end

		autocompleteLbl.Text = prefixMatch and (searchBox.Text .. string.sub(prefixMatch.name, #q + 1)) or ""

		local count = #matched
		if count > 0 then
			searchResults.Visible = true
			searchResults.Size = UDim2.new(1, 0, 0, count * 36 + 8)
			for i = 1, SEARCH_POOL do
				local entry, res = matched[i], pooledResults[i]
				if entry then
					res.item = entry
					res.tag.Text = "[" .. entry.kind .. "]"
					res.name.Text = entry.name
					res.path.Text = entry.tabName
					res.btn.Visible = true
					res.btn.BackgroundColor3 = Library.CurrentTheme.Background
				else
					res.item = nil
					res.btn.Visible = false
				end
			end
		else
			searchResults.Visible = false
			for i = 1, SEARCH_POOL do pooledResults[i].btn.Visible = false end
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(updateSearch)
	searchBox.Focused:Connect(function() if searchBox.Text ~= "" then updateSearch() end end)
	searchBox.FocusLost:Connect(function(enterPressed)
		if enterPressed and searchOverlay.Visible then
			local target = (selectedResultIdx > 0 and currentMatched[selectedResultIdx]) or currentMatched[1]
			if target then jumpToItem(target) end
		end
	end)
	searchBtn.Activated:Connect(function()
		searchOverlay.Visible = not searchOverlay.Visible
		if searchOverlay.Visible then
			searchBox:CaptureFocus()
			updateSearch()
		else
			searchResults.Visible = false
		end
	end)
	searchCloseBtn.Activated:Connect(function()
		searchBox.Text = ""
		searchOverlay.Visible = false
		searchResults.Visible = false
	end)

	conn(UserInputService.InputBegan, function(i)
		if searchOverlay.Visible and searchBox:IsFocused() then
			if i.KeyCode == Enum.KeyCode.Right and currentMatched[1] and searchBox.CursorPosition == #searchBox.Text + 1 then
				searchBox.Text = currentMatched[1].name
				searchBox.CursorPosition = #searchBox.Text + 1
			elseif i.KeyCode == Enum.KeyCode.Down then
				if #currentMatched > 0 then
					selectedResultIdx = math.min(selectedResultIdx + 1, #currentMatched)
					highlightSelected()
				end
			elseif i.KeyCode == Enum.KeyCode.Up then
				if #currentMatched > 0 then
					selectedResultIdx = math.max(selectedResultIdx - 1, 0)
					highlightSelected()
				end
			elseif i.KeyCode == Enum.KeyCode.Escape then
				searchOverlay.Visible = false
				searchResults.Visible = false
			end
		end
	end)

	local window = {}
	function window:Destroy()
		if isDev then
			for _, entry in GameConfig do
				if entry.kind == "Toggle" then pcall(entry.set, false) end
			end
		end
		for i = #Library._windows, 1, -1 do
			if Library._windows[i] == windowEntry then
				local n = #Library._windows
				Library._windows[i] = Library._windows[n]
				Library._windows[n] = nil
				break
			end
		end
		for i = 1, #conns do conns[i]:Disconnect() end
		gui:Destroy()
	end
	closeBtn.Activated:Connect(function() window:Destroy() end)

	function window:Notify(text, duration)
		if not notificationsEnabled then return end
		local n = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = notifHolder }, { BackgroundColor3 = "Secondary" })
		corner(n, 8)
		local s = stroke(n, "Stroke", 1)
		pad(n, 14, 10)
		local isLong = isTextLong(text, T.Label, 210)
		local l = Make("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = T.Label, TextWrapped = true, TextTransparency = 1, TextXAlignment = isLong and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center, Text = text, Parent = n }, { TextColor3 = "Text" })

		tw(n, Motion.Panel, { BackgroundTransparency = 0 })
		tw(s, Motion.Panel, { Transparency = 0 })
		tw(l, Motion.Panel, { TextTransparency = 0 })

		task.delay(duration or NOTIFY_DEFAULT_DURATION, function()
			if not n.Parent then return end
			tw(n, Motion.Normal, { BackgroundTransparency = 1 })
			tw(s, Motion.Normal, { Transparency = 1 })
			tw(l, Motion.Normal, { TextTransparency = 1 })
			task.wait(0.2)
			n:Destroy()
		end)
	end

	-- Tooltip when an element is given a description.
	local tooltip = Make("TextLabel", { BackgroundTransparency = 0.1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.new(0, 0, 0, 0), Visible = false, ZIndex = 200, TextSize = T.Label, TextWrapped = true, Text = "", Parent = gui }, { BackgroundColor3 = "Secondary", TextColor3 = "Text" })
	corner(tooltip, 6)
	stroke(tooltip, "Stroke", 0.4)
	pad(tooltip, 8, 5)
	local tooltipConstraint = Instance.new("UISizeConstraint", tooltip)
	tooltipConstraint.MaxSize = Vector2.new(220, math.huge)

	local function updateDockedPosition(inst)
		local absPos = inst.AbsolutePosition
		local absSize = inst.AbsoluteSize
		local camera = workspace.CurrentCamera
		local viewport = camera.ViewportSize
		local targetX = absPos.X + absSize.X + TOOLTIP_OFFSET
		local targetY = absPos.Y + (absSize.Y / 2)
		tooltip.AnchorPoint = Vector2.new(0, 0.5)
		if targetX + 230 > viewport.X then -- Flip to the left if overflowing the right side
			targetX = absPos.X - TOOLTIP_OFFSET
			tooltip.AnchorPoint = Vector2.new(1, 0.5)
		end
		tooltip.Position = UDim2.fromOffset(targetX, targetY)
	end

	local function attachTooltip(inst, text)
		if not text or text == "" then return end
		local hoverToken = 0
		inst.MouseEnter:Connect(function()
			hoverToken += 1
			local current = hoverToken
			task.delay(TOOLTIP_DELAY, function()
				if current == hoverToken then
					tooltip.Text = text
					updateDockedPosition(inst)
					tooltip.Visible = true
				end
			end)
		end)
		inst.MouseLeave:Connect(function()
			hoverToken += 1
			tooltip.Visible = false
		end)
	end

	-- Component Container Factory
	local function createContainer(targetParent, registry, tabName, tabIdx)
		local container = {}
		local order = 0
		local function nextOrder() order += 1; return order end
		local function configKey(kind, name) return tabName .. ">" .. kind .. ":" .. name end

		local function card(h)
			local f = Make("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, h), Parent = targetParent }, { BackgroundColor3 = "Secondary" })
			corner(f, 8)
			pad(f, 16, 0)
			return f
		end

		local function rowLabel(parent, iconName, kind, text, rGap)
			local row = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -(rGap or 0), 1, 0), Parent = parent })
			local rl = Instance.new("UIListLayout", row)
			rl.FillDirection, rl.VerticalAlignment, rl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 10)
			mkicon(iconName, kind, row, UDim2.new(0, 16, 0, 16))
			local l = Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -26, 1, 0), Text = text, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row }, { TextColor3 = "Text" })
			return l
		end

		function container:Section(text, collapsed, builder)
			if type(collapsed) == "function" then builder, collapsed = collapsed, false end
			collapsed = collapsed and true or false

			local header = Make("TextButton", { BackgroundTransparency = 1, LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 24), Parent = targetParent })
			local hl = Instance.new("UIListLayout", header)
			hl.FillDirection, hl.VerticalAlignment, hl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 6)

			local holder, setChevron = newIndicator(header, false)
			Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -20, 1, 0), FontWeight = "Bold", Text = text, Parent = header }, { TextColor3 = "SubText" })

			local subFrame = Make("Frame", { BackgroundTransparency = 1, LayoutOrder = nextOrder(), AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Visible = not collapsed, Parent = targetParent })
			local cl = Instance.new("UIListLayout", subFrame)
			cl.SortOrder, cl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 10)

			local section = createContainer(subFrame, registry, tabName, tabIdx)
			section.Instance = subFrame
			section.Header = header

			local function updateIndicator()
				local hasChildren = #subFrame:GetChildren() > 1
				holder.Visible = hasChildren
				header.Active = hasChildren
			end
			subFrame.ChildAdded:Connect(updateIndicator)
			subFrame.ChildRemoved:Connect(updateIndicator)

			local function setOpen(open)
				collapsed = not open
				subFrame.Visible = open
				setChevron(open)
			end
			setOpen(not collapsed)
			header.Activated:Connect(function() setOpen(collapsed) end)

			function section:SetCollapsed(state) setOpen(not state) end

			if builder then withScope(section, builder) end
			updateIndicator()
			addSearchEntry(text, "Section", tabName, tabIdx, header, function(open) if open then setOpen(true) end end)

			return section
		end

		function container:Divider()
			local f = Make("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 1), Parent = targetParent }, { BackgroundColor3 = "Stroke" })
			return { Instance = f }
		end

		function container:Text(title, content, iconName)
			if content == nil then -- syntax sugar to call with only one string
				content, title = title, nil
			end

			local f = Make("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = targetParent }, { BackgroundColor3 = "Secondary" })
			corner(f, 8)
			pad(f, 16, 14)
			local vl = Instance.new("UIListLayout", f)
			vl.Padding = UDim.new(0, 8)

			local titleLbl = nil
			if title then
				local head = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, T.Title + 4), Parent = f })
				local hl = Instance.new("UIListLayout", head)
				hl.FillDirection, hl.VerticalAlignment, hl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8)

				mkicon(iconName, "Text", head, UDim2.new(0, 18, 0, 18))
				titleLbl = Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -26, 1, 0), FontWeight = "Bold", Text = title, TextSize = T.Title, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head }, { TextColor3 = "Text" })
			end
			local contentLbl = Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = T.Body, TextWrapped = true, Text = content, Parent = f }, { TextColor3 = "SubText" })

			return setmetatable({ Instance = f, _titleLbl = titleLbl, _contentLbl = contentLbl }, TextHandle)
		end

		function container:Button(text, callback, iconName, description)
			callback = callback or function() end
			local f = card(46)
			rowLabel(f, iconName, "Button", text, 0)
			local clickBtn = Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = f })
			local s = stroke(f, "Stroke", 0.7)
			hover(clickBtn, s, { Transparency = 0.2 }, { Transparency = 0.7 })
			attachTooltip(f, description)
			clickBtn.Activated:Connect(function()
				tw(f, Motion.Fast, { BackgroundColor3 = Library.CurrentTheme.Accent })
				task.delay(0.12, function() tw(f, Motion.Normal, { BackgroundColor3 = Library.CurrentTheme.Secondary }) end)
				callback()
			end)

			local Lock, Locked = addLock(f)
			local h = setmetatable({ Instance = f, _callback = callback, _Lock = Lock, _Locked = Locked }, ButtonHandle)
			addSearchEntry(text, "Button", tabName, tabIdx, f)
			return h
		end

		function container:Toggle(text, default, callback, iconName, description)
			callback = callback or function() end
			local f = card(46)
			rowLabel(f, iconName, "Toggle", text, 46)
			local sw = Make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 40, 0, 22), Parent = f })
			corner(sw, 11)
			local circ = Make("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), Size = UDim2.new(0, 16, 0, 16), Parent = sw })
			corner(circ, 8)

			local clickBtn = Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = f })
			local s = stroke(f, "Stroke", 0.7)
			hover(clickBtn, s, { Transparency = 0.2 }, { Transparency = 0.7 })
			attachTooltip(f, description)

			local state = default and true or false
			bindTheme(sw, "BackgroundColor3", function(th) return state and th.Accent or th.Stroke end)

			local key = configKey("Toggle", text)
			local function apply(newState, imm)
				state = newState and true or false
				local pos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
				local col = state and Library.CurrentTheme.Accent or Library.CurrentTheme.Stroke
				if imm then
					circ.Position, sw.BackgroundColor3 = pos, col
				else
					tw(circ, Motion.Normal, { Position = pos })
					tw(sw, Motion.Normal, { BackgroundColor3 = col })
				end
				callback(state)
			end

			clickBtn.Activated:Connect(function() apply(not state); requestSave(registry, key) end)

			local function getState() return state end
			regConfig(registry, key, state, getState, function(v) if type(v) == "boolean" then apply(v, true) end end, "Toggle")

			local Lock, Locked = addLock(f)
			local h = setmetatable({ Instance = f, _get = getState, _apply = apply, _requestSave = requestSave, _registry = registry, _key = key, _Lock = Lock, _Locked = Locked }, ToggleHandle)
			addSearchEntry(text, "Toggle", tabName, tabIdx, f)
			return h
		end

		function container:Slider(text, min, max, default, step, callback, iconName, description)
			if type(step) == "function" then callback, step = step, 1 else step = step or 1 end
			callback = callback or function() end
			min = min or 0
			max = max or 100
			default = default or min
			local decimals = decimalsOf(step)
			local mult = 10 ^ decimals
			local function round(v) return math.floor((math.floor((v - min) / step + 0.5) * step + min) * mult + 0.5) / mult end
			local function fmt(v) return decimals > 0 and string.format("%." .. decimals .. "f", v) or tostring(v) end

			default = round(math.clamp(default, min, max))
			local f = card(70)
			attachTooltip(f, description)
			local row = Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 10), Size = UDim2.new(1, 0, 0, 22), Parent = f })
			local rl = Instance.new("UIListLayout", row)
			rl.FillDirection, rl.VerticalAlignment, rl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8)

			mkicon(iconName, "Slider", row, UDim2.new(0, 14, 0, 14))
			Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(0.6, 0, 1, 0), Text = text, Parent = row }, { TextColor3 = "Text" })

			local val = Make("TextLabel", { Size = UDim2.new(0.3, 0, 0, 22), Position = UDim2.new(0.7, 0, 0, 10), FontWeight = "Bold", Text = fmt(default), TextXAlignment = Enum.TextXAlignment.Right, Parent = f }, { TextColor3 = "Accent" })
			local bar = Make("Frame", { Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 0, 6), Parent = f }, { BackgroundColor3 = "Stroke" })
			corner(bar, 3)

			local fill = Make("Frame", { Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0), Parent = bar }, { BackgroundColor3 = "Accent" })
			corner(fill, 3)
			local knob = Make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Color3.new(1, 1, 1), Parent = fill })
			corner(knob, 6)

			local current = default
			local isDragging = false
			local function setVisual(value, p)
				fill.Size = UDim2.new(p, 0, 1, 0)
				val.Text = fmt(value)
			end

			local key = configKey("Slider", text)
			local function move(x)
				local p = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				local v = round(min + (max - min) * p)
				setVisual(v, p)
				if v ~= current then current = v; callback(v, isDragging) end
			end

			bar.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					isDragging = true
					claimMove(bar, function(pos) move(pos.X) end, function()
						isDragging = false
						callback(current, false)
						requestSave(registry, key)
					end)
					move(i.Position.X)
				end
			end)

			local function applyVal(v)
				v = round(math.clamp(v, min, max))
				current = v
				setVisual(v, (v - min) / (max - min))
				callback(v, false)
			end

			local function getCurrent() return current end
			regConfig(registry, key, default, getCurrent, function(v) if type(v) == "number" then applyVal(v) end end, "Slider")

			local Lock, Locked = addLock(f)
			local h = setmetatable({ Instance = f, _get = getCurrent, _apply = applyVal, _requestSave = requestSave, _registry = registry, _key = key, _Lock = Lock, _Locked = Locked }, SliderHandle)
			addSearchEntry(text, "Slider", tabName, tabIdx, f)
			return h
		end

		function container:Dropdown(text, options, callback, default, iconName, description)
			if type(callback) ~= "function" and callback ~= nil then
				iconName, default, callback = default, callback, function() end
			else
				callback = callback or function() end
			end
			options = options or {}
			local multi = type(default) == "table"
			local selected = {}
			if multi then
				for i = 1, #default do selected[default[i]] = true end
			else
				default = default or options[1]
			end

			local f = card(50)
			f.ClipsDescendants = true
			local fStroke = stroke(f, "Stroke", 0.7)
			hover(f, fStroke, { Transparency = 0.2 }, { Transparency = 0.7 })
			attachTooltip(f, description)

			local function getSelectedList()
				local list = {}
				for i = 1, #options do
					local v = options[i]
					if selected[v] then list[#list + 1] = v end
				end
				return list
			end

			local function getDisplayText()
				if not multi then return tostring(default or "Select...") end
				local list = getSelectedList()
				return #list == 0 and "Select..." or table.concat(list, ", ")
			end

			local head = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), Parent = f })
			rowLabel(head, iconName, "Dropdown", text, 170)

			local selector = Make("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 160, 0, 34), ClipsDescendants = true, Parent = head }, { BackgroundColor3 = "Background" })
			corner(selector, 6)
			local selStroke = stroke(selector, "Stroke", 0.6)

			local selLabel = Make("TextLabel", { Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -28, 1, 0), Text = getDisplayText(), TextSize = T.Body, Parent = selector }, { TextColor3 = "Text" })
			local _, setChevron = newIndicator(selector, true)

			local function updateAlign()
				local str = getDisplayText()
				local isLong = isTextLong(str, T.Body, 122)
				selLabel.TextXAlignment = isLong and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
				selLabel.TextTruncate = isLong and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
			end
			updateAlign()

			local listHolder = Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 50), Size = UDim2.new(1, 0, 0, 0), Parent = f })
			local vl = Instance.new("UIListLayout", listHolder)
			vl.SortOrder, vl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 6)

			local clickBtn = Make("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Parent = f })
			selector.MouseEnter:Connect(function()
				twProp(selStroke, Motion.Fast, "Color", Library.CurrentTheme.Accent)
				twProp(selStroke, Motion.Fast, "Transparency", 0.2)
			end)
			selector.MouseLeave:Connect(function()
				twProp(selStroke, Motion.Fast, "Color", Library.CurrentTheme.Stroke)
				twProp(selStroke, Motion.Fast, "Transparency", 0.6)
			end)

			local key = configKey("Dropdown", text)
			local opened, optBtns, optData = false, {}, {}

			local function refresh()
				selLabel.Text = getDisplayText()
				updateAlign()
				for i = 1, #optBtns do
					local opt, v = optBtns[i], options[i]
					local isSel = multi and selected[v] or (v == default)
					opt.BackgroundColor3 = isSel and Library.CurrentTheme.Accent or Library.CurrentTheme.Background
					opt.TextColor3 = isSel and Library.CurrentTheme.AccentText or Library.CurrentTheme.SubText
				end
			end

			local function setOpened(open)
				opened = open
				setChevron(opened)
				tw(f, Motion.Normal, { Size = UDim2.new(1, 0, 0, opened and (#options * 38 + 58) or 50) })
			end

			local function build()
				for i = 1, #options do
					local v = options[i]
					local data = optData[i]
					if not data then
						local opt = Make("TextButton", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 32), TextSize = T.Body, Parent = listHolder })
						corner(opt, 6)
						data = { btn = opt, value = v }
						optData[i] = data
						bindTheme(opt, "BackgroundColor3", function(th)
							local isSel = multi and selected[data.value] or (data.value == default)
							return isSel and th.Accent or th.Background
						end)
						bindTheme(opt, "TextColor3", function(th)
							local isSel = multi and selected[data.value] or (data.value == default)
							return isSel and th.AccentText or th.SubText
						end)
						opt.Activated:Connect(function()
							local val = data.value
							if multi then
								selected[val] = not selected[val] or nil
								callback(getSelectedList())
							else
								default = val
								setOpened(false)
								callback(val)
							end
							refresh()
							requestSave(registry, key)
						end)
					else
						data.value = v
					end
					data.btn.Text = tostring(v)
					optBtns[i] = data.btn
				end
				for i = #options + 1, #optData do
					optData[i].btn:Destroy()
					optData[i] = nil
					optBtns[i] = nil
				end
			end
			build()

			clickBtn.Activated:Connect(function() setOpened(not opened) end)

			local function getValue() return multi and getSelectedList() or default end
			local function setValue(v)
				if multi and type(v) == "table" then
					table.clear(selected)
					for i = 1, #v do
						local item = v[i]
						if table.find(options, item) then selected[item] = true end
					end
				elseif table.find(options, v) then
					default = v
				end
				refresh()
				callback(getValue())
			end
			-- Section 11c: multi-select stores a plain string array; JSON round-trips it as an array natively.
			regConfig(registry, key, getValue(), getValue, setValue, "Dropdown")

			local function refreshOptions(newOpts)
				options = newOpts or {}
				build()
				refresh()
				if opened then
					tw(f, Motion.Normal, { Size = UDim2.new(1, 0, 0, #options * 38 + 58) })
				end
			end

			local Lock, Locked = addLock(f)
			local h = setmetatable({
				Instance = f, _get = getValue, _set = setValue, _refreshOptions = refreshOptions,
				_requestSave = requestSave, _registry = registry, _key = key, _Lock = Lock, _Locked = Locked,
			}, DropdownHandle)
			-- Section 11b: the search "expand" hook actually opens the dropdown before jumping to it.
			addSearchEntry(text, "Dropdown", tabName, tabIdx, f, function(open) if open then setOpened(true) end end)
			return h
		end

		function container:Keybind(text, default, callback, iconName, description)
			callback = callback or function() end
			local f = card(46)
			local fStroke = stroke(f, "Stroke", 0.7)
			hover(f, fStroke, { Transparency = 0.2 }, { Transparency = 0.7 })
			attachTooltip(f, description)
			rowLabel(f, iconName, "Keybind", text, 110)
			local bind = Make("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 30), FontWeight = "Bold", Text = default and default.Name or "None", TextSize = T.Body, Parent = f }, { BackgroundColor3 = "Background", TextColor3 = "Text" })
			corner(bind, 6)
			pad(bind, 8, 0)
			local bs = stroke(bind, "Stroke", 0.5)

			local key, listening = default, false
			bind.Activated:Connect(function()
				listening = true
				bind.Text = "..."
				twProp(bs, Motion.Fast, "Color", Library.CurrentTheme.Accent)
				twProp(bs, Motion.Fast, "Transparency", 0)
			end)

			local resolvedKey = configKey("Keybind", text)
			conn(UserInputService.InputBegan, function(i, gpe)
				if listening and i.UserInputType == Enum.UserInputType.Keyboard then
					key = (i.KeyCode == Enum.KeyCode.Backspace or i.KeyCode == Enum.KeyCode.Escape) and nil or i.KeyCode
					bind.Text = key and key.Name or "None"
					listening = false
					twProp(bs, Motion.Fast, "Color", Library.CurrentTheme.Stroke)
					twProp(bs, Motion.Fast, "Transparency", 0.5)
					requestSave(registry, resolvedKey)
				elseif not gpe and key and i.KeyCode == key then
					callback(key)
				end
			end)

			local function setKeyHandle(newKey)
				if typeof(newKey) == "EnumItem" and newKey.EnumType == Enum.KeyCode then
					key = newKey
				elseif type(newKey) == "string" then
					key = (newKey ~= "None" and pcall(function() return Enum.KeyCode[newKey] end) and Enum.KeyCode[newKey]) or nil
				else
					key = nil
				end
				bind.Text = key and key.Name or "None"
			end

			regConfig(registry, resolvedKey, default and default.Name or "None", function() return key and key.Name or "None" end, setKeyHandle, "Keybind")

			local Lock, Locked = addLock(f)
			local h = setmetatable({ Instance = f, _get = function() return key end, _setKey = setKeyHandle, _requestSave = requestSave, _registry = registry, _key = resolvedKey, _Lock = Lock, _Locked = Locked }, KeybindHandle)
			addSearchEntry(text, "Keybind", tabName, tabIdx, f)
			return h
		end

		function container:Input(text, placeholder, callback, default, iconName, description)
			if type(placeholder) == "function" then callback, placeholder = placeholder, "" end
			callback = callback or function() end
			local f = card(50)
			local fStroke = stroke(f, "Stroke", 0.7)
			hover(f, fStroke, { Transparency = 0.2 }, { Transparency = 0.7 })
			attachTooltip(f, description)
			rowLabel(f, iconName, "Input", text, 170)
			local box = Make("TextBox", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 160, 0, 34), PlaceholderText = placeholder or "", Text = default or "", TextSize = T.Body, ClipsDescendants = true, Parent = f }, { BackgroundColor3 = "Background", TextColor3 = "Text", PlaceholderColor3 = "SubText" })
			corner(box, 6)
			pad(box, 10, 0)
			stroke(box, "Stroke", 0.6)

			local function updateAlign()
				local str = box.Text ~= "" and box.Text or box.PlaceholderText
				local isLong = isTextLong(str, T.Body, 140)
				box.TextXAlignment = isLong and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
			end

			local key = configKey("Input", text)
			box:GetPropertyChangedSignal("Text"):Connect(updateAlign)
			box.Focused:Connect(function() if box.Text ~= "" then box.TextXAlignment = Enum.TextXAlignment.Left end end)
			box.FocusLost:Connect(function()
				updateAlign()
				callback(box.Text)
				requestSave(registry, key)
			end)
			updateAlign()

			regConfig(registry, key, default or "", function() return box.Text end, function(v)
				if type(v) == "string" then box.Text = v; updateAlign(); callback(v) end
			end, "Input")

			local function setValue(val)
				box.Text = tostring(val or "")
				updateAlign()
				callback(box.Text)
			end

			local Lock, Locked = addLock(f)
			local h = setmetatable({ Instance = f, _get = function() return box.Text end, _set = setValue, _requestSave = requestSave, _registry = registry, _key = key, _Lock = Lock, _Locked = Locked }, InputHandle)
			addSearchEntry(text, "Input", tabName, tabIdx, f)
			return h
		end

		function container:Color(text, default, callback, iconName, description)
			if type(default) == "function" then callback, default = default, Color3.fromRGB(255, 255, 255) end
			callback = callback or function() end
			local f = card(46)
			f.ClipsDescendants = true
			local fStroke = stroke(f, "Stroke", 0.7)

			local head = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Parent = f })
			rowLabel(head, iconName, "Color", text, 48)

			local col = default or Color3.fromRGB(255, 255, 255)
			local h, s, v = col:ToHSV()

			local headClick = Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = head })
			hover(headClick, fStroke, { Transparency = 0.2 }, { Transparency = 0.7 })
			attachTooltip(f, description)
			local swatch = Make("TextButton", { BackgroundColor3 = col, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 34, 0, 22), Parent = head })
			corner(swatch, 6)
			local sws = stroke(swatch, "Stroke")
			hoverColor(swatch, sws, "Color", "Accent", "Stroke")

			local content = Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 0, 130), Visible = false, Parent = f })
			local cl = Instance.new("UIListLayout", content)
			cl.SortOrder, cl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 8)

			local map = Make("Frame", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 74), BackgroundColor3 = Color3.fromHSV(h, 1, 1), Parent = content })
			corner(map, 6)
			local satOverlay = Make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = map })
			corner(satOverlay, 6)
			local satGrad = Instance.new("UIGradient", satOverlay)
			satGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })

			local valOverlay = Make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), Parent = map })
			corner(valOverlay, 6)
			local valGrad = Instance.new("UIGradient", valOverlay)
			valGrad.Rotation, valGrad.Transparency = 90, NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })

			local satCursor = Make("Frame", { Size = UDim2.new(0, 10, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(s, 0, 1 - v, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = map })
			corner(satCursor, 5)
			stroke(satCursor, "Stroke", 0.3)

			local hueBar = Make("Frame", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = Color3.new(1, 1, 1), Parent = content })
			corner(hueBar, 5)
			local hueGrad = Instance.new("UIGradient", hueBar)
			hueGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
			})

			local hueCursor = Make("Frame", { Size = UDim2.new(0, 8, 1, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(h, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = hueBar })
			corner(hueCursor, 3)
			stroke(hueCursor, "Stroke", 0.4)

			local inRow = Make("Frame", { LayoutOrder = 3, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Parent = content })
			local irl = Instance.new("UIListLayout", inRow)
			irl.FillDirection, irl.Padding = Enum.FillDirection.Horizontal, UDim.new(0, 6)

			local hexBox = Make("TextBox", { LayoutOrder = 1, Size = UDim2.new(0.4, -4, 1, 0), Text = "#" .. col:ToHex():upper(), TextSize = T.Small, TextXAlignment = Enum.TextXAlignment.Center, Parent = inRow }, { BackgroundColor3 = "Background", TextColor3 = "Text" })
			corner(hexBox, 6)
			stroke(hexBox, "Stroke", 0.6)

			local channelNames = { "R", "G", "B" }
			local chanBoxes = {}
			for idx = 1, #channelNames do
				local name = channelNames[idx]
				local b = Make("TextBox", { LayoutOrder = idx + 1, Size = UDim2.new(0.2, -4, 1, 0), PlaceholderText = name, Text = tostring(math.floor(col[name] * 255 + 0.5)), TextSize = T.Small, TextXAlignment = Enum.TextXAlignment.Center, Parent = inRow }, { BackgroundColor3 = "Background", TextColor3 = "Text", PlaceholderColor3 = "SubText" })
				corner(b, 6)
				stroke(b, "Stroke", 0.6)
				chanBoxes[name] = b
			end

			local function updateVisuals(skipInputs)
				col = Color3.fromHSV(h, s, v)
				map.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				satCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
				swatch.BackgroundColor3 = col
				if not skipInputs then
					hexBox.Text = "#" .. col:ToHex():upper()
					for name, b in chanBoxes do b.Text = tostring(math.floor(col[name] * 255 + 0.5)) end
				end
				callback(col)
			end

			local key = configKey("Color", text)
			local function pickSatVal(pos)
				s = math.clamp((pos.X - map.AbsolutePosition.X) / map.AbsoluteSize.X, 0, 1)
				v = 1 - math.clamp((pos.Y - map.AbsolutePosition.Y) / map.AbsoluteSize.Y, 0, 1)
				updateVisuals(false)
			end

			local function pickHue(pos)
				h = math.clamp((pos.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
				updateVisuals(false)
			end

			local function saveOnDragEnd() requestSave(registry, key) end

			map.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					claimMove(map, pickSatVal, saveOnDragEnd); pickSatVal(i.Position)
				end
			end)
			hueBar.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					claimMove(hueBar, pickHue, saveOnDragEnd); pickHue(i.Position)
				end
			end)

			hexBox.FocusLost:Connect(function()
				local ok, newCol = pcall(Color3.fromHex, hexBox.Text:gsub("#", ""))
				if ok and newCol then
					h, s, v = newCol:ToHSV()
					updateVisuals(false)
					requestSave(registry, key)
				else
					hexBox.Text = "#" .. col:ToHex():upper()
				end
			end)

			local function commitRgb()
				local r = math.clamp(tonumber(chanBoxes.R.Text) or 0, 0, 255)
				local g = math.clamp(tonumber(chanBoxes.G.Text) or 0, 0, 255)
				local b = math.clamp(tonumber(chanBoxes.B.Text) or 0, 0, 255)
				h, s, v = Color3.fromRGB(r, g, b):ToHSV()
				updateVisuals(false)
				requestSave(registry, key)
			end
			for _, b in chanBoxes do b.FocusLost:Connect(commitRgb) end

			local opened = false
			local function toggleOpen()
				opened = not opened
				content.Visible = opened
				tw(f, Motion.Normal, { Size = UDim2.new(1, 0, 0, opened and 184 or 46) })
			end
			swatch.Activated:Connect(toggleOpen)
			headClick.Activated:Connect(toggleOpen)

			local function getRgbTable()
				return { R = math.floor(col.R * 255 + 0.5), G = math.floor(col.G * 255 + 0.5), B = math.floor(col.B * 255 + 0.5) }
			end

			local function setFromValue(val)
				local res = typeof(val) == "Color3" and val
					or (type(val) == "table" and val.R and Color3.fromRGB(val.R, val.G or 0, val.B or 0))
					or (type(val) == "string" and pcall(Color3.fromHex, val:gsub("#", "")) and Color3.fromHex(val:gsub("#", "")))
				if res then
					h, s, v = res:ToHSV()
					updateVisuals(false)
				end
			end

			regConfig(registry, key, getRgbTable(), getRgbTable, setFromValue, "Color")

			local Lock, Locked = addLock(f)
			local hdl = setmetatable({ Instance = f, _get = function() return col end, _set = setFromValue, _requestSave = requestSave, _registry = registry, _key = key, _Lock = Lock, _Locked = Locked }, ColorHandle)
			addSearchEntry(text, "Color", tabName, tabIdx, f)
			return hdl
		end

		return container
	end

	local function createTab(tabName, tabIcon, registry, tabBuilder)
		if type(tabIcon) == "function" then tabBuilder, tabIcon = tabIcon, nil end
		local tabIndex = #tabPages + 1
		local isSettings = registry == KvantConfig

		local btn = Make("TextButton", {
			Size = isSide and UDim2.new(0.9, 0, 0, 36) or UDim2.new(0, 0, 0, 38),
			AutomaticSize = isSide and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
			LayoutOrder = tabIndex,
			Visible = not isSettings,
			Parent = tabHolder,
		}, { BackgroundColor3 = function(th) return activeIndex == tabIndex and th.Accent or th.Secondary end })
		corner(btn, isSide and 7 or 19)
		pad(btn, isSide and 10 or 14, 0)

		local bl = Instance.new("UIListLayout", btn)
		bl.FillDirection, bl.VerticalAlignment, bl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8)
		mkicon(tabIcon, "Tab", btn, UDim2.new(0, 16, 0, 16))

		local label = Make("TextLabel", { LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.X, Size = isSide and UDim2.new(1, -24, 1, 0) or UDim2.new(0, 0, 1, 0), Text = tabName, TextTruncate = Enum.TextTruncate.AtEnd, Parent = btn,
		}, { TextColor3 = function(th) return activeIndex == tabIndex and th.AccentText or th.SubText end })

		local page = Make("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Visible = false, AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = pageHolder })
		styleScroll(page, false)

		local pl = Instance.new("UIListLayout", page)
		pl.SortOrder, pl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 10)

		local function activate()
			activeIndex = tabIndex
			if not isSettings then lastUserIndex = tabIndex end
			for i = 1, #tabPages do
				local p, isCur = tabPages[i], (i == activeIndex)
				p.Visible = isCur
				if tabBtns[i].Visible then
					tabBtns[i].BackgroundColor3 = isCur and Library.CurrentTheme.Accent or Library.CurrentTheme.Secondary
					tabLabels[i].TextColor3 = isCur and Library.CurrentTheme.AccentText or Library.CurrentTheme.SubText
				end
			end
		end

		local function hoverTab(b, l, index)
			-- TODO: Should add here isLight call??
			b.MouseEnter:Connect(function()
				if activeIndex ~= index then
					twProp(b, Motion.Fast, "BackgroundColor3", Library.CurrentTheme.Accent)
					twProp(l, Motion.Fast, "TextColor3", Library.CurrentTheme.AccentText)
				end
			end)
			b.MouseLeave:Connect(function()
				if activeIndex ~= index then
					twProp(b, Motion.Fast, "BackgroundColor3", Library.CurrentTheme.Secondary)
					twProp(l, Motion.Fast, "TextColor3", Library.CurrentTheme.SubText)
				end
			end)
		end
		btn.Activated:Connect(activate)
		hoverTab(btn, label, tabIndex)

		tabPages[tabIndex], tabBtns[tabIndex], tabLabels[tabIndex], tabActivators[tabIndex] = page, btn, label, activate
		if isSettings then settingsIndex = tabIndex elseif not lastUserIndex then activate() end

		local tab = createContainer(page, registry, tabName, tabIndex)
		tab.Instance = page
		tab.Button = btn

		if tabBuilder then withScope(tab, tabBuilder) end
		return tab
	end

	function window:Tab(name, icon, tabBuilder)
		return createTab(name, icon, GameConfig, tabBuilder)
	end

	-- Settings Tab
	local settingsTab = createTab("Settings", ASSET.Settings, KvantConfig)
	settingsTab:Section("Interface", false, function(s)
		s:Dropdown("Theme", { "Darker", "Dark", "Vesper", "Light", "SolarizedLight" }, function(v) Library:SetTheme(v) end, "Darker")
		s:Dropdown("Font", { "Inter", "Roboto", "Ubuntu" }, function(v) Library:SetFont(v) end, "Roboto")
		s:Slider("UI Scale", 80, 120, 100, 1, function(v) baseScale = v / 100; if not minimized then uiScale.Scale = baseScale end end)
		s:Toggle("Show Icons", true, function(st)
			iconsOn = st
			for i = 1, #icons do icons[i].inst.Visible = st end
			for i = 1, #indicators do
				indicators[i].img.Visible = st
				indicators[i].txt.Visible = not st
			end
		end)
		s:Toggle("Close Button", false, function(st) closeBtn.Visible = st end)
		s:Toggle("Reduce Motion", false, function(st) reduceMotion = st end)
		s:Button("Reset Window", function() main.Position = defaultPosition end)
	end)

	settingsTab:Section("Controls", false, function(s)
		s:Keybind("Collapse Window", Enum.KeyCode.K, toggleWindow)
		s:Toggle("Unlock Cursor", false, function(st) unlockCursor = st; applyCursorState() end)
	end)

	settingsTab:Section("Other", false, function(s)
		s:Toggle("Disable Notifications", false, function(st) notificationsEnabled = not st end)
		if supported then
			s:Toggle("Autoload Settings", true, function(st) autoload = st end)
			s:Button("Reset Settings", function()
				for key, entry in GameConfig do
					pcall(entry.set, entry.default)
					markDirty(GameConfig, key)
				end
				requestSave(GameConfig)
			end)
		end
	end)

	settingsBtn.Activated:Connect(function()
		if lastUserIndex == nil then return end
		if activeIndex == settingsIndex then
			tabActivators[lastUserIndex]()
		else
			tabActivators[settingsIndex]()
		end
	end)

	if supported then
		task.defer(function()
			ensureFolders()
			applyConfig(KvantConfig, PERSIST.Kvant)
			if autoload then applyConfig(GameConfig, PERSIST.Game(GameId)) end
		end)
	end

	if builder then withScope(window, builder) end
	return window
end

return Library
