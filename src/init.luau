-- TODO:
-- style: correct code style format (lazy for now)
-- style: extract hardcoded strings for better code (lazy for now)
-- pcall elements in scope creating - so it can create other valid elements or keep as error??
-- refactor: replace getfenv?

-- LATER TODO:
-- feat?? reset kvant settings
-- feat?? collapse/uncollapse all sections?
-- feat: lock/unlock functionality? can be done without library with simple if flag but will see.
-- feat: toasts (or how it's called i forgor) on long hover with descriptin for toggles, buttons, etc???
-- feat: auto-cache and auto-update when needed from github (if supported).
-- feat: add customasset to bypass detection.
-- style: better hover effect on other elements??
-- style: BuilderIcons - find chevron icons for dropdowns
-- style: BuilderIcons - replacement top frame header icons
-- style: Better dropdown left lucide icon
-- feat?? custom frame with content - like timers, etc...?

-- Environment & Services
local cloneref = cloneref or function(f) return f end
local TweenService: TweenService = cloneref(game:GetService("TweenService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))

local supported = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
local GameId = tostring(cloneref(game).GameId)
local ROOT = "Kvant"
local GAMES_DIR = ROOT .. "/games"
local KVANT_FILE = ROOT .. "/settings.luau"
local function gameFile(id) return GAMES_DIR .. "/" .. tostring(id) .. ".luau" end

-- Library & Configuration
local Library = {
	CurrentTheme = nil,
	Themes = {},
}

Library.Config = {
	Text = { Title = 18, Label = 17, Body = 16, Small = 15 },
	Fonts = {
		Bold = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Bold),
		Medium = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Medium),
		Regular = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular),
		Icons = Font.new("rbxasset://luapackages/packages/_index/buildericons/buildericons/buildericons.json"),
	},
	Motion = {
		Fast = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Normal = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Panel = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	},
}

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
		AccentText = Color3.fromRGB(16, 16, 16),
	},
	Light = {
		Background = Color3.fromRGB(246, 246, 246), Secondary  = Color3.fromRGB(255, 255, 255),
		Accent     = Color3.fromRGB(25, 118, 210),  Stroke     = Color3.fromRGB(225, 225, 228),
		Text       = Color3.fromRGB(33, 33, 33),    SubText    = Color3.fromRGB(117, 117, 117),
		AccentText = Color3.fromRGB(255, 255, 255),
	},
	SolorizedLight = {
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
	for _, k in REQUIRED_THEME_KEYS do
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

local themeRegistry, fontRegistry = {}, {}
local function bindTheme(inst, prop, key)
	table.insert(themeRegistry, { inst = inst, prop = prop, key = key })
	local val = type(key) == "function" and key(Library.CurrentTheme) or Library.CurrentTheme[key]
	if val then inst[prop] = val end
	return inst
end

local function bindFont(inst, weight)
	table.insert(fontRegistry, { inst = inst, weight = weight })
	inst.FontFace = Library.Config.Fonts[weight] or Library.Config.Fonts.Regular
	return inst
end

function Library:SetTheme(theme)
	local t = typeof(theme) == "table" and theme or Library.Themes[theme]
	if not t or not validateTheme(t) then return end
	Library.CurrentTheme = sanitizeTheme(t)
	for i = #themeRegistry, 1, -1 do
		local e = themeRegistry[i]
		if e.inst.Parent then
			local val = type(e.key) == "function" and e.key(Library.CurrentTheme) or Library.CurrentTheme[e.key]
			if val then e.inst[e.prop] = val end
		else
			table.remove(themeRegistry, i)
		end
	end
end

local FontPresets = {
	Inter = "rbxassetid://12187365364",
	Roboto = "rbxasset://fonts/families/Roboto.json",
	Ubuntu = "rbxasset://fonts/families/Ubuntu.json",
}

function Library:SetFont(font)
	local id = FontPresets[font] or (typeof(font) == "Font" and font.Family) or tostring(font)
	if not id:find("://") and tonumber(id) then id = "rbxassetid://" .. id end
	Library.Config.Fonts.Bold = Font.new(id, Enum.FontWeight.Bold)
	Library.Config.Fonts.Medium = Font.new(id, Enum.FontWeight.Medium)
	Library.Config.Fonts.Regular = Font.new(id, Enum.FontWeight.Regular)
	for i = #fontRegistry, 1, -1 do
		local e = fontRegistry[i]
		if e.inst.Parent then
			e.inst.FontFace = Library.Config.Fonts[e.weight] or Library.Config.Fonts.Regular
		else
			table.remove(fontRegistry, i)
		end
	end
end

Library.Themes = BuiltInThemes
Library.CurrentTheme = sanitizeTheme(BuiltInThemes.Darker)

local Icons = {
	Kvant = "rbxassetid://73167696981648",
	Tab = "rbxassetid://91943941515944",
	Button = "rbxassetid://107150227368485",
	Toggle = "rbxassetid://90411952142550",
	Slider = "rbxassetid://85538382643347",
	Keybind = "rbxassetid://121474456068237",
	Text = "rbxassetid://133543553793564",
	Settings = "rbxassetid://80758916183665",
	Dropdown = "rbxassetid://134243273101015",
	Color = "rbxassetid://86350350950064",
	Input = "rbxassetid://107551944047171",
}

-- Scoped Context Manager
local contextStack = {}

local function currentScope()
	return contextStack[#contextStack]
end

local function withScope(scope, fn)
	table.insert(contextStack, scope)
	local ok, err = pcall(fn, scope)
	table.remove(contextStack)
	if not ok then error(err, 2) end
end

local DeclarativeMethods = {
	"Tab", "Section", "Divider", "Text", "Button", "Toggle", "Slider", "Dropdown", "Keybind", "Input", "Color"
}

local function registerDeclaratives(target)
	if type(target) ~= "table" then return end
	for _, name in DeclarativeMethods do
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

-- Primitives & Helper Functions
local nid = 0
local function getName()
	nid += 1
	return string.format("%X%X", os.clock() * 1e4, nid)
end

local function ensureFolders()
	if not supported then return end
	if not isfolder(ROOT) then makefolder(ROOT) end
	if not isfolder(GAMES_DIR) then makefolder(GAMES_DIR) end
end

local function corner(p, r)
	local c = Instance.new("UICorner", p)
	c.CornerRadius = UDim.new(0, r or 8)
	return c
end

local function pad(p, x, y)
	local padInst = Instance.new("UIPadding", p)
	padInst.PaddingLeft, padInst.PaddingRight = UDim.new(0, x), UDim.new(0, x)
	padInst.PaddingTop, padInst.PaddingBottom = UDim.new(0, y or x), UDim.new(0, y or x)
	return padInst
end

local function stroke(p, colKey, trans)
	local s = Instance.new("UIStroke", p)
	s.Transparency = trans or 0
	bindTheme(s, "Color", colKey or "Stroke")
	return s
end

local function decimalsOf(n)
	if n == math.floor(n) then return 0 end
	local s = string.format("%.6f", n):gsub("0+$", ""):gsub("%.$", "")
	local dot = s:find("%.")
	return dot and (#s - dot) or 0
end

local function serialize(val)
	local t = type(val)
	if t == "string" then return string.format("%q", val)
	elseif t == "number" or t == "boolean" then return tostring(val)
	elseif t == "table" then
		local parts = {}
		for k, v in val do
			if type(k) == "string" or type(k) == "number" then
				table.insert(parts, "[" .. serialize(k) .. "]=" .. serialize(v))
			end
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "nil"
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

function Library:CreateWindow(optOrName, sideTabs, customTheme, customSize, iconId)
	pcall(function()
		if type(getfenv) == "function" then registerDeclaratives(getfenv(2)) end
	end)

	-- You might not like it, but that's the way it is
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

	if opt.Theme then Library:SetTheme(opt.Theme) end
	local T, F, Motion = Library.Config.Text, Library.Config.Fonts, Library.Config.Motion
	local isSide = opt.SideTabs or false

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

	-- Config Registries
	local KvantConfig, GameConfig, savePending = {}, {}, {}
	local function regConfig(registry, key, default, getter, setter)
		registry[key] = { default = default, get = getter, set = setter }
	end

	local function requestSave(registry)
		if not supported or savePending[registry] then return end
		savePending[registry] = true
		task.delay(0.35, function()
			savePending[registry] = nil
			ensureFolders()
			local data = {}
			for k, v in registry do
				local ok, res = pcall(v.get)
				if ok then data[k] = res end
			end
			pcall(writefile, registry == KvantConfig and KVANT_FILE or gameFile(GameId), serialize(data))
		end)
	end

	local function applyConfig(registry, path)
		if not isfile(path) then return end
		local ok, chunk = pcall(loadstring, "return " .. readfile(path))
		if not ok or type(chunk) ~= "function" then return end
		local ran, data = pcall(chunk)
		if not ran or type(data) ~= "table" then return end
		for k, entry in registry do
			if data[k] ~= nil then pcall(entry.set, data[k]) end
		end
	end

	-- Motion & Connectivity Helpers
	local icons, indicators, conns = {}, {}, {}
	local reduceMotion, iconsOn, notificationsEnabled, autoload = false, true, true, true

	local function tw(inst, info, props)
		if reduceMotion then
			for k, v in props do (inst)[k] = v end
		else
			TweenService:Create(inst, info, props):Play()
		end
	end

	local function conn(sig, fn)
		local c = sig:Connect(fn)
		table.insert(conns, c)
		return c
	end

	local function hover(btn, target, enterProps, leaveProps)
		conn(btn.MouseEnter, function() tw(target, Motion.Fast, typeof(enterProps) == "function" and enterProps() or enterProps) end)
		conn(btn.MouseLeave, function() tw(target, Motion.Fast, typeof(leaveProps) == "function" and leaveProps() or leaveProps) end)
	end

	local function mkicon(id, kind, parent, size, isMuted)
		local imgId = id == nil and Icons[kind] or id
		if not imgId then return end
		local img = Make("ImageLabel", { LayoutOrder = 1, Size = size, Image = imgId, Visible = iconsOn, Parent = parent }, {
			ImageColor3 = isMuted and "IconMuted" or "Icon"
		})
		table.insert(icons, { inst = img, muted = isMuted or false })
		return img
	end

	local function newIndicator(parent, isDropdown)
		local holder = Make("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 14, 0, 14),
			AnchorPoint = isDropdown and Vector2.new(1, 0.5) or Vector2.new(0.5, 0.5),
			Position = isDropdown and UDim2.new(1, -7, 0.5, 0) or UDim2.new(0.5, 0, 0.5, 0),
			Parent = parent,
		})
		local img = Make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 12, 0, 12),
			Image = Icons.Dropdown,
			Visible = iconsOn,
			Parent = holder,
		}, { ImageColor3 = "SubText" })
		local txt = Make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),
			FontFace = F.Icons,
			Text = "",
			TextSize = T.Small,
			TextXAlignment = Enum.TextXAlignment.Center,
			Visible = not iconsOn,
			Parent = holder,
		}, { TextColor3 = "SubText" })
		local ind = { img = img, txt = txt, isDropdown = isDropdown }
		local function setOpen(open)
			if isDropdown then
				tw(img, Motion.Normal, { Rotation = open and 180 or 0 })
				txt.Text = open and "arrow-medium-down" or "arrow-medium-up"
			else
				tw(img, Motion.Normal, { Rotation = open and 0 or -90 })
				txt.Text = open and "arrow-medium-down" or "arrow-medium-right"
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

	local activeMove, dragMoved = nil, false
	conn(UserInputService.InputChanged, function(i)
		if activeMove and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			activeMove(i.Position)
		end
	end)
	conn(UserInputService.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then activeMove = nil end
	end)

	local function makeDraggable(frame, handle)
		handle = handle or frame
		handle.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				local sx, sy = i.Position.X, i.Position.Y
				local ox, oy = frame.Position.X.Offset, frame.Position.Y.Offset
				dragMoved = false
				activeMove = function(pos)
					if math.abs(pos.X - sx) > 3 or math.abs(pos.Y - sy) > 3 then dragMoved = true end
					frame.Position = UDim2.new(frame.Position.X.Scale, ox + (pos.X - sx), frame.Position.Y.Scale, oy + (pos.Y - sy))
				end
			end
		end)
	end

	-- Root Interface
	local gui = Make("ScreenGui", {
		ResetOnSpawn = false,
		Parent = gethui and gethui() or cloneref(game:FindFirstChild("CoreGui")) or cloneref(game:GetService("Players")).LocalPlayer:WaitForChild("PlayerGui"),
	})

	local winSize = opt.Size or (isSide and UDim2.new(0.42, 0, 0.62, 0) or UDim2.new(0.3, 0, 0.6, 0))
	local main = Make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = winSize,
		Active = true,
		ClipsDescendants = true,
		Parent = gui,
	}, { BackgroundColor3 = "Background" })
	local defaultPosition = main.Position
	corner(main, 10)
	stroke(main, "Stroke")

	local mainConstraint = Instance.new("UISizeConstraint", main)
	mainConstraint.MinSize = opt.MinSize or (isSide and Vector2.new(460, 400) or Vector2.new(320, 400))
	mainConstraint.MaxSize = opt.MaxSize or (isSide and Vector2.new(620, 560) or Vector2.new(420, 520))

	local uiScale = Instance.new("UIScale", main)
	local notifHolder = Make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 260, 1, -32), Parent = gui })
	local notifLayout = Instance.new("UIListLayout", notifHolder)
	notifLayout.VerticalAlignment, notifLayout.HorizontalAlignment, notifLayout.Padding = Enum.VerticalAlignment.Bottom, Enum.HorizontalAlignment.Right, UDim.new(0, 8)

	-- Topbar
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

	local settingsBtn = Make("ImageButton", { Size = UDim2.new(0, 20, 0, 20), Image = Icons.Settings, LayoutOrder = 1, Parent = controls }, { ImageColor3 = "Icon" })
	local minBtn = Make("ImageButton", { Size = UDim2.new(0, 20, 0, 20), Image = "rbxassetid://10137941941", LayoutOrder = 2, Parent = controls }, { ImageColor3 = "Icon" })
	local closeBtn = Make("ImageButton", { Size = UDim2.new(0, 22, 0, 22), Image = "rbxassetid://10137832201", Visible = false, LayoutOrder = 3, Parent = controls }, { ImageColor3 = "Icon" })

	for _, btn in { settingsBtn, minBtn, closeBtn } do
		hover(btn, btn, function() return { ImageColor3 = Library.CurrentTheme.Accent } end, function() return { ImageColor3 = Library.CurrentTheme.Icon } end)
	end
	makeDraggable(main, topbar)

	local pill = Make("TextButton", {
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.04, 0),
		Size = UDim2.new(0, 0, 0, 36),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = gui,
	}, { BackgroundColor3 = "Secondary" })
	corner(pill, 18)
	pad(pill, 16, 0)
	local pillConstraint = Instance.new("UISizeConstraint", pill)
	pillConstraint.MinSize, pillConstraint.MaxSize = Vector2.new(110, 36), Vector2.new(280, 36)

	local layout = Instance.new("UIListLayout", pill)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	local label = Make("TextLabel", {
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = opt.Name or "Kvant",
		TextSize = T.Label,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = pill,
	}, { TextColor3 = "Text" })
	local labelConstraint = Instance.new("UISizeConstraint", label)
	labelConstraint.MaxSize = Vector2.new(248, math.huge)
	local pillStroke = stroke(pill, "Stroke")
	hover(pill, pillStroke, function() return { Color = Library.CurrentTheme.Accent } end, function() return { Color = Library.CurrentTheme.Stroke } end)
	makeDraggable(pill)

	-- Window Layouts
	local tabHolder, pageHolder
	if isSide then
		tabHolder = Make("ScrollingFrame", {
			Position = UDim2.new(0, 0, 0, 44),
			Size = UDim2.new(0.30, 0, 1, -44),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = main,
		}, { BackgroundColor3 = "Secondary" })
		corner(tabHolder, 10)
		styleScroll(tabHolder, false)
		pad(tabHolder, 0, 10)

		local tabList = Instance.new("UIListLayout", tabHolder)
		tabList.SortOrder, tabList.HorizontalAlignment, tabList.Padding = Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Center, UDim.new(0, 6)

		Make("Frame", { Position = UDim2.new(0.30, 0, 0, 44), Size = UDim2.new(0, 1, 1, -44), Parent = main }, { BackgroundColor3 = "Stroke" })
		pageHolder = Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.30, 0, 0, 44), Size = UDim2.new(0.7, 0, 1, -44), Parent = main })
	else
		tabHolder = Make("ScrollingFrame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16, 0, 54),
			Size = UDim2.new(1, -32, 0, 46),
			ScrollingDirection = Enum.ScrollingDirection.X,
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			Parent = main,
		})
		styleScroll(tabHolder, true)

		local tabList = Instance.new("UIListLayout", tabHolder)
		tabList.FillDirection, tabList.VerticalAlignment, tabList.SortOrder, tabList.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, Enum.SortOrder.LayoutOrder, UDim.new(0, 8)
		pageHolder = Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 108), Size = UDim2.new(1, 0, 1, -102), Parent = main })
	end
	pad(pageHolder, 16, 12)

	-- Window Behaviors & Controls
	local minimized, unlockCursor, savedMouseBehavior, isAnimating = false, false, nil, false

	-- TODO: Transfer this
	local baseScale = 1
	local FastMotion = TweenInfo.new(0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Fallback cursor for games that hide or blank the system pointer (needs more testing)
	local virtualCursor = Make("ImageLabel", {
		Size = UDim2.new(0, 18, 0, 18),
		Image = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png",
		BackgroundTransparency = 1,
		ZIndex = 1000000,
		Visible = false,
		Parent = gui,
	}, { ImageColor3 = "Text" })

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
				local t = TweenService:Create(main, FastMotion, { Position = offPos })
				local ts = TweenService:Create(uiScale, FastMotion, { Scale = baseScale * 0.96 })
				t:Play(); ts:Play()
				t.Completed:Connect(function()
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
				local t = TweenService:Create(main, FastMotion, { Position = curPos })
				local ts = TweenService:Create(uiScale, FastMotion, { Scale = baseScale })
				t:Play(); ts:Play()
				t.Completed:Connect(function() isAnimating = false end)
			end
		end
		applyCursorState()
	end
	minBtn.Activated:Connect(toggleWindow)
	pill.Activated:Connect(function() if not dragMoved then toggleWindow() end end)

	local tabPages, tabBtns, tabLabels, tabActivators = {}, {}, {}, {}
	local activeIndex, lastUserIndex, settingsIndex = nil, nil, nil
	local window = {}

	function window:Destroy()
		for _, c in conns do c:Disconnect() end
		gui:Destroy()
	end
	closeBtn.Activated:Connect(function() window:Destroy() end)

	function window:Notify(text, duration)
		if not notificationsEnabled then return end
		local n = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = notifHolder }, { BackgroundColor3 = "Secondary" })
		corner(n, 8)
		local s = stroke(n, "Stroke", 1)
		pad(n, 14, 10)
		local l = Make("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = T.Label, TextWrapped = true, TextTransparency = 1, Text = text, Parent = n }, { TextColor3 = "Text" })

		tw(n, Motion.Panel, { BackgroundTransparency = 0 })
		tw(s, Motion.Panel, { Transparency = 0 })
		tw(l, Motion.Panel, { TextTransparency = 0 })

		task.delay(duration or 3, function()
			if not n.Parent then return end
			tw(n, Motion.Normal, { BackgroundTransparency = 1 })
			tw(s, Motion.Normal, { Transparency = 1 })
			tw(l, Motion.Normal, { TextTransparency = 1 })
			task.wait(0.2)
			n:Destroy()
		end)
	end

	-- Component Container Factory (shared by Tabs and Sections)
	local function createContainer(targetParent, registry, tabName)
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

			local section = createContainer(subFrame, registry, tabName)
			section.Instance = subFrame
			section.Header = header

			local function updateIndicator()
				local hasChildren = #subFrame:GetChildren() > 1
				holder.Visible = hasChildren
				header.Active = hasChildren
			end
			subFrame.ChildAdded:Connect(updateIndicator)
			subFrame.ChildRemoved:Connect(updateIndicator)

			setChevron(not collapsed)
			header.Activated:Connect(function()
				collapsed = not collapsed
				subFrame.Visible = not collapsed
				setChevron(not collapsed)
			end)

			function section:SetCollapsed(state)
				collapsed = state and true or false
				subFrame.Visible = not collapsed
				setChevron(not collapsed)
			end

			if builder then withScope(section, builder) end
			updateIndicator()

			return section
		end

		function container:Divider()
			local f = Make("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 1), Parent = targetParent }, { BackgroundColor3 = "Stroke" })
			return { Instance = f }
		end

		function container:Text(title, content, iconName)
			local f = Make("Frame", { LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = targetParent }, { BackgroundColor3 = "Secondary" })
			corner(f, 8)
			pad(f, 16, 14)
			local vl = Instance.new("UIListLayout", f)
			vl.Padding = UDim.new(0, 8)

			local head = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, T.Title + 4), Parent = f })
			local hl = Instance.new("UIListLayout", head)
			hl.FillDirection, hl.VerticalAlignment, hl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8)

			mkicon(iconName, "Text", head, UDim2.new(0, 18, 0, 18))
			local titleLbl = Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -26, 1, 0), FontWeight = "Bold", Text = title, TextSize = T.Title, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head }, { TextColor3 = "Text" })
			local contentLbl = Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = T.Body, TextWrapped = true, Text = content, Parent = f }, { TextColor3 = "SubText" })

			local handle = {
				Instance = f,
				Get = function() return contentLbl.Text end,
				Set = function(self, str)
					if str == nil and type(self) == "string" then str = self end
					contentLbl.Text = tostring(str or "")
				end,
				SetTitle = function(self, str)
					if str == nil and type(self) == "string" then str = self end
					titleLbl.Text = tostring(str or "")
				end,
			}
			return handle
		end

		function container:Button(text, callback, iconName)
			callback = callback or function() end
			local f = card(46)
			rowLabel(f, iconName, "Button", text, 0)
			local clickBtn = Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = f })
			local s = stroke(f, "Stroke", 0.7)
			hover(clickBtn, s, { Transparency = 0.2 }, { Transparency = 0.7 })
			clickBtn.Activated:Connect(function()
				tw(f, Motion.Fast, { BackgroundColor3 = Library.CurrentTheme.Accent })
				task.delay(0.12, function() tw(f, Motion.Normal, { BackgroundColor3 = Library.CurrentTheme.Secondary }) end)
				callback()
			end)

			local handle = {
				Instance = f,
				Fire = function() callback() end,
			}
			return handle
		end

		function container:Toggle(text, default, callback, iconName)
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

			local state = default and true or false
			bindTheme(sw, "BackgroundColor3", function(th) return state and th.Accent or th.Stroke end)

			local function apply(newState, imm)
				state = newState and true or false
				local pos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
				local col = state and Library.CurrentTheme.Accent or Library.CurrentTheme.Stroke
				if imm then circ.Position, sw.BackgroundColor3 = pos, col else
					tw(circ, Motion.Normal, { Position = pos })
					tw(sw, Motion.Normal, { BackgroundColor3 = col })
				end
				callback(state)
			end

			clickBtn.Activated:Connect(function() apply(not state); requestSave(registry) end)
			regConfig(registry, configKey("Toggle", text), state, function() return state end, function(v) if type(v) == "boolean" then apply(v, true) end end)

			local handle = {
				Instance = f,
				Get = function() return state end,
				Set = function(self, val)
					if val == nil and type(self) == "boolean" then val = self end
					apply(val)
					requestSave(registry)
				end,
			}
			return handle
		end

		function container:Slider(text, min, max, default, step, callback, iconName)
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
			local function setVisual(value, p)
				fill.Size = UDim2.new(p, 0, 1, 0)
				val.Text = fmt(value)
			end

			local function move(x)
				local p = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				local v = round(min + (max - min) * p)
				setVisual(v, p)
				if v ~= current then current = v; callback(v); requestSave(registry) end
			end

			bar.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					activeMove = function(pos) move(pos.X) end
					move(i.Position.X)
				end
			end)

			local function applyVal(v)
				v = round(math.clamp(v, min, max))
				current = v
				setVisual(v, (v - min) / (max - min))
				callback(v)
			end

			regConfig(registry, configKey("Slider", text), default, function() return current end, function(v)
				if type(v) == "number" then applyVal(v) end
			end)

			local handle = {
				Instance = f,
				Get = function() return current end,
				Set = function(self, v)
					if v == nil and type(self) == "number" then v = self end
					if type(v) == "number" then
						applyVal(v)
						requestSave(registry)
					end
				end,
			}
			return handle
		end

		function container:Dropdown(text, options, callback, default, iconName)
			if type(callback) ~= "function" and callback ~= nil then
				iconName, default, callback = default, callback, function() end
			else
				callback = callback or function() end
			end
			options = options or {}
			local multi = type(default) == "table"
			local selected = {}
			if multi then for _, v in default do selected[v] = true end else default = default or options[1] end

			local f = card(50)
			f.ClipsDescendants = true
			stroke(f, "Stroke", 0.7)

			local function getSelectedList()
				local list = {}
				for _, v in options do if selected[v] then table.insert(list, v) end end
				return list
			end

			local function getDisplayText()
				if not multi then return tostring(default or "Select...") end
				local list = getSelectedList()
				return #list == 0 and "Select..." or table.concat(list, ", ")
			end

			local head = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 50), Parent = f })
			rowLabel(head, iconName, "Dropdown", text, 170)

			local selector = Make("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 160, 0, 34),
				ClipsDescendants = true,
				Parent = head,
			}, { BackgroundColor3 = "Background" })
			corner(selector, 6)
			local selStroke = stroke(selector, "Stroke", 0.6)

			local selLabel = Make("TextLabel", {
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -28, 1, 0),
				Text = getDisplayText(),
				TextSize = T.Body,
				Parent = selector,
			}, { TextColor3 = "Text" })

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
			hover(clickBtn, selStroke, function() return { Color = Library.CurrentTheme.Accent, Transparency = 0.1 } end, function() return { Color = Library.CurrentTheme.Stroke, Transparency = 0.6 } end)

			local opened, optBtns = false, {}
			local function refresh()
				selLabel.Text = getDisplayText()
				updateAlign()
				for i, opt in optBtns do
					local v = options[i]
					local isSel = multi and selected[v] or (v == default)
					opt.BackgroundColor3 = isSel and Library.CurrentTheme.Accent or Library.CurrentTheme.Background
					opt.TextColor3 = isSel and Library.CurrentTheme.AccentText or Library.CurrentTheme.SubText
				end
			end

			local function build()
				for _, b in optBtns do b:Destroy() end
				table.clear(optBtns)
				for i, v in options do
					local opt = Make("TextButton", {
						LayoutOrder = i,
						Size = UDim2.new(1, 0, 0, 32),
						Text = tostring(v),
						TextSize = T.Body,
						Parent = listHolder,
					}, {
						BackgroundColor3 = function(th) return (multi and selected[v] or v == default) and th.Accent or th.Background end,
						TextColor3 = function(th) return (multi and selected[v] or v == default) and th.AccentText or th.SubText end,
					})
					corner(opt, 6)
					opt.Activated:Connect(function()
						if multi then
							selected[v] = not selected[v] or nil
							callback(getSelectedList())
						else
							default = v
							opened = false
							setChevron(false)
							tw(f, Motion.Normal, { Size = UDim2.new(1, 0, 0, 50) })
							callback(v)
						end
						refresh()
						requestSave(registry)
					end)
					optBtns[i] = opt
				end
			end
			build()

			clickBtn.Activated:Connect(function()
				opened = not opened
				setChevron(opened)
				tw(f, Motion.Normal, { Size = UDim2.new(1, 0, 0, opened and (#options * 38 + 58) or 50) })
			end)

			regConfig(registry, configKey("Dropdown", text), multi and getSelectedList() or default, function()
				return multi and getSelectedList() or default
			end, function(v)
				if multi and type(v) == "table" then
					table.clear(selected)
					for _, item in v do if table.find(options, item) then selected[item] = true end end
				elseif table.find(options, v) then
					default = v
				end
				refresh()
				callback(multi and getSelectedList() or default)
			end)

			local handle = {
				Instance = f,
				Get = function()
					return multi and getSelectedList() or default
				end,
				Set = function(self, v)
					if v == nil and (type(self) == "string" or type(self) == "table") and self ~= handle then v = self end
					if multi and type(v) == "table" then
						table.clear(selected)
						for _, item in v do if table.find(options, item) then selected[item] = true end end
					elseif table.find(options, v) then
						default = v
					end
					refresh()
					callback(multi and getSelectedList() or default)
					requestSave(registry)
				end,
				Refresh = function(self, newOpts)
					if newOpts == nil and type(self) == "table" and self ~= handle then newOpts = self end
					options = newOpts or {}
					build()
					refresh()
				end,
			}
			return handle
		end

		function container:Keybind(text, default, callback, iconName)
			callback = callback or function() end
			local f = card(46)
			rowLabel(f, iconName, "Keybind", text, 110)
			local bind = Make("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 0, 30),
				FontWeight = "Bold",
				Text = default and default.Name or "None",
				TextSize = T.Body,
				Parent = f,
			}, { BackgroundColor3 = "Background", TextColor3 = "Text" })
			corner(bind, 6)
			pad(bind, 8, 0)
			local bs = stroke(bind, "Stroke", 0.5)

			local key, listening = default, false
			bind.Activated:Connect(function()
				listening = true
				bind.Text = "..."
				tw(bs, Motion.Fast, { Color = Library.CurrentTheme.Accent, Transparency = 0 })
			end)

			conn(UserInputService.InputBegan, function(i, gpe)
				if listening and i.UserInputType == Enum.UserInputType.Keyboard then
					key = (i.KeyCode == Enum.KeyCode.Backspace or i.KeyCode == Enum.KeyCode.Escape) and nil or i.KeyCode
					bind.Text = key and key.Name or "None"
					listening = false
					tw(bs, Motion.Fast, { Color = Library.CurrentTheme.Stroke, Transparency = 0.5 })
					requestSave(registry)
				elseif not gpe and key and i.KeyCode == key then
					callback(key)
				end
			end)

			regConfig(registry, configKey("Keybind", text), default and default.Name or "None", function()
				return key and key.Name or "None"
			end, function(v)
				key = (type(v) == "string" and v ~= "None") and (pcall(function() return Enum.KeyCode[v] end) and Enum.KeyCode[v] or nil) or nil
				bind.Text = key and key.Name or "None"
			end)

			local handle = {
				Instance = f,
				Get = function() return key end,
				Set = function(self, newKey)
					if newKey == nil and (typeof(self) == "EnumItem" or type(self) == "string") then newKey = self end
					if typeof(newKey) == "EnumItem" and newKey.EnumType == Enum.KeyCode then
						key = newKey
					elseif type(newKey) == "string" then
						key = (newKey ~= "None" and pcall(function() return Enum.KeyCode[newKey] end) and Enum.KeyCode[newKey]) or nil
					else
						key = nil
					end
					bind.Text = key and key.Name or "None"
					requestSave(registry)
				end,
			}
			return handle
		end

		function container:Input(text, placeholder, callback, default, iconName)
			if type(placeholder) == "function" then
				callback, placeholder = placeholder, ""
			end
			callback = callback or function() end
			local f = card(50)
			rowLabel(f, iconName, "Input", text, 170)
			local box = Make("TextBox", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 160, 0, 34),
				PlaceholderText = placeholder or "",
				Text = default or "",
				TextSize = T.Body,
				ClipsDescendants = true,
				Parent = f,
			}, { BackgroundColor3 = "Background", TextColor3 = "Text", PlaceholderColor3 = "SubText" })
			corner(box, 6)
			pad(box, 10, 0)
			stroke(box, "Stroke", 0.6)

			local function updateAlign()
				local str = box.Text ~= "" and box.Text or box.PlaceholderText
				local isLong = isTextLong(str, T.Body, 140)
				box.TextXAlignment = isLong and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
			end

			box:GetPropertyChangedSignal("Text"):Connect(updateAlign)
			box.Focused:Connect(function() box.TextXAlignment = Enum.TextXAlignment.Left end)
			box.FocusLost:Connect(function()
				updateAlign()
				callback(box.Text)
				requestSave(registry)
			end)
			updateAlign()

			regConfig(registry, configKey("Input", text), default or "", function() return box.Text end, function(v)
				if type(v) == "string" then box.Text = v; updateAlign(); callback(v) end
			end)

			local handle = {
				Instance = f,
				Get = function() return box.Text end,
				Set = function(self, val)
					if val == nil and type(self) == "string" then val = self end
					box.Text = tostring(val or "")
					updateAlign()
					callback(box.Text)
					requestSave(registry)
				end,
			}
			return handle
		end

		function container:Color(text, default, callback, iconName)
			if type(default) == "function" then
				callback, default = default, Color3.fromRGB(255, 255, 255)
			end
			callback = callback or function() end
			local f = card(46)
			f.ClipsDescendants = true

			local head = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Parent = f })
			rowLabel(head, iconName, "Color", text, 48)

			local col = default or Color3.fromRGB(255, 255, 255)
			local h, s, v = col:ToHSV()

			local swatch = Make("TextButton", { BackgroundColor3 = col, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 34, 0, 22), Parent = head })
			corner(swatch, 6)
			local sws = stroke(swatch, "Stroke")
			hover(swatch, sws, function() return { Color = Library.CurrentTheme.Accent } end, function() return { Color = Library.CurrentTheme.Stroke } end)

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

			local chanBoxes = {}
			for idx, name in { "R", "G", "B" } do
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

			local function pickSatVal(pos)
				s = math.clamp((pos.X - map.AbsolutePosition.X) / map.AbsoluteSize.X, 0, 1)
				v = 1 - math.clamp((pos.Y - map.AbsolutePosition.Y) / map.AbsoluteSize.Y, 0, 1)
				updateVisuals(false)
			end

			local function pickHue(pos)
				h = math.clamp((pos.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
				updateVisuals(false)
			end

			map.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					activeMove = pickSatVal; pickSatVal(i.Position)
				end
			end)
			hueBar.InputBegan:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
					activeMove = pickHue; pickHue(i.Position)
				end
			end)

			hexBox.FocusLost:Connect(function()
				local ok, newCol = pcall(Color3.fromHex, hexBox.Text:gsub("#", ""))
				if ok and newCol then h, s, v = newCol:ToHSV(); updateVisuals(false); requestSave(registry) else hexBox.Text = "#" .. col:ToHex():upper() end
			end)

			local function commitRgb()
				local r = math.clamp(tonumber(chanBoxes.R.Text) or 0, 0, 255)
				local g = math.clamp(tonumber(chanBoxes.G.Text) or 0, 0, 255)
				local b = math.clamp(tonumber(chanBoxes.B.Text) or 0, 0, 255)
				h, s, v = Color3.fromRGB(r, g, b):ToHSV()
				updateVisuals(false)
				requestSave(registry)
			end
			for _, b in chanBoxes do b.FocusLost:Connect(commitRgb) end

			local opened = false
			swatch.Activated:Connect(function()
				opened = not opened
				content.Visible = opened
				tw(f, Motion.Normal, { Size = UDim2.new(1, 0, 0, opened and 184 or 46) })
			end)

			regConfig(registry, configKey("Color", text), { R = math.floor(col.R * 255 + 0.5), G = math.floor(col.G * 255 + 0.5), B = math.floor(col.B * 255 + 0.5) }, function()
				return { R = math.floor(col.R * 255 + 0.5), G = math.floor(col.G * 255 + 0.5), B = math.floor(col.B * 255 + 0.5) }
			end, function(val)
				local res = typeof(val) == "Color3" and val or (type(val) == "table" and val.R and Color3.fromRGB(val.R, val.G or 0, val.B or 0)) or (type(val) == "string" and pcall(Color3.fromHex, val:gsub("#", "")) and Color3.fromHex(val:gsub("#", "")))
				if res then h, s, v = res:ToHSV(); updateVisuals(false) end
			end)

			local handle = {
				Instance = f,
				Get = function() return col end,
				Set = function(self, val)
					if val == nil and (typeof(self) == "Color3" or type(self) == "table" or type(self) == "string") then val = self end
					local res = typeof(val) == "Color3" and val or (type(val) == "table" and val.R and Color3.fromRGB(val.R, val.G or 0, val.B or 0)) or (type(val) == "string" and pcall(Color3.fromHex, val:gsub("#", "")) and Color3.fromHex(val:gsub("#", "")))
					if res then
						h, s, v = res:ToHSV()
						updateVisuals(false)
						requestSave(registry)
					end
				end,
			}
			return handle
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
		}, {
			BackgroundColor3 = function(th) return activeIndex == tabIndex and th.Accent or th.Secondary end,
		})
		corner(btn, isSide and 7 or 19)
		pad(btn, isSide and 10 or 14, 0)

		local bl = Instance.new("UIListLayout", btn)
		bl.FillDirection, bl.VerticalAlignment, bl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8)
		mkicon(tabIcon, "Tab", btn, UDim2.new(0, 16, 0, 16))

		local label = Make("TextLabel", {
			LayoutOrder = 2,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = isSide and UDim2.new(1, -24, 1, 0) or UDim2.new(0, 0, 1, 0),
			Text = tabName,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = btn,
		}, {
			TextColor3 = function(th) return activeIndex == tabIndex and th.AccentText or th.SubText end,
		})

		local page = Make("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Visible = false,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = pageHolder,
		})
		styleScroll(page, false)

		local pl = Instance.new("UIListLayout", page)
		pl.SortOrder, pl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 10)

		local function activate()
			activeIndex = tabIndex
			if not isSettings then lastUserIndex = tabIndex end
			for i, p in tabPages do
				local isCur = (i == activeIndex)
				p.Visible = isCur
				if tabBtns[i].Visible then
					tabBtns[i].BackgroundColor3 = isCur and Library.CurrentTheme.Accent or Library.CurrentTheme.Secondary
					tabLabels[i].TextColor3 = isCur and Library.CurrentTheme.AccentText or Library.CurrentTheme.SubText
				end
			end
		end

		local function hoverTab(b, l, index)
			conn(b.MouseEnter, function()
				if activeIndex ~= index then
					tw(b, Motion.Fast, { BackgroundColor3 = Library.CurrentTheme.Accent })
					tw(l, Motion.Fast, { TextColor3 = Library.CurrentTheme.AccentText })
				end
			end)
			conn(b.MouseLeave, function()
				if activeIndex ~= index then
					tw(b, Motion.Fast, { BackgroundColor3 = Library.CurrentTheme.Secondary })
					tw(l, Motion.Fast, { TextColor3 = Library.CurrentTheme.SubText })
				end
			end)
		end
		btn.Activated:Connect(activate)
		hoverTab(btn, label, tabIndex)

		tabPages[tabIndex], tabBtns[tabIndex], tabLabels[tabIndex], tabActivators[tabIndex] = page, btn, label, activate
		if isSettings then settingsIndex = tabIndex elseif not lastUserIndex then activate() end

		local tab = createContainer(page, registry, tabName)
		tab.Instance = page
		tab.Button = btn

		if tabBuilder then withScope(tab, tabBuilder) end
		return tab
	end

	function window:Tab(name, icon, tabBuilder)
		return createTab(name, icon, GameConfig, tabBuilder)
	end

	-- Settings Tab
	local settingsTab = createTab("Settings", Icons.Settings, KvantConfig)
	settingsTab:Section("Interface", false, function(s)
		s:Dropdown("Theme", { "Darker", "Dark", "Vesper", "Light", "SolorizedLight" }, function(v) Library:SetTheme(v) end, "Darker")
		s:Dropdown("Font", { "Inter", "Roboto", "Ubuntu" }, function(v) Library:SetFont(v) end, "Roboto")
		s:Slider("UI Scale", 80, 120, 100, 1, function(v) baseScale = v / 100; if not minimized then uiScale.Scale = baseScale end end)
		s:Toggle("Show Icons", true, function(st)
			iconsOn = st
			for _, ic in icons do ic.inst.Visible = st end
			for _, ind in indicators do
				ind.img.Visible = st
				ind.txt.Visible = not st
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
				for _, entry in GameConfig do pcall(entry.set, entry.default) end
				requestSave(GameConfig)
			end)
		end
	end)

	settingsBtn.Activated:Connect(function()
		if activeIndex == settingsIndex then
			if lastUserIndex and tabActivators[lastUserIndex] then tabActivators[lastUserIndex]() end
		else
			tabActivators[settingsIndex]()
		end
	end)

	if supported then
		task.defer(function()
			ensureFolders()
			applyConfig(KvantConfig, KVANT_FILE)
			if autoload then applyConfig(GameConfig, gameFile(GameId)) end
		end)
	end

	if builder then withScope(window, builder) end
	return window
end

return Library