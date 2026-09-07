-- TODO:
-- feat: runtime theme changing
-- feat: custom themes validation
-- feat: auto inverse icon color depen on theme (dark or light) palette
-- fix: toggle off icons not working

-- LATER TODO:
-- fix: uncollapse animation
-- feat: auto-cache and auto-update when needed from github.
-- feat: add customasset to bypass detection.
-- style: code still messy (check conn).
-- style: find chevron icons in buildericons
-- chore: API validation

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

-- TODO: runtime font Changing???
-- 12187365364 - Inter
-- rbxasset://fonts/families/Roboto.json

Library.Config = {
	Text = { Title = 18, Label = 17, Body = 16, Small = 15 },
	Fonts = {
		Bold = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold),
		Medium = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
		Regular = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular),
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
		Background = Color3.fromRGB(24, 24, 27),
		Secondary = Color3.fromRGB(34, 34, 39),
		Accent = Color3.fromRGB(34, 197, 94),
		Stroke = Color3.fromRGB(50, 50, 58),
		Text = Color3.fromRGB(245, 245, 247),
		SubText = Color3.fromRGB(160, 160, 170),
		AccentText = Color3.fromRGB(255, 255, 255),
		Icon = Color3.fromRGB(245, 245, 247),
		IconMuted = Color3.fromRGB(160, 160, 170),
	},
	Darker = {
		Background = Color3.fromRGB(9, 9, 11),
		Secondary = Color3.fromRGB(18, 18, 22),
		Accent = Color3.fromRGB(34, 197, 94),
		Stroke = Color3.fromRGB(32, 32, 38),
		Text = Color3.fromRGB(240, 240, 243),
		SubText = Color3.fromRGB(140, 140, 150),
		AccentText = Color3.fromRGB(255, 255, 255),
		Icon = Color3.fromRGB(240, 240, 243),
		IconMuted = Color3.fromRGB(140, 140, 150),
	},
	Vesper = { -- github.com/michaljach/vesper-black
		Background = Color3.fromRGB(16, 16, 16),
		Secondary = Color3.fromRGB(24, 24, 24),
		Accent = Color3.fromRGB(255, 199, 153),
		Stroke = Color3.fromRGB(40, 40, 40),
		Text = Color3.fromRGB(255, 255, 255),
		SubText = Color3.fromRGB(160, 160, 160),
		AccentText = Color3.fromRGB(16, 16, 16),
		Icon = Color3.fromRGB(255, 255, 255),
		IconMuted = Color3.fromRGB(160, 160, 160),
	},
	Light = { -- github.com/miguelsolorio/min-theme
		Background = Color3.fromRGB(246, 246, 246),
		Secondary = Color3.fromRGB(255, 255, 255),
		Accent = Color3.fromRGB(25, 118, 210),
		Stroke = Color3.fromRGB(225, 225, 228),
		Text = Color3.fromRGB(33, 33, 33),
		SubText = Color3.fromRGB(117, 117, 117),
		AccentText = Color3.fromRGB(255, 255, 255),
		Icon = Color3.fromRGB(33, 33, 33),
		IconMuted = Color3.fromRGB(140, 140, 140),
	},
}
Library.Themes = BuiltInThemes
Library.CurrentTheme = BuiltInThemes.Darker

function Library:SetTheme(theme)
	Library.CurrentTheme = typeof(theme) == "table" and theme or Library.Themes[theme] or Library.CurrentTheme
end

local Icons = {
	Kvant = "rbxassetid://73167696981648", -- atom
	Tab = "rbxassetid://91943941515944", -- layout-panel-top
	Button = "rbxassetid://107150227368485", -- mouse-pointer-click
	Toggle = "rbxassetid://90411952142550", -- toggle-right
	Slider = "rbxassetid://85538382643347", -- sliders-horizontal
	Keybind = "rbxassetid://121474456068237", -- keyboard
	Text = "rbxassetid://133543553793564", -- type
	Settings = "rbxassetid://80758916183665", -- settings
	Dropdown = "rbxassetid://134243273101015", -- chevron-down
	Color = "rbxassetid://86350350950064", -- palette
	Input = "rbxassetid://107551944047171", -- text-cursor-input
}

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

local function stroke(p, col, trans)
	local s = Instance.new("UIStroke", p)
	s.Color, s.Transparency = col, trans or 0
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

