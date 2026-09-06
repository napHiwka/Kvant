-- SHORT TODO:
-- fix: Dropdown - disable shevron icon when icons disabled.
-- feat: Custom window sizes on window creation.
-- style: Sections - something better (textual) than (collapsed and ">" or "v") when icons turned off (probaly use also them in Dropdown when icons disabled).
-- style: Increase pill max size (adjustable to text size - but not infinite) or recude font.
-- code style: update Motion to actually used anims.

-- LATER TODO:
-- fix: Theme assigning per window - not working.
-- API: SetTheme to window, not lib.
-- feat: auto-cache and auto-update when needed from github.
-- feat: add customasset to bypass detection.
-- style: bigger text looks good.
-- style: Input - bigger font & height?
-- test: under 2k, 4k screens.

-- Environment
local cloneref = cloneref or function(f)
	return f
end

local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local nid = 0
local function rname()
	nid += 1
	return string.format("%X%X", os.clock() * 1e4, nid)
end

local supported = type(writefile) == "function"
	and type(readfile) == "function"
	and type(isfile) == "function"
	and type(isfolder) == "function"
	and type(makefolder) == "function"

local game = cloneref(game)
local GameId = tostring(game.GameId)
local ROOT = "Kvant"
local GAMES_DIR = ROOT .. "/games"
local KVANT_FILE = ROOT .. "/settings.luau"

local function gameFile(id)
	return GAMES_DIR .. "/" .. tostring(id) .. ".luau"
end

local function ensureFolders()
	if not isfolder(ROOT) then
		makefolder(ROOT)
	end
	if not isfolder(GAMES_DIR) then
		makefolder(GAMES_DIR)
	end
end

-- Library
local Library = {}
Library.Config = {
	Themes = {
		Dark = {
			Background = Color3.fromRGB(24, 24, 27),
			Secondary = Color3.fromRGB(32, 32, 36),
			Accent = Color3.fromRGB(34, 197, 94),
			Stroke = Color3.fromRGB(50, 50, 56),
			Text = Color3.fromRGB(240, 240, 242),
			SubText = Color3.fromRGB(160, 160, 168),
			AccentText = Color3.fromRGB(255, 255, 255),
		},
		Darker = {
			Background = Color3.fromRGB(9, 9, 11),
			Secondary = Color3.fromRGB(15, 15, 17),
			Accent = Color3.fromRGB(34, 197, 94),
			Stroke = Color3.fromRGB(26, 26, 29),
			Text = Color3.fromRGB(235, 235, 238),
			SubText = Color3.fromRGB(130, 130, 138),
			AccentText = Color3.fromRGB(255, 255, 255),
		},
		Light = {
			Background = Color3.fromRGB(250, 250, 251),
			Secondary = Color3.fromRGB(240, 240, 243),
			Accent = Color3.fromRGB(74, 158, 110),
			Stroke = Color3.fromRGB(222, 222, 227),
			Text = Color3.fromRGB(22, 22, 25),
			SubText = Color3.fromRGB(110, 110, 118),
			AccentText = Color3.fromRGB(255, 255, 255),
		},
	},
	Text = { Title = 17, Label = 16, Body = 15, Small = 14 },
	Fonts = {
		Bold = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold),
		Medium = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
		Regular = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular),
	},
	Motion = {
		Fast = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Snap = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Panel = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	},
}

function Library:SetTheme(n)
	if Library.Config.Themes[n] then
		Library.CurrentTheme = Library.Config.Themes[n]
	end
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