function Library:CreateWindow(optOrName, sideTabs, customTheme, customSize, iconId)
	local opt = type(optOrName) == "table" and optOrName or {
		Name = optOrName or "Kvant",
		SideTabs = sideTabs,
		Theme = customTheme,
		Size = customSize,
		Icon = iconId,
	}

	if opt.Theme then Library:SetTheme(opt.Theme) end
	local theme = Library.CurrentTheme
	local T, F, Motion = Library.Config.Text, Library.Config.Fonts, Library.Config.Motion
	local isSide = opt.SideTabs or false

	local Defaults = {
		Frame = { BorderSizePixel = 0 },
		ScrollingFrame = { BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0) },
		TextLabel = { BackgroundTransparency = 1, BorderSizePixel = 0, FontFace = F.Medium, TextColor3 = theme.Text, TextSize = T.Label, TextXAlignment = Enum.TextXAlignment.Left },
		TextButton = { BorderSizePixel = 0, AutoButtonColor = false, Text = "" },
		TextBox = { BorderSizePixel = 0, ClearTextOnFocus = false, FontFace = F.Medium, TextColor3 = theme.Text, TextSize = T.Body, PlaceholderColor3 = theme.SubText },
		ImageLabel = { BackgroundTransparency = 1, BorderSizePixel = 0 },
		ImageButton = { BackgroundTransparency = 1, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Fit },
	}

	local function Make(class, props)
		local inst = Instance.new(class)
		inst.Name = getName()
		local d = Defaults[class]
		if d then for k, v in d do inst[k] = v end end
		for k, v in props do if k ~= "Parent" then inst[k] = v end end
		if props.Parent then inst.Parent = props.Parent end
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
		conn(btn.MouseEnter, function() tw(target, Motion.Fast, enterProps) end)
		conn(btn.MouseLeave, function() tw(target, Motion.Fast, leaveProps) end)
	end

	local function mkicon(id, kind, parent, size, isMuted)
		local imgId = id == nil and Icons[kind] or id
		if not imgId then return end
		local iconColor = (isMuted and Library.CurrentTheme.IconMuted) or Library.CurrentTheme.Icon
		local img = Make("ImageLabel", { LayoutOrder = 1, Size = size, Image = imgId,ImageColor3 = iconColor, Visible = iconsOn, Parent = parent })
		table.insert(icons, { Instance = img, Muted = isMuted or false })
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
			ImageColor3 = theme.SubText,
			Visible = iconsOn,
			Parent = holder,
		})
		local txt = Make("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),
			FontFace = F.Icons,
			Text = "",
			TextSize = T.Small,
			TextColor3 = theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Center,
			Visible = not iconsOn,
			Parent = holder,
		})
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
		table.insert(icons, img)
		return holder, setOpen
	end

	local function styleScroll(f, horiz)
		f.ScrollBarThickness = 3
		f.ScrollBarImageColor3 = theme.SubText
		f.ScrollBarImageTransparency = 0.25
		if horiz then f.HorizontalScrollBarInset = Enum.ScrollBarInset.Always else f.VerticalScrollBarInset = Enum.ScrollBarInset.Always end
	end

	-- Universal Input Dragging
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
		BackgroundColor3 = theme.Background,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = winSize,
		Active = true,
		ClipsDescendants = true,
		Parent = gui,
	})
	local defaultPosition = main.Position
	corner(main, 10)
	stroke(main, theme.Stroke)

	local mainConstraint = Instance.new("UISizeConstraint", main)
	mainConstraint.MinSize = opt.MinSize or (isSide and Vector2.new(460, 400) or Vector2.new(320, 400))
	mainConstraint.MaxSize = opt.MaxSize or (isSide and Vector2.new(620, 560) or Vector2.new(420, 520))

	local uiScale = Instance.new("UIScale", main)
	local notifHolder = Make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 260, 1, -32), Parent = gui })
	local notifLayout = Instance.new("UIListLayout", notifHolder)
	notifLayout.VerticalAlignment, notifLayout.HorizontalAlignment, notifLayout.Padding = Enum.VerticalAlignment.Bottom, Enum.HorizontalAlignment.Right, UDim.new(0, 8)

	-- Topbar
	local topbar = Make("Frame", { BackgroundColor3 = theme.Secondary, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), ZIndex = 5, Parent = main })
	corner(topbar, 10)

	local titleRow = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 16, 0, 0), Parent = topbar })
	local trl = Instance.new("UIListLayout", titleRow)
	trl.FillDirection, trl.VerticalAlignment, trl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 10)

	mkicon(opt.Icon, "Kvant", titleRow, UDim2.new(0, 20, 0, 20))
	Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -30, 1, 0), FontFace = F.Bold, Text = opt.Name or "Kvant", TextSize = T.Title, TextTruncate = Enum.TextTruncate.AtEnd, Parent = titleRow })

	local controls = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 0, 1, 0), Position = UDim2.new(1, -12, 0, 0), Parent = topbar })
	local ctrlList = Instance.new("UIListLayout", controls)
	ctrlList.FillDirection, ctrlList.VerticalAlignment, ctrlList.HorizontalAlignment, ctrlList.SortOrder, ctrlList.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, Enum.HorizontalAlignment.Right, Enum.SortOrder.LayoutOrder, UDim.new(0, 10)

	local settingsBtn = Make("ImageButton", { Size = UDim2.new(0, 20, 0, 20), Image = Icons.Settings, ImageColor3 = theme.Text, LayoutOrder = 1, Parent = controls })
	local minBtn = Make("ImageButton", { Size = UDim2.new(0, 20, 0, 20), Image = "rbxassetid://10137941941", ImageColor3 = theme.Text, LayoutOrder = 2, Parent = controls })
	local closeBtn = Make("ImageButton", { Size = UDim2.new(0, 22, 0, 22), Image = "rbxassetid://10137832201", ImageColor3 = theme.Text, Visible = false, LayoutOrder = 3, Parent = controls })

	for _, btn in { settingsBtn, minBtn, closeBtn } do
		hover(btn, btn, { ImageColor3 = theme.Accent }, { ImageColor3 = theme.Icon })
	end
	makeDraggable(main, topbar)

	-- Minimized Pill
	local pill = Make("TextButton", {
		BackgroundColor3 = theme.Secondary,
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.04, 0),
		Size = UDim2.new(0, 0, 0, 36),
		AutomaticSize = Enum.AutomaticSize.X,
		Parent = gui,
	})
	corner(pill, 18)
	pad(pill, 16, 0)
	local pillConstraint = Instance.new("UISizeConstraint", pill)
	pillConstraint.MinSize, pillConstraint.MaxSize = Vector2.new(110, 36), Vector2.new(280, 36)

	local layout = Instance.new("UIListLayout", pill)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center

	local label = Make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = opt.Name or "Kvant",
		FontFace = F.Medium,
		TextSize = T.Label,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = pill,
	})
	local labelConstraint = Instance.new("UISizeConstraint", label)
	labelConstraint.MaxSize = Vector2.new(248, math.huge) -- MaxSize.X = 280 - horizontal padding (16 * 2 = 32) -> 248
	local pillStroke = stroke(pill, theme.Stroke)
	hover(pill, pillStroke, { Color = theme.Accent }, { Color = theme.Stroke })
	makeDraggable(pill)

	-- Window Layouts
	local tabHolder, pageHolder
	if isSide then
		tabHolder = Make("ScrollingFrame", {
			BackgroundColor3 = theme.Secondary,
			Position = UDim2.new(0, 0, 0, 44),
			Size = UDim2.new(0.30, 0, 1, -44),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = main,
		})
		corner(tabHolder, 10)
		styleScroll(tabHolder, false)
		pad(tabHolder, 0, 10)

		local tabList = Instance.new("UIListLayout", tabHolder)
		tabList.SortOrder, tabList.HorizontalAlignment, tabList.Padding = Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Center, UDim.new(0, 6)

		Make("Frame", { BackgroundColor3 = theme.Stroke, Position = UDim2.new(0.30, 0, 0, 44), Size = UDim2.new(0, 1, 1, -44), Parent = main })
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
	local minimized, unlockCursor, savedMouseBehavior = false, false, nil
	local function applyCursorState()
		if unlockCursor and not minimized then
			savedMouseBehavior = savedMouseBehavior or UserInputService.MouseBehavior
			task.spawn(function()
				while unlockCursor and not minimized do
					UserInputService.MouseBehavior = Enum.MouseBehavior.Default
					task.wait()
				end
				if savedMouseBehavior then
					UserInputService.MouseBehavior = savedMouseBehavior
					savedMouseBehavior = nil
				end
			end)
		elseif savedMouseBehavior then
			UserInputService.MouseBehavior = savedMouseBehavior
			savedMouseBehavior = nil
		end
	end

	local function toggleWindow()
		minimized = not minimized
		if minimized then
			tw(main, Motion.Normal, { BackgroundTransparency = 1 })
			main.Visible, pill.Visible = false, true
		else
			main.Visible = true
			main.Size = UDim2.new(winSize.X.Scale, winSize.X.Offset, 0, 44)
			pill.Visible = false
			tw(main, Motion.Normal, { BackgroundTransparency = 0, Size = winSize })
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
		local n = Make("Frame", { BackgroundColor3 = theme.Secondary, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = notifHolder })
		corner(n, 8)
		local s = stroke(n, theme.Stroke, 1)
		pad(n, 14, 10)
		local l = Make("TextLabel", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextSize = T.Label, TextWrapped = true, TextTransparency = 1, Text = text, Parent = n })

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

	local function createTab(tabName, tabIcon, registry)
		local tabIndex = #tabPages + 1
		local isSettings = registry == KvantConfig

		local btn = Make("TextButton", {
			BackgroundColor3 = theme.Secondary,
			Size = isSide and UDim2.new(0.9, 0, 0, 36) or UDim2.new(0, 0, 0, 38),
			AutomaticSize = isSide and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
			LayoutOrder = tabIndex,
			Visible = not isSettings,
			Parent = tabHolder,
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
			TextColor3 = theme.SubText,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = btn,
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
			for i, p in tabPages do
				p.Visible = false
				tabLabels[i].TextColor3 = theme.SubText
				if tabBtns[i].Visible then tabBtns[i].BackgroundColor3 = theme.Secondary end
			end
			page.Visible = true
			activeIndex = tabIndex
			if btn.Visible then
				label.TextColor3 = theme.AccentText
				btn.BackgroundColor3 = theme.Accent
			end
			if not isSettings then lastUserIndex = tabIndex end
		end

		-- TODO: refactor later
		local function hoverTab(btn, label, index)
			conn(btn.MouseEnter, function()
				if activeIndex ~= index then
					tw(btn, Motion.Fast, {
						BackgroundColor3 = theme.Accent
					})
					tw(label, Motion.Fast, {
						TextColor3 = theme.AccentText
					})
				end
			end)
			conn(btn.MouseLeave, function()
				if activeIndex ~= index then
					tw(btn, Motion.Fast, {
						BackgroundColor3 = theme.Secondary
					})
					tw(label, Motion.Fast, {
						TextColor3 = theme.SubText
					})
				end
			end)
		end
		btn.Activated:Connect(activate)
		hoverTab(btn, label, tabIndex)

		tabPages[tabIndex], tabBtns[tabIndex], tabLabels[tabIndex], tabActivators[tabIndex] = page, btn, label, activate
		if isSettings then settingsIndex = tabIndex elseif not lastUserIndex then activate() end

		-- Component Builders
		local tab, order = {}, 0
		local targetParent = page
		local function nextOrder() order += 1; return order end
		local function configKey(kind, name) return tabName .. ">" .. kind .. ":" .. name end

		local function card(h)
			local f = Make("Frame", { LayoutOrder = nextOrder(), BackgroundColor3 = theme.Secondary, Size = UDim2.new(1, 0, 0, h), Parent = targetParent })
			corner(f, 8)
			pad(f, 16, 0)
			return f
		end

		local function rowLabel(parent, iconName, kind, text, rGap)
			local row = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -(rGap or 0), 1, 0), Parent = parent })
			local rl = Instance.new("UIListLayout", row)
			rl.FillDirection, rl.VerticalAlignment, rl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 10)
			mkicon(iconName, kind, row, UDim2.new(0, 16, 0, 16))
			Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -26, 1, 0), Text = text, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
		end

		function tab:Section(text, collapsed, builder)
			if type(collapsed) == "function" then builder, collapsed = collapsed, false end
			collapsed = collapsed and true or false

			local header = Make("TextButton", { BackgroundTransparency = 1, LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 24), Parent = targetParent })
			local hl = Instance.new("UIListLayout", header)
			hl.FillDirection, hl.VerticalAlignment, hl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 6)

			local holder, setChevron = newIndicator(header, false)
			Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -20, 1, 0), FontFace = F.Bold, Text = text, TextColor3 = theme.SubText, Parent = header })

			local container = Make("Frame", { BackgroundTransparency = 1, LayoutOrder = nextOrder(), AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0), Visible = not collapsed, Parent = targetParent })
			local cl = Instance.new("UIListLayout", container)
			cl.SortOrder, cl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 10)

			if builder then
				local oldP, oldO = targetParent, order
				targetParent, order = container, 0
				builder(tab)
				targetParent, order = oldP, oldO
			end

			if #container:GetChildren() < 2 then -- No items, can't be collapsible
				holder.Visible = false
				header.Active = false
			end

			setChevron(not collapsed)
			header.Activated:Connect(function()
				collapsed = not collapsed
				container.Visible = not collapsed
				setChevron(not collapsed)
			end)
		end

		function tab:Divider()
			Make("Frame", { LayoutOrder = nextOrder(), BackgroundColor3 = theme.Stroke, Size = UDim2.new(1, 0, 0, 1), Parent = targetParent })
		end

		function tab:Text(title, content, iconName)
			local f = Make("Frame", { LayoutOrder = nextOrder(), BackgroundColor3 = theme.Secondary, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = targetParent })
			corner(f, 8)
			pad(f, 16, 14)
			local vl = Instance.new("UIListLayout", f)
			vl.Padding = UDim.new(0, 8)

			local head = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, T.Title + 4), Parent = f })
			local hl = Instance.new("UIListLayout", head)
			hl.FillDirection, hl.VerticalAlignment, hl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8)

			mkicon(iconName, "Text", head, UDim2.new(0, 18, 0, 18))
			Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, -26, 1, 0), FontFace = F.Bold, Text = title, TextSize = T.Title, TextTruncate = Enum.TextTruncate.AtEnd, Parent = head })
			Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextColor3 = theme.SubText, TextSize = T.Body, TextWrapped = true, Text = content, Parent = f })
		end

		function tab:Button(text, callback, iconName)
			local f = card(46)
			rowLabel(f, iconName, "Button", text, 0)
			local clickBtn = Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = f })
			local s = stroke(f, theme.Stroke, 0.7)
			hover(clickBtn, s, { Transparency = 0.2 }, { Transparency = 0.7 })
			clickBtn.Activated:Connect(function()
				tw(f, Motion.Fast, { BackgroundColor3 = theme.Accent })
				task.delay(0.12, function() tw(f, Motion.Normal, { BackgroundColor3 = theme.Secondary }) end)
				callback()
			end)
		end

		function tab:Toggle(text, default, callback, iconName)
			local f = card(46)
			rowLabel(f, iconName, "Toggle", text, 46)
			local sw = Make("Frame", { BackgroundColor3 = default and theme.Accent or theme.Stroke, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 40, 0, 22), Parent = f })
			corner(sw, 11)
			local circ = Make("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8), Size = UDim2.new(0, 16, 0, 16), Parent = sw })
			corner(circ, 8)

			local clickBtn = Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = f })
			local s = stroke(f, theme.Stroke, 0.7)
			hover(clickBtn, s, { Transparency = 0.2 }, { Transparency = 0.7 })

			local state = default and true or false
			local function apply(newState, imm)
				state = newState
				local pos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
				local col = state and theme.Accent or theme.Stroke
				if imm then circ.Position, sw.BackgroundColor3 = pos, col else
					tw(circ, Motion.Normal, { Position = pos })
					tw(sw, Motion.Normal, { BackgroundColor3 = col })
				end
				callback(state)
			end

			clickBtn.Activated:Connect(function() apply(not state); requestSave(registry) end)
			regConfig(registry, configKey("Toggle", text), state, function() return state end, function(v) if type(v) == "boolean" then apply(v, true) end end)
		end

		function tab:Slider(text, min, max, default, step, callback, iconName)
			if type(step) == "function" then callback, step = step, 1 else step = step or 1 end
			local decimals = decimalsOf(step)
			local mult = 10 ^ decimals
			local function round(v) return math.floor((math.floor((v - min) / step + 0.5) * step + min) * mult + 0.5) / mult end
			local function fmt(v) return decimals > 0 and string.format("%." .. decimals .. "f", v) or tostring(v) end

			default = round(default)
			local f = card(70)
			local row = Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 10), Size = UDim2.new(1, 0, 0, 22), Parent = f })
			local rl = Instance.new("UIListLayout", row)
			rl.FillDirection, rl.VerticalAlignment, rl.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8)

			mkicon(iconName, "Slider", row, UDim2.new(0, 14, 0, 14))
			Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(0.6, 0, 1, 0), Text = text, Parent = row })

			local val = Make("TextLabel", { Size = UDim2.new(0.3, 0, 0, 22), Position = UDim2.new(0.7, 0, 0, 10), FontFace = F.Bold, Text = fmt(default), TextColor3 = theme.Accent, TextXAlignment = Enum.TextXAlignment.Right, Parent = f })
			local bar = Make("Frame", { BackgroundColor3 = theme.Stroke, Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 0, 6), Parent = f })
			corner(bar, 3)

			local fill = Make("Frame", { BackgroundColor3 = theme.Accent, Size = UDim2.new((default - min) / (max - min), 0, 1, 0), Parent = bar })
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

			regConfig(registry, configKey("Slider", text), default, function() return current end, function(v)
				if type(v) == "number" then
					v = round(math.clamp(v, min, max))
					current = v
					setVisual(v, (v - min) / (max - min))
					callback(v)
				end
			end)
		end

		function tab:Dropdown(text, options, callback, default, iconName)
			local multi = type(default) == "table"
			local selected = {}
			if multi then for _, v in default do selected[v] = true end else default = default or options[1] end

			local f = card(46)
			f.ClipsDescendants = true
			local s = stroke(f, theme.Stroke, 0.7)

			local function getSelectedList()
				local list = {}
				for _, v in options do if selected[v] then table.insert(list, v) end end
				return list
			end

			local function getLabel()
				if not multi then return text .. ": " .. tostring(default) end
				local list = getSelectedList()
				return text .. ": " .. (#list == 0 and "None" or table.concat(list, ", "))
			end

			local head = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Parent = f })
			rowLabel(head, iconName, nil, getLabel(), 40)
			local _, setChevron = newIndicator(head, true)

			local listHolder = Make("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 46), Size = UDim2.new(1, 0, 0, 0), Parent = f })
			local vl = Instance.new("UIListLayout", listHolder)
			vl.SortOrder, vl.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0, 6)

			local clickBtn = Make("TextButton", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = f })
			hover(clickBtn, s, { Transparency = 0.2 }, { Transparency = 0.7 })

			local opened, optBtns = false, {}
			local function refresh()
				head:FindFirstChildOfClass("Frame"):FindFirstChildOfClass("TextLabel").Text = getLabel()
				for i, opt in optBtns do
					local v = options[i]
					local isSel = multi and selected[v] or (v == default)
					opt.BackgroundColor3 = isSel and theme.Accent or theme.Background
					opt.TextColor3 = isSel and theme.AccentText or theme.SubText
				end
			end

			local function build()
				for _, b in optBtns do b:Destroy() end
				table.clear(optBtns)
				for i, v in options do
					local isSel = multi and selected[v] or (v == default)
					local opt = Make("TextButton", {
						LayoutOrder = i,
						BackgroundColor3 = isSel and theme.Accent or theme.Background,
						Size = UDim2.new(1, 0, 0, 32),
						FontFace = F.Medium,
						Text = tostring(v),
						TextColor3 = isSel and theme.AccentText or theme.SubText,
						TextSize = T.Body,
						Parent = listHolder,
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
							tw(f, Motion.Normal, { Size = UDim2.new(1, 0, 0, 46) })
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
				tw(f, Motion.Normal, { Size = UDim2.new(1, 0, 0, opened and (#options * 38 + 52) or 46) })
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

			local dd = {}
			function dd:Refresh(newOpts)
				options = newOpts
				build()
				refresh()
			end
			return dd
		end

		function tab:Keybind(text, default, callback, iconName)
			local f = card(46)
			rowLabel(f, iconName, "Keybind", text, 110)
			local bind = Make("TextButton", {
				BackgroundColor3 = theme.Background,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 0, 30),
				FontFace = F.Bold,
				Text = default and default.Name or "None",
				TextColor3 = theme.Text,
				TextSize = T.Body,
				Parent = f,
			})
			corner(bind, 6)
			pad(bind, 8, 0)
			local bs = stroke(bind, theme.Stroke, 0.5)

			local key, listening = default, false
			bind.Activated:Connect(function()
				listening = true
				bind.Text = "..."
				tw(bs, Motion.Fast, { Color = theme.Accent, Transparency = 0 })
			end)

			conn(UserInputService.InputBegan, function(i, gpe)
				if listening and i.UserInputType == Enum.UserInputType.Keyboard then
					key = (i.KeyCode == Enum.KeyCode.Backspace or i.KeyCode == Enum.KeyCode.Escape) and nil or i.KeyCode
					bind.Text = key and key.Name or "None"
					listening = false
					tw(bs, Motion.Fast, { Color = theme.Stroke, Transparency = 0.5 })
					requestSave(registry)
				elseif not gpe and key and i.KeyCode == key then
					callback()
				end
			end)

			regConfig(registry, configKey("Keybind", text), default and default.Name or "None", function()
				return key and key.Name or "None"
			end, function(v)
				key = (type(v) == "string" and v ~= "None") and (pcall(function() return Enum.KeyCode[v] end) and Enum.KeyCode[v] or nil) or nil
				bind.Text = key and key.Name or "None"
			end)
		end

		function tab:Input(text, placeholder, callback, default, iconName)
			local f = card(50)
			rowLabel(f, iconName, "Input", text, 150)
			local box = Make("TextBox", {
				BackgroundColor3 = theme.Background,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 160, 0, 34),
				PlaceholderText = placeholder or "",
				Text = default or "",
				TextSize = T.Body,
				ClipsDescendants = true,
				Parent = f,
			})
			corner(box, 6)
			pad(box, 10, 0)

			box.FocusLost:Connect(function()
				callback(box.Text)
				requestSave(registry)
			end)

			regConfig(registry, configKey("Input", text), default or "", function() return box.Text end, function(v)
				if type(v) == "string" then box.Text = v; callback(v) end
			end)
		end

		function tab:Color(text, default, callback, iconName)
			local f = card(46)
			f.ClipsDescendants = true

			local head = Make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Parent = f })
			rowLabel(head, iconName, "Color", text, 48)

			local col = default or Color3.fromRGB(255, 255, 255)
			local h, s, v = col:ToHSV()

			local swatch = Make("TextButton", { BackgroundColor3 = col, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.new(0, 34, 0, 22), Parent = head })
			corner(swatch, 6)
			local sws = stroke(swatch, theme.Stroke)
			hover(swatch, sws, { Color = theme.Accent }, { Color = theme.Stroke })

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
			stroke(satCursor, Color3.new(0, 0, 0), 0.3)

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
			stroke(hueCursor, Color3.new(0, 0, 0), 0.4)

			local inRow = Make("Frame", { LayoutOrder = 3, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Parent = content })
			local irl = Instance.new("UIListLayout", inRow)
			irl.FillDirection, irl.Padding = Enum.FillDirection.Horizontal, UDim.new(0, 6)

			local hexBox = Make("TextBox", { LayoutOrder = 1, BackgroundColor3 = theme.Background, Size = UDim2.new(0.4, -4, 1, 0), Text = "#" .. col:ToHex():upper(), TextSize = T.Small, TextXAlignment = Enum.TextXAlignment.Center, Parent = inRow })
			corner(hexBox, 6)
			stroke(hexBox, theme.Stroke, 0.6)

			local chanBoxes = {}
			for idx, name in { "R", "G", "B" } do
				local b = Make("TextBox", { LayoutOrder = idx + 1, BackgroundColor3 = theme.Background, Size = UDim2.new(0.2, -4, 1, 0), PlaceholderText = name, Text = tostring(math.floor(col[name] * 255 + 0.5)), TextSize = T.Small, TextXAlignment = Enum.TextXAlignment.Center, Parent = inRow })
				corner(b, 6)
				stroke(b, theme.Stroke, 0.6)
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
		end

		return tab
	end

	function window:Tab(name, icon) return createTab(name, icon, GameConfig) end

	-- Settings Tab
	local settingsTab = createTab("Settings", Icons.Settings, KvantConfig)
	settingsTab:Section("Interface", false, function(s)
		s:Slider("UI Scale", 80, 120, 100, 1, function(v) uiScale.Scale = v / 100 end)
		s:Toggle("Show Icons", true, function(st)
			iconsOn = st
			for _, ic in icons do ic.Visible = st end
			for _, ind in indicators do ind.txt.Visible = not st end
		end)
		s:Toggle("Close Button", false, function(st) closeBtn.Visible = st end)
		s:Toggle("Reduce Motion", false, function(st) reduceMotion = st end)
		s:Button("Reset Window Position", function() main.Position = defaultPosition end)
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

	return window
end

return Library