local function decimalsOf(n)
	if n == math.floor(n) then
		return 0
	end
	local s = string.format("%.6f", n):gsub("0+$", ""):gsub("%.$", "")
	local dot = s:find("%.")
	return dot and (#s - dot) or 0
end

local function newCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius
	c.Parent = parent
	return c
end

local function newPadding(parent, left, right, top, bottom)
	local p = Instance.new("UIPadding")
	if left then
		p.PaddingLeft = UDim.new(0, left)
	end
	if right then
		p.PaddingRight = UDim.new(0, right)
	end
	if top then
		p.PaddingTop = UDim.new(0, top)
	end
	if bottom then
		p.PaddingBottom = UDim.new(0, bottom)
	end
	p.Parent = parent
	return p
end

local function newStroke(parent, color, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color
	if transparency then
		s.Transparency = transparency
	end
	s.Parent = parent
	return s
end

local function styleScrollbar(scrollingFrame, theme, horizontal)
	scrollingFrame.ScrollBarThickness = 3
	scrollingFrame.ScrollBarImageColor3 = theme.SubText
	scrollingFrame.ScrollBarImageTransparency = 0.25
	if horizontal then
		scrollingFrame.HorizontalScrollBarInset = Enum.ScrollBarInset.Always
	else
		scrollingFrame.VerticalScrollBarInset = Enum.ScrollBarInset.Always
	end
end

function Library:CreateWindow(name, sideTabs, iconId)
	name = name or "Kvant"
	local theme = Library.CurrentTheme
	local T, F = Library.Config.Text, Library.Config.Fonts

	local Defaults = {
		Frame = { BorderSizePixel = 0 },
		ScrollingFrame = { BorderSizePixel = 0 },
		TextLabel = {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			FontFace = F.Medium,
			TextColor3 = theme.Text,
			TextSize = T.Label,
			TextXAlignment = Enum.TextXAlignment.Left,
		},
		TextButton = { BorderSizePixel = 0, AutoButtonColor = false, Text = "" },
		TextBox = {
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			FontFace = F.Medium,
			TextColor3 = theme.Text,
			TextSize = T.Body,
			PlaceholderColor3 = theme.SubText,
		},
		ImageLabel = { BackgroundTransparency = 1, BorderSizePixel = 0 },
		ImageButton = { BackgroundTransparency = 1, BorderSizePixel = 0, ScaleType = Enum.ScaleType.Fit },
	}

	local function Make(class, props)
		local inst = Instance.new(class)
		inst.Name = rname()
		local d = Defaults[class]
		if d then
			for k, v in d do
				inst[k] = v
			end
		end
		local parent = props.Parent
		for k, v in props do
			if k ~= "Parent" then
				inst[k] = v
			end
		end
		if parent then
			inst.Parent = parent
		end
		return inst
	end

	-- Persistence
	local KvantConfig, GameConfig = {}, {}
	local savePending = {}

	-- ... at this point just use json (what weak one would say)
	local function serialize(value)
		local valueType = type(value)
		if valueType == "string" then
			return string.format("%q", value)
		elseif valueType == "number" or valueType == "boolean" then
			return tostring(value)
		elseif valueType == "table" then
			local parts = { "{" }
			for key, item in value do
				local keyType = type(key)
				if keyType == "string" then
					parts[#parts + 1] = "[" .. string.format("%q", key) .. "]="
				elseif keyType == "number" then
					parts[#parts + 1] = "[" .. tostring(key) .. "]="
				else
					continue
				end
				parts[#parts + 1] = serialize(item)
				parts[#parts + 1] = ","
			end
			parts[#parts + 1] = "}"
			return table.concat(parts)
		end
		return "nil"
	end

	local function registerConfig(registry, key, default, getter, setter)
		registry[key] = {
			default = default,
			get = getter,
			set = setter,
		}
	end

	local function readConfig(path)
		if not isfile(path) then
			return nil
		end

		local ok, chunk = pcall(loadstring, "return " .. readfile(path))
		if not ok or type(chunk) ~= "function" then
			return nil
		end

		local ran, data = pcall(chunk)
		if ran and type(data) == "table" then
			return data
		end
		return nil
	end

	local function writeConfig(path, registry)
		local data = {}
		for key, entry in registry do
			local ok, value = pcall(entry.get)
			if ok then
				data[key] = value
			end
		end
		pcall(writefile, path, serialize(data))
	end

	local function applyConfig(registry, saved)
		if type(saved) ~= "table" then
			return
		end
		for key, entry in registry do
			local value = saved[key]
			if value ~= nil then
				pcall(entry.set, value)
			end
		end
	end

	local function requestSave(registry)
		if not supported or savePending[registry] then
			return
		end

		savePending[registry] = true
		task.delay(0.35, function()
			savePending[registry] = nil
			ensureFolders()

			if registry == KvantConfig then
				writeConfig(KVANT_FILE, KvantConfig)
			else
				writeConfig(gameFile(GameId), GameConfig)
			end
		end)
	end

	local icons, iconN, iconsOn = {}, 0, true
	local sectionArrows = {}
	local reduceMotion = false
	local notificationsEnabled = true
	local autoload = true
	local function tw(inst, info, props)
		if reduceMotion then
			for k, v in props do
				inst[k] = v
			end
		else
			TweenService:Create(inst, info, props):Play()
		end
	end

	local conns = {}
	local function conn(sig, fn)
		local c = sig:Connect(fn)
		conns[#conns + 1] = c
		return c
	end

	local function mkicon(id, kind, parent, size)
		local imgId = id
		if imgId == nil then
			imgId = Icons[kind]
		end
		if imgId == false then
			return
		end
		local img = Make("ImageLabel", {
			LayoutOrder = 1,
			Size = size,
			Image = imgId,
			Visible = iconsOn,
			Parent = parent,
		})
		iconN += 1
		icons[iconN] = img
		return img
	end

	-- Icon+label row builder
	local function rowLabel(parent, iconName, kind, text, rightGap)
		local row = Make("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -(rightGap or 0), 1, 0),
			Parent = parent,
		})
		local rl = Instance.new("UIListLayout")
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.VerticalAlignment = Enum.VerticalAlignment.Center
		rl.Padding = UDim.new(0, 10)
		rl.Parent = row
		mkicon(iconName, kind, row, UDim2.new(0, 16, 0, 16))
		Make("TextLabel", {
			LayoutOrder = 2,
			Size = UDim2.new(1, -26, 1, 0),
			Text = text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
	end

	-- Input dispatcher
	local activeMove = nil
	local dragMoved = false
	conn(UserInputService.InputChanged, function(i)
		if
			activeMove
			and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch)
		then
			activeMove(i.Position)
		end
	end)
	conn(UserInputService.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			activeMove = nil
		end
	end)
	local function drag(frame, handle)
		handle = handle or frame
		handle.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				local sx, sy = i.Position.X, i.Position.Y
				local ox, oy = frame.Position.X.Offset, frame.Position.Y.Offset
				dragMoved = false
				activeMove = function(pos)
					if math.abs(pos.X - sx) > 3 or math.abs(pos.Y - sy) > 3 then
						dragMoved = true
					end
					frame.Position =
						UDim2.new(frame.Position.X.Scale, ox + (pos.X - sx), frame.Position.Y.Scale, oy + (pos.Y - sy))
				end
			end
		end)
	end

	local gui = Make("ScreenGui", {
		ResetOnSpawn = false,
		Parent = gethui and gethui() or cloneref(game:FindFirstChild("CoreGui")) or cloneref(
			game:GetService("Players")
		).LocalPlayer:WaitForChild("PlayerGui"),
	})

	local winSize = sideTabs and UDim2.new(0.42, 0, 0.62, 0) or UDim2.new(0.3, 0, 0.6, 0)
	local winMin = sideTabs and Vector2.new(460, 400) or Vector2.new(320, 400)
	local winMax = sideTabs and Vector2.new(620, 560) or Vector2.new(420, 520)

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

	local mainConstraint = Instance.new("UISizeConstraint")
	mainConstraint.MinSize = winMin
	mainConstraint.MaxSize = winMax
	mainConstraint.Parent = main

	newCorner(main, UDim.new(0, 10))
	newStroke(main, theme.Stroke)

	local uiScale = Instance.new("UIScale")
	uiScale.Parent = main

	local notifHolder = Make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 260, 1, -32),
		Parent = gui,
	})
	local notifList = Instance.new("UIListLayout")
	notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	notifList.Padding = UDim.new(0, 8)
	notifList.Parent = notifHolder

	local topbar = Make("Frame", {
		BackgroundColor3 = theme.Secondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 44),
		ZIndex = 5,
		Parent = main,
	})
	newCorner(topbar, UDim.new(0, 10))

	local titleRow = Make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -130, 1, 0),
		Position = UDim2.new(0, 16, 0, 0),
		Parent = topbar,
	})
	local titleList = Instance.new("UIListLayout")
	titleList.FillDirection = Enum.FillDirection.Horizontal
	titleList.VerticalAlignment = Enum.VerticalAlignment.Center
	titleList.Padding = UDim.new(0, 10)
	titleList.Parent = titleRow

	mkicon(iconId, "Kvant", titleRow, UDim2.new(0, 20, 0, 20))

	Make("TextLabel", {
		LayoutOrder = 2,
		Size = UDim2.new(1, -30, 1, 0),
		FontFace = F.Bold,
		Text = name,
		TextSize = T.Title,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = titleRow,
	})

	local controls = Make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 0, 1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		Parent = topbar,
	})
	local controlsList = Instance.new("UIListLayout")
	controlsList.FillDirection = Enum.FillDirection.Horizontal
	controlsList.VerticalAlignment = Enum.VerticalAlignment.Center
	controlsList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	controlsList.SortOrder = Enum.SortOrder.LayoutOrder
	controlsList.Padding = UDim.new(0, 10)
	controlsList.Parent = controls

	local ctrlIconSize = UDim2.new(0, 20, 0, 20)
	local settingsBtn = Make("ImageButton", {
		Size = ctrlIconSize,
		Image = Icons.Settings,
		ImageColor3 = theme.Text,
		LayoutOrder = 1,
		Parent = controls,
	})
	local minBtn = Make("ImageButton", {
		Size = ctrlIconSize,
		Image = "rbxassetid://10137941941",
		ImageColor3 = theme.Text,
		LayoutOrder = 2,
		Parent = controls,
	})
	local closeBtn = Make("ImageButton", {
		Size = UDim2.new(0, 22, 0, 22),
		Image = "rbxassetid://10137832201",
		ImageColor3 = theme.Text,
		Visible = false,
		LayoutOrder = 3,
		Parent = controls,
	})

	for _, btn in { settingsBtn, minBtn, closeBtn } do
		btn.MouseEnter:Connect(function()
			tw(btn, TweenInfo.new(0.08), { ImageColor3 = theme.Accent })
		end)
		btn.MouseLeave:Connect(function()
			tw(btn, TweenInfo.new(0.12), { ImageColor3 = theme.Text })
		end)
	end

	drag(main, topbar)

	local tabHolder, pageHolder
	if sideTabs then
		tabHolder = Make("ScrollingFrame", {
			BackgroundColor3 = theme.Secondary,
			Position = UDim2.new(0, 0, 0, 44),
			Size = UDim2.new(0.30, 0, 1, -44),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Parent = main,
		})
		newCorner(tabHolder, UDim.new(0, 10))
		styleScrollbar(tabHolder, theme, false)

		local tabList = Instance.new("UIListLayout")
		tabList.SortOrder = Enum.SortOrder.LayoutOrder
		tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
		tabList.Padding = UDim.new(0, 6)
		tabList.Parent = tabHolder

		newPadding(tabHolder, nil, nil, 10)

		Make("Frame", {
			BackgroundColor3 = theme.Stroke,
			Position = UDim2.new(0.30, 0, 0, 44),
			Size = UDim2.new(0, 1, 1, -44),
			Parent = main,
		})

		pageHolder = Make("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.30, 0, 0, 44),
			Size = UDim2.new(0.7, 0, 1, -44),
			Parent = main,
		})
	else
		tabHolder = Make("ScrollingFrame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16, 0, 54),
			Size = UDim2.new(1, -32, 0, 46),
			ScrollingDirection = Enum.ScrollingDirection.X,
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Parent = main,
		})
		styleScrollbar(tabHolder, theme, true)

		local tabList = Instance.new("UIListLayout")
		tabList.FillDirection = Enum.FillDirection.Horizontal
		tabList.VerticalAlignment = Enum.VerticalAlignment.Center
		tabList.SortOrder = Enum.SortOrder.LayoutOrder
		tabList.Padding = UDim.new(0, 8)
		tabList.Parent = tabHolder

		pageHolder = Make("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 108),
			Size = UDim2.new(1, 0, 1, -102),
			Parent = main,
		})
	end

	newPadding(pageHolder, 16, 16, sideTabs and 12 or 12, 16)

	local pill = Make("TextButton", {
		BackgroundColor3 = theme.Secondary,
		Visible = false,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.04, 0),
		Size = UDim2.new(0, 150, 0, 40),
		Parent = gui,
	})
	newCorner(pill, UDim.new(1, 0))
	local pillStroke = newStroke(pill, theme.Stroke)

	Make("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		Text = name,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = pill,
	})

	pill.MouseEnter:Connect(function()
		tw(pillStroke, TweenInfo.new(0.1), { Color = theme.Accent })
	end)
	pill.MouseLeave:Connect(function()
		tw(pillStroke, TweenInfo.new(0.12), { Color = theme.Stroke })
	end)

	drag(pill)

	local minimized = false
	local unlockCursor = false
	local savedMouseBehavior = nil
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
			tw(
				main,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 1 }
			)
			main.Visible = false
			pill.Visible = true
		else
			main.Visible = true
			main.Size = UDim2.new(winSize.X.Scale, winSize.X.Offset, 0, 44)
			pill.Visible = false
			tw(
				main,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 0, Size = winSize }
			)
		end
		applyCursorState()
	end
	minBtn.Activated:Connect(toggleWindow)
	pill.Activated:Connect(function()
		if dragMoved then
			dragMoved = false
			return
		end
		toggleWindow()
	end)

	local tabBtns, tabLabels, tabPages, tabN = {}, {}, {}, 0
	local activeIndex
	local lastUserIndex
	local settingsIndex
	local settingsTabActivate
	local window = {}

	function window:Destroy()
		for i = 1, #conns do
			conns[i]:Disconnect()
		end
		gui:Destroy()
	end

	closeBtn.Activated:Connect(function()
		window:Destroy()
	end)

	function window:Notify(text, duration)
		if not notificationsEnabled then
			return
		end
		duration = duration or 3
		local n = Make("Frame", {
			BackgroundColor3 = theme.Secondary,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = notifHolder,
		})
		newCorner(n, UDim.new(0, 8))
		local s = newStroke(n, theme.Stroke, 1)
		newPadding(n, 14, 14, 10, 10)
		local l = Make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			TextSize = T.Body,
			TextWrapped = true,
			TextTransparency = 1,
			Text = text,
			Parent = n,
		})

		tw(n, TweenInfo.new(0.18), { BackgroundTransparency = 0 })
		tw(s, TweenInfo.new(0.18), { Transparency = 0 })
		tw(l, TweenInfo.new(0.18), { TextTransparency = 0 })

		task.delay(duration, function()
			if not n.Parent then
				return
			end
			tw(n, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
			tw(s, TweenInfo.new(0.2), { Transparency = 1 })
			tw(l, TweenInfo.new(0.2), { TextTransparency = 1 })
			task.wait(0.2)
			n:Destroy()
		end)
	end

	local function createTab(tabName, tabIcon, registry)
		local btn = Make("TextButton", {
			BackgroundColor3 = theme.Secondary,
			Size = sideTabs and UDim2.new(0.9, 0, 0, 36) or UDim2.new(0, 0, 0, 38),
			AutomaticSize = sideTabs and Enum.AutomaticSize.None or Enum.AutomaticSize.X,
			Parent = tabHolder,
		})
		newCorner(btn, sideTabs and UDim.new(0, 7) or UDim.new(1, 0))
		newPadding(btn, sideTabs and 10 or 14, sideTabs and 10 or 14)

		local btnList = Instance.new("UIListLayout")
		btnList.FillDirection = Enum.FillDirection.Horizontal
		btnList.VerticalAlignment = Enum.VerticalAlignment.Center
		btnList.Padding = UDim.new(0, 8)
		btnList.Parent = btn

		mkicon(tabIcon, "Tab", btn, UDim2.new(0, 16, 0, 16))

		local label = Make("TextLabel", {
			LayoutOrder = 2,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = sideTabs and UDim2.new(1, -24, 1, 0) or UDim2.new(0, 0, 1, 0),
			Text = tabName,
			TextColor3 = theme.SubText,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = btn,
		})

		local page = Make("ScrollingFrame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Visible = false,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Parent = pageHolder,
		})
		styleScrollbar(page, theme, false)

		local list = Instance.new("UIListLayout")
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, 10)
		list.Parent = page

		list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 8)
		end)

		tabN += 1
		local index = tabN
		local isSettings = registry == KvantConfig

		btn.LayoutOrder = index
		if isSettings then
			btn.Visible = false
			settingsIndex = index
		end

		tabBtns[index] = btn
		tabLabels[index] = label
		tabPages[index] = page

		local function activate()
			for i = 1, tabN do
				tabPages[i].Visible = false
				tabLabels[i].TextColor3 = theme.SubText
				if tabBtns[i].Visible then
					tabBtns[i].BackgroundColor3 = theme.Secondary
				end
			end
			page.Visible = true
			activeIndex = index

			if btn.Visible then
				label.TextColor3 = theme.AccentText
				btn.BackgroundColor3 = theme.Accent
			end

			if not isSettings then
				lastUserIndex = index
			end
		end
		btn.Activated:Connect(activate)

		btn.MouseEnter:Connect(function()
			if activeIndex ~= index then
				tw(btn, TweenInfo.new(0.08), { BackgroundColor3 = theme.Stroke })
			end
		end)
		btn.MouseLeave:Connect(function()
			if activeIndex ~= index then
				tw(btn, TweenInfo.new(0.1), { BackgroundColor3 = theme.Secondary })
			end
		end)

		if isSettings then
			settingsTabActivate = activate
		elseif not lastUserIndex then
			activate()
		end

		local tab = {}
		local ctx = { parent = page, order = 0 }
		local function nextOrder()
			ctx.order += 1
			return ctx.order
		end
		local function configKey(kind, text)
			return tabName .. ">" .. kind .. ":" .. text
		end

		function tab:Section(text, collapsed, builder)
			if type(collapsed) == "function" then
				builder, collapsed = collapsed, false
			end
			collapsed = collapsed and true or false

			local header = Make("TextButton", {
				BackgroundTransparency = 1,
				LayoutOrder = nextOrder(),
				Size = UDim2.new(1, 0, 0, 24),
				Parent = ctx.parent,
			})
			local hlist = Instance.new("UIListLayout")
			hlist.FillDirection = Enum.FillDirection.Horizontal
			hlist.VerticalAlignment = Enum.VerticalAlignment.Center
			hlist.Padding = UDim.new(0, 6)
			hlist.Parent = header

			local chevHolder = Make("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Size = UDim2.new(0, 14, 0, 14),
				Parent = header,
			})

			local chev = Make("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 12, 0, 12),
				Image = Icons.Dropdown,
				ImageColor3 = theme.SubText,
				Rotation = collapsed and -90 or 0,
				Visible = iconsOn,
				Parent = chevHolder,
			})
			iconN += 1
			icons[iconN] = chev

			local arrow = Make("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 1, 0),
				FontFace = F.Bold,
				Text = collapsed and ">" or "v",
				TextColor3 = theme.SubText,
				TextXAlignment = Enum.TextXAlignment.Center,
				Visible = not iconsOn,
				Parent = chevHolder,
			})
			table.insert(sectionArrows, arrow)

			Make("TextLabel", {
				LayoutOrder = 2,
				Size = UDim2.new(1, -20, 1, 0),
				FontFace = F.Bold,
				Text = text,
				TextColor3 = theme.SubText,
				Parent = header,
			})

			local container = Make("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = nextOrder(),
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				Visible = not collapsed,
				Parent = ctx.parent,
			})
			local innerList = Instance.new("UIListLayout")
			innerList.SortOrder = Enum.SortOrder.LayoutOrder
			innerList.Padding = UDim.new(0, 10)
			innerList.Parent = container

			if builder then
				local savedParent, savedOrder = ctx.parent, ctx.order
				ctx.parent, ctx.order = container, 0
				builder(tab)
				ctx.parent, ctx.order = savedParent, savedOrder
			end

			local hasContent = #container:GetChildren() > 1
			if not hasContent then
				container.Visible = false
				header.Active = false
				header.AutoButtonColor = false
				chevHolder.Visible = false
				return
			end

			header.Activated:Connect(function()
				collapsed = not collapsed
				container.Visible = not collapsed
				tw(chev, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Rotation = collapsed and -90 or 0,
				})
				arrow.Text = collapsed and ">" or "v"
			end)
		end

		function tab:Divider()
			Make("Frame", {
				LayoutOrder = nextOrder(),
				BackgroundColor3 = theme.Stroke,
				Size = UDim2.new(1, 0, 0, 1),
				Parent = ctx.parent,
			})
		end

		function tab:Text(title, content, iconName)
			local f = Make("Frame", {
				LayoutOrder = nextOrder(),
				BackgroundColor3 = theme.Secondary,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = ctx.parent,
			})
			newCorner(f, UDim.new(0, 8))
			newPadding(f, 16, 16, 14, 14)
			local vlist = Instance.new("UIListLayout")
			vlist.Padding = UDim.new(0, 8)
			vlist.Parent = f

			local head = Make("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, T.Title + 8),
				Parent = f,
			})
			local headList = Instance.new("UIListLayout")
			headList.FillDirection = Enum.FillDirection.Horizontal
			headList.VerticalAlignment = Enum.VerticalAlignment.Center
			headList.Padding = UDim.new(0, 8)
			headList.Parent = head

			mkicon(iconName, "Text", head, UDim2.new(0, 18, 0, 18))

			Make("TextLabel", {
				LayoutOrder = 2,
				Size = UDim2.new(1, -26, 1, 0),
				FontFace = F.Bold,
				Text = title,
				TextSize = T.Title,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = head,
			})
			Make("TextLabel", {
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = theme.SubText,
				TextSize = T.Body,
				TextWrapped = true,
				Text = content,
				Parent = f,
			})
		end

		local function card(h)
			local f = Make("Frame", {
				LayoutOrder = nextOrder(),
				BackgroundColor3 = theme.Secondary,
				Size = UDim2.new(1, 0, 0, h),
				Parent = ctx.parent,
			})
			newCorner(f, UDim.new(0, 8))
			newPadding(f, 16, 16)
			return f
		end

		function tab:Button(text, callback, iconName)
			local f = card(46)
			rowLabel(f, iconName, "Button", text, 0)
			local clickBtn =
				Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = f })
			local cardStroke = newStroke(f, theme.Stroke, 0.7)

			clickBtn.MouseEnter:Connect(function()
				tw(cardStroke, TweenInfo.new(0.08), { Transparency = 0.2 })
			end)
			clickBtn.MouseLeave:Connect(function()
				tw(cardStroke, TweenInfo.new(0.12), { Transparency = 0.7 })
			end)
			clickBtn.Activated:Connect(function()
				tw(f, TweenInfo.new(0.06), { BackgroundColor3 = theme.Accent })
				task.delay(0.12, function()
					tw(f, TweenInfo.new(0.15), { BackgroundColor3 = theme.Secondary })
				end)
				callback()
			end)
		end

		function tab:Toggle(text, default, callback, iconName)
			local f = card(46)
			rowLabel(f, iconName, "Toggle", text, 46)
			local sw = Make("Frame", {
				BackgroundColor3 = default and theme.Accent or theme.Stroke,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 40, 0, 22),
				Parent = f,
			})
			newCorner(sw, UDim.new(1, 0))
			local circ = Make("Frame", {
				BackgroundColor3 = Color3.new(1, 1, 1),
				Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
				Size = UDim2.new(0, 16, 0, 16),
				Parent = sw,
			})
			newCorner(circ, UDim.new(1, 0))
			local clickBtn =
				Make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = f })
			local cardStroke = newStroke(f, theme.Stroke, 0.7)

			clickBtn.MouseEnter:Connect(function()
				tw(cardStroke, TweenInfo.new(0.08), { Transparency = 0.2 })
			end)
			clickBtn.MouseLeave:Connect(function()
				tw(cardStroke, TweenInfo.new(0.12), { Transparency = 0.7 })
			end)

			local state = default and true or false
			local key = configKey("Toggle", text)

			local function apply(newState, immediate)
				state = newState
				local pos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
				local color = state and theme.Accent or theme.Stroke
				if immediate then
					circ.Position = pos
					sw.BackgroundColor3 = color
				else
					tw(circ, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = pos })
					tw(
						sw,
						TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ BackgroundColor3 = color }
					)
				end
				callback(state)
			end

			clickBtn.Activated:Connect(function()
				apply(not state)
				requestSave(registry)
			end)

			registerConfig(registry, key, state, function()
				return state
			end, function(value)
				if type(value) == "boolean" then
					apply(value, true)
				end
			end)
		end

		function tab:Slider(text, min, max, default, step, callback, iconName)
			if type(step) == "function" then
				callback, step = step, 1
			else
				step = step or 1
			end
			local decimals = decimalsOf(step)
			local mult = 10 ^ decimals
			local function fmt(v)
				return decimals > 0 and string.format("%." .. decimals .. "f", v) or tostring(v)
			end
			local function round(v)
				local snapped = math.floor((v - min) / step + 0.5) * step + min
				return math.floor(snapped * mult + 0.5) / mult
			end
			default = round(default)

			local f = card(70)
			local row = Make("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 10),
				Size = UDim2.new(1, 0, 0, 22),
				Parent = f,
			})
			local rl = Instance.new("UIListLayout")
			rl.FillDirection = Enum.FillDirection.Horizontal
			rl.VerticalAlignment = Enum.VerticalAlignment.Center
			rl.Padding = UDim.new(0, 8)
			rl.Parent = row
			mkicon(iconName, "Slider", row, UDim2.new(0, 14, 0, 14))
			Make("TextLabel", { LayoutOrder = 2, Size = UDim2.new(0.6, 0, 1, 0), Text = text, Parent = row })
			local val = Make("TextLabel", {
				Size = UDim2.new(0.3, 0, 0, 22),
				Position = UDim2.new(0.7, 0, 0, 10),
				FontFace = F.Bold,
				Text = fmt(default),
				TextColor3 = theme.Accent,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = f,
			})
			local bar = Make("Frame", {
				BackgroundColor3 = theme.Stroke,
				Position = UDim2.new(0, 0, 0, 46),
				Size = UDim2.new(1, 0, 0, 6),
				Parent = f,
			})
			newCorner(bar, UDim.new(1, 0))
			local fill = Make("Frame", {
				BackgroundColor3 = theme.Accent,
				Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
				Parent = bar,
			})
			newCorner(fill, UDim.new(1, 0))

			local knob = Make("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 12, 0, 12),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = fill,
			})
			newCorner(knob, UDim.new(1, 0))

			local current = default
			local key = configKey("Slider", text)

			local function setVisual(value, pos)
				fill.Size = UDim2.new(pos, 0, 1, 0)
				val.Text = fmt(value)
			end

			local function move(x)
				local pos = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				local value = round(min + (max - min) * pos)
				setVisual(value, pos)
				if value ~= current then
					current = value
					callback(value)
					requestSave(registry)
				end
			end
			bar.InputBegan:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					activeMove = function(pos)
						move(pos.X)
					end
					move(i.Position.X)
				end
			end)

			registerConfig(registry, key, default, function()
				return current
			end, function(value)
				if type(value) ~= "number" then
					return
				end
				value = round(math.clamp(value, min, max))
				current = value
				setVisual(value, (value - min) / (max - min))
				callback(value)
			end)
		end

		function tab:Dropdown(text, options, callback, default, iconName)
			local multi = type(default) == "table"
			local selected = {}
			if multi then
				for i = 1, #default do
					selected[default[i]] = true
				end
			else
				default = default or options[1]
			end
			local initialDefault = default

			local function selectedList()
				local list, n = {}, 0
				for i = 1, #options do
					if selected[options[i]] then
						n += 1
						list[n] = options[i]
					end
				end
				return list
			end

			local f = card(46)
			f.ClipsDescendants = true
			local cardStroke = newStroke(f, theme.Stroke, 0.7)

			local function labelText()
				if not multi then
					return text .. ": " .. tostring(default)
				end
				local list = selectedList()
				if #list == 0 then
					return text .. ": None"
				end
				local parts = {}
				for i = 1, #list do
					parts[i] = tostring(list[i])
				end
				return text .. ": " .. table.concat(parts, ", ")
			end

			local function openHeight()
				return #options > 0 and (48 + 38 * #options) or 46
			end

			local head = Make("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 22),
				Position = UDim2.new(0, 0, 0, 12),
				Parent = f,
			})
			local headList = Instance.new("UIListLayout")
			headList.FillDirection = Enum.FillDirection.Horizontal
			headList.VerticalAlignment = Enum.VerticalAlignment.Center
			headList.Padding = UDim.new(0, 10)
			headList.Parent = head
			-- mkicon(iconName, "Dropdown", head, UDim2.new(0, 16, 0, 16))

			local label = Make("TextLabel", {
				LayoutOrder = 2,
				Size = UDim2.new(1, -50, 1, 0),
				Text = labelText(),
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = head,
			})

			local chev = Make("ImageLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -7, 0, 16),
				Size = UDim2.new(0, 14, 0, 14),
				Image = Icons.Dropdown,
				ImageColor3 = theme.SubText,
				Parent = f,
			})

			local list2 = Make("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 46),
				Size = UDim2.new(1, 0, 0, 0),
				Parent = f,
			})
			local vl = Instance.new("UIListLayout")
			vl.SortOrder = Enum.SortOrder.LayoutOrder
			vl.Padding = UDim.new(0, 6)
			vl.Parent = list2
			local clickBtn = Make(
				"TextButton",
				{ LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Parent = f }
			)

			clickBtn.MouseEnter:Connect(function()
				tw(cardStroke, TweenInfo.new(0.08), { Transparency = 0.2 })
			end)
			clickBtn.MouseLeave:Connect(function()
				tw(cardStroke, TweenInfo.new(0.12), { Transparency = 0.7 })
			end)

			local opened = false
			local optBtns = {}

			local function refreshVisual()
				label.Text = labelText()
				for i = 1, #optBtns do
					local v = options[i]
					local opt = optBtns[i]
					local isSel = multi and selected[v]
					opt.BackgroundColor3 = isSel and theme.Accent or theme.Background
					opt.TextColor3 = isSel and theme.AccentText or theme.SubText
				end
			end

			local function build()
				for i = 1, #optBtns do
					optBtns[i]:Destroy()
				end
				table.clear(optBtns)
				for i = 1, #options do
					local v = options[i]
					local isSel = multi and selected[v]
					local opt = Make("TextButton", {
						LayoutOrder = i,
						BackgroundColor3 = isSel and theme.Accent or theme.Background,
						Size = UDim2.new(1, 0, 0, 32),
						FontFace = F.Medium,
						Text = tostring(v),
						TextColor3 = isSel and theme.AccentText or theme.SubText,
						TextSize = T.Body,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Parent = list2,
					})
					newCorner(opt, UDim.new(0, 6))

					opt.MouseEnter:Connect(function()
						if not (multi and selected[v]) then
							tw(opt, TweenInfo.new(0.08), { BackgroundColor3 = theme.Stroke, TextColor3 = theme.Text })
						end
					end)
					opt.MouseLeave:Connect(function()
						if not (multi and selected[v]) then
							tw(
								opt,
								TweenInfo.new(0.1),
								{ BackgroundColor3 = theme.Background, TextColor3 = theme.SubText }
							)
						end
					end)

					if multi then
						opt.Activated:Connect(function()
							selected[v] = not selected[v] or nil
							refreshVisual()
							callback(selectedList())
							requestSave(registry)
						end)
					else
						opt.Activated:Connect(function()
							default = v
							label.Text = labelText()
							opened = false
							tw(f, TweenInfo.new(0.15), { Size = UDim2.new(1, 0, 0, 46) })
							tw(chev, TweenInfo.new(0.15), { Rotation = 0 })
							callback(v)
							requestSave(registry)
						end)
					end
					optBtns[i] = opt
				end
			end
			build()

			clickBtn.Activated:Connect(function()
				opened = not opened
				tw(f, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(1, 0, 0, opened and openHeight() or 46),
				})
				tw(chev, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Rotation = opened and 180 or 0,
				})
			end)

			local key = configKey("Dropdown", text)
			registerConfig(registry, key, multi and selectedList() or initialDefault, function()
				return multi and selectedList() or default
			end, function(value)
				if multi then
					if type(value) ~= "table" then
						return
					end
					table.clear(selected)
					for i = 1, #value do
						if table.find(options, value[i]) then
							selected[value[i]] = true
						end
					end
				else
					if not table.find(options, value) then
						return
					end
					default = value
				end
				refreshVisual()
				callback(multi and selectedList() or default)
			end)

			local dropdown = {}
			function dropdown:Refresh(newOptions)
				options = newOptions
				if multi then
					for k in selected do
						if not table.find(options, k) then
							selected[k] = nil
						end
					end
				elseif not table.find(options, default) then
					default = options[1]
				end
				build()
				label.Text = labelText()
				if opened then
					tw(f, TweenInfo.new(0.15), { Size = UDim2.new(1, 0, 0, openHeight()) })
				end
			end
			return dropdown
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
			newCorner(bind, UDim.new(0, 6))
			newPadding(bind, 8, 8)
			local bindStroke = newStroke(bind, theme.Stroke, 0.5)

			local bindMin = Instance.new("UISizeConstraint")
			bindMin.MinSize = Vector2.new(44, 0)
			bindMin.Parent = bind

			local key = default
			local listening = false
			local regKey = configKey("Keybind", text)

			bind.MouseEnter:Connect(function()
				if not listening then
					tw(bindStroke, TweenInfo.new(0.08), { Color = theme.SubText, Transparency = 0.2 })
				end
			end)
			bind.MouseLeave:Connect(function()
				if not listening then
					tw(bindStroke, TweenInfo.new(0.1), { Color = theme.Stroke, Transparency = 0.5 })
				end
			end)

			bind.Activated:Connect(function()
				listening = true
				bind.Text = "..."
				tw(bindStroke, TweenInfo.new(0.1), { Color = theme.Accent, Transparency = 0 })
			end)

			conn(UserInputService.InputBegan, function(i, gpe)
				if listening then
					if i.UserInputType == Enum.UserInputType.Keyboard then
						if i.KeyCode == Enum.KeyCode.Backspace or i.KeyCode == Enum.KeyCode.Escape then
							key = nil
							bind.Text = "None"
						else
							key = i.KeyCode
							bind.Text = key.Name
						end
						listening = false
						tw(bindStroke, TweenInfo.new(0.12), { Color = theme.Stroke, Transparency = 0.5 })
						requestSave(registry)
					end
					return
				end
				if not gpe and key and i.KeyCode == key then
					callback()
				end
			end)

			registerConfig(registry, regKey, default and default.Name or "None", function()
				return key and key.Name or "None"
			end, function(value)
				if type(value) ~= "string" then
					return
				end
				if value == "None" then
					key = nil
					bind.Text = "None"
				else
					local ok, keycode = pcall(function()
						return Enum.KeyCode[value]
					end)
					if ok and keycode then
						key = keycode
						bind.Text = keycode.Name
					end
				end
			end)
		end

		function tab:Input(text, placeholder, callback, default, iconName)
			local f = card(46)
			rowLabel(f, iconName, "Input", text, 140)
			local box = Make("TextBox", {
				BackgroundColor3 = theme.Background,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 160, 0, 30),
				PlaceholderText = placeholder or "",
				Text = default or "",
				ClearTextOnFocus = false,
				ClipsDescendants = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = f,
			})
			newCorner(box, UDim.new(0, 6))
			newPadding(box, 8, 8)

			box.FocusLost:Connect(function()
				callback(box.Text)
				requestSave(registry)
			end)

			local key = configKey("Input", text)
			registerConfig(registry, key, default or "", function()
				return box.Text
			end, function(value)
				if type(value) == "string" then
					box.Text = value
					callback(value)
				end
			end)
		end

		function tab:Color(text, default, callback, iconName)
			local f = card(46)
			f.ClipsDescendants = true

			local header = Make("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 46),
				Parent = f,
			})
			rowLabel(header, iconName, "Color", text, 48)

			local color = default or Color3.fromRGB(255, 255, 255)
			local h, s, v = color:ToHSV()
			local clickBtn =
				Make("TextButton", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Parent = f })
			local swatch = Make("TextButton", {
				BackgroundColor3 = color,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.new(0, 34, 0, 22),
				Parent = header,
			})
			newCorner(swatch, UDim.new(0, 6))
			local swatchStroke = newStroke(swatch, theme.Stroke)

			swatch.MouseEnter:Connect(function()
				tw(swatchStroke, TweenInfo.new(0.08), { Color = theme.Accent })
			end)
			swatch.MouseLeave:Connect(function()
				tw(swatchStroke, TweenInfo.new(0.1), { Color = theme.Stroke })
			end)

			local content = Make("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 46),
				Size = UDim2.new(1, 0, 0, 130),
				Visible = false,
				Parent = f,
			})
			local cl = Instance.new("UIListLayout")
			cl.SortOrder = Enum.SortOrder.LayoutOrder
			cl.Padding = UDim.new(0, 8)
			cl.Parent = content

			-- Sat/Val 2D Canvas (Gradient-based, no external image assets required)
			local map = Make("Frame", {
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 74),
				BackgroundColor3 = Color3.fromHSV(h, 1, 1),
				Parent = content,
			})
			newCorner(map, UDim.new(0, 6))

			local satOverlay = Make("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = map,
			})
			newCorner(satOverlay, UDim.new(0, 6))
			local satGrad = Instance.new("UIGradient")
			satGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
			satGrad.Parent = satOverlay

			local valOverlay = Make("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.new(0, 0, 0),
				Parent = map,
			})
			newCorner(valOverlay, UDim.new(0, 6))
			local valGrad = Instance.new("UIGradient")
			valGrad.Rotation = 90
			valGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			})
			valGrad.Parent = valOverlay

			local satCursor = Make("Frame", {
				Size = UDim2.new(0, 10, 0, 10),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(s, 0, 1 - v, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = map,
			})
			newCorner(satCursor, UDim.new(1, 0))
			newStroke(satCursor, Color3.new(0, 0, 0), 0.3)

			-- Hue Slider
			local hueBar = Make("Frame", {
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 10),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = content,
			})
			newCorner(hueBar, UDim.new(1, 0))
			local hueGrad = Instance.new("UIGradient")
			hueGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
			})
			hueGrad.Parent = hueBar

			local hueCursor = Make("Frame", {
				Size = UDim2.new(0, 8, 1, 4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(h, 0, 0.5, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				Parent = hueBar,
			})
			newCorner(hueCursor, UDim.new(0, 3))
			newStroke(hueCursor, Color3.new(0, 0, 0), 0.4)

			-- Input Row: Hex & RGB
			local inputRow = Make("Frame", {
				LayoutOrder = 3,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 26),
				Parent = content,
			})
			local irl = Instance.new("UIListLayout")
			irl.FillDirection = Enum.FillDirection.Horizontal
			irl.Padding = UDim.new(0, 6)
			irl.Parent = inputRow

			local hexBox = Make("TextBox", {
				LayoutOrder = 1,
				BackgroundColor3 = theme.Background,
				Size = UDim2.new(0.4, -4, 1, 0),
				FontFace = F.Medium,
				Text = "#" .. color:ToHex():upper(),
				TextSize = T.Small,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = inputRow,
			})
			newCorner(hexBox, UDim.new(0, 6))
			newStroke(hexBox, theme.Stroke, 0.6)

			local function makeChanBox(order, placeholder, initVal)
				local box = Make("TextBox", {
					LayoutOrder = order,
					BackgroundColor3 = theme.Background,
					Size = UDim2.new(0.2, -4, 1, 0),
					FontFace = F.Medium,
					PlaceholderText = placeholder,
					Text = tostring(initVal),
					TextSize = T.Small,
					TextXAlignment = Enum.TextXAlignment.Center,
					Parent = inputRow,
				})
				newCorner(box, UDim.new(0, 6))
				newStroke(box, theme.Stroke, 0.6)
				return box
			end

			local rBox = makeChanBox(2, "R", math.floor(color.R * 255 + 0.5))
			local gBox = makeChanBox(3, "G", math.floor(color.G * 255 + 0.5))
			local bBox = makeChanBox(4, "B", math.floor(color.B * 255 + 0.5))

			local function updateVisuals(skipInputs)
				color = Color3.fromHSV(h, s, v)
				map.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				satCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
				swatch.BackgroundColor3 = color

				if not skipInputs then
					hexBox.Text = "#" .. color:ToHex():upper()
					local r = math.floor(color.R * 255 + 0.5)
					local g = math.floor(color.G * 255 + 0.5)
					local b = math.floor(color.B * 255 + 0.5)
					rBox.Text = tostring(r)
					gBox.Text = tostring(g)
					bBox.Text = tostring(b)
				end

				callback(color)
			end

			local function updateSatVal(pos)
				local minX = map.AbsolutePosition.X
				local maxX = minX + map.AbsoluteSize.X
				local minY = map.AbsolutePosition.Y
				local maxY = minY + map.AbsoluteSize.Y
				if maxX <= minX or maxY <= minY then
					return
				end
				s = math.clamp((pos.X - minX) / (maxX - minX), 0, 1)
				v = 1 - math.clamp((pos.Y - minY) / (maxY - minY), 0, 1)
				updateVisuals(false)
			end

			local function updateHue(pos)
				local minX = hueBar.AbsolutePosition.X
				local maxX = minX + hueBar.AbsoluteSize.X
				if maxX <= minX then
					return
				end
				h = math.clamp((pos.X - minX) / (maxX - minX), 0, 1)
				updateVisuals(false)
			end

			map.InputBegan:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					activeMove = updateSatVal
					updateSatVal(i.Position)
				end
			end)

			hueBar.InputBegan:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					activeMove = updateHue
					updateHue(i.Position)
				end
			end)

			hexBox.FocusLost:Connect(function()
				local clean = hexBox.Text:gsub("#", "")
				local ok, newCol = pcall(Color3.fromHex, clean)
				if ok and newCol then
					h, s, v = newCol:ToHSV()
					updateVisuals(false)
					requestSave(registry)
				else
					hexBox.Text = "#" .. color:ToHex():upper()
				end
			end)

			local function commitRgb()
				local r = math.clamp(tonumber(rBox.Text) or 0, 0, 255)
				local g = math.clamp(tonumber(gBox.Text) or 0, 0, 255)
				local b = math.clamp(tonumber(bBox.Text) or 0, 0, 255)
				local newCol = Color3.fromRGB(r, g, b)
				h, s, v = newCol:ToHSV()
				updateVisuals(false)
				requestSave(registry)
			end
			rBox.FocusLost:Connect(commitRgb)
			gBox.FocusLost:Connect(commitRgb)
			bBox.FocusLost:Connect(commitRgb)

			local opened = false
			clickBtn.Activated:Connect(function()
				opened = not opened
				if opened then
					content.Visible = true
					tw(f, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, 184),
					})
				else
					tw(f, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, 46),
					})
					task.delay(0.18, function()
						if not opened then
							content.Visible = false
						end
					end)
				end
			end)

			local key = configKey("Color", text)
			registerConfig(registry, key, {
				R = math.floor(color.R * 255 + 0.5),
				G = math.floor(color.G * 255 + 0.5),
				B = math.floor(color.B * 255 + 0.5),
			}, function()
				return {
					R = math.floor(color.R * 255 + 0.5),
					G = math.floor(color.G * 255 + 0.5),
					B = math.floor(color.B * 255 + 0.5),
				}
			end, function(value)
				local loadedCol
				if typeof(value) == "Color3" then
					loadedCol = value
				elseif type(value) == "table" and value.R then
					loadedCol = Color3.fromRGB(value.R, value.G or 0, value.B or 0)
				elseif type(value) == "string" then
					local ok, c = pcall(Color3.fromHex, value:gsub("#", ""))
					if ok and c then
						loadedCol = c
					end
				end
				if loadedCol then
					h, s, v = loadedCol:ToHSV()
					updateVisuals(false)
				end
			end)
		end

		return tab
	end

	function window:Tab(tabName, tabIcon)
		return createTab(tabName, tabIcon, GameConfig)
	end

	local settingsTab = createTab("Settings", Icons.Settings, KvantConfig)

	settingsTab:Section("Interface", false, function(section)
		section:Slider("UI Scale", 80, 120, 100, 1, function(v)
			uiScale.Scale = v / 100
		end)
		section:Toggle("Show Icons", true, function(state)
			iconsOn = state
			for i = 1, iconN do
				icons[i].Visible = state
			end
			for i = 1, #sectionArrows do
				sectionArrows[i].Visible = not state
			end
		end)
		section:Toggle("Close Button", false, function(state)
			closeBtn.Visible = state
		end)
		section:Toggle("Reduce Motion", false, function(state)
			reduceMotion = state
		end)
		section:Button("Reset Window Position", function()
			main.Position = defaultPosition
		end)
	end)

	settingsTab:Section("Controls", false, function()
		settingsTab:Keybind("Collapse Window", Enum.KeyCode.K, toggleWindow)
		settingsTab:Toggle("Unlock Cursor", false, function(state)
			unlockCursor = state
			applyCursorState()
		end)
	end)

	settingsTab:Section("Other", false, function()
		settingsTab:Toggle("Disable Notifications", false, function(state)
			notificationsEnabled = not state
		end)

		if supported then
			settingsTab:Toggle("Autoload Settings", true, function(state)
				autoload = state
			end)
			settingsTab:Button("Reset Settings", function()
				for _, entry in GameConfig do
					pcall(entry.set, entry.default)
				end
				requestSave(GameConfig)
			end)
		end
	end)

	settingsBtn.Activated:Connect(function()
		if not settingsTabActivate then
			return
		end
		if activeIndex == settingsIndex then
			if lastUserIndex then
				local page = tabPages[lastUserIndex]
				for i = 1, tabN do
					tabPages[i].Visible = false
					tabLabels[i].TextColor3 = theme.SubText
					if tabBtns[i].Visible then
						tabBtns[i].BackgroundColor3 = theme.Secondary
					end
				end
				page.Visible = true
				activeIndex = lastUserIndex
				tabLabels[lastUserIndex].TextColor3 = theme.AccentText
				tabBtns[lastUserIndex].BackgroundColor3 = theme.Accent
			end
		else
			settingsTabActivate()
		end
	end)

	task.defer(function()
		if not supported then
			return
		end
		ensureFolders()
		local kvantSaved = readConfig(KVANT_FILE)
		if kvantSaved then
			applyConfig(KvantConfig, kvantSaved)
		end
		if not autoload then
			return
		end
		local gameSaved = readConfig(gameFile(GameId))
		if gameSaved then
			applyConfig(GameConfig, gameSaved)
		end
	end)

	return window
end

return Library
