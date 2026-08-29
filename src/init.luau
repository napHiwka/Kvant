local cloneref = cloneref or function(f) return f end;

local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local rng = Random.new()
local nid = 0
local function rname()
	nid = nid + 1
	return nid .. rng:NextInteger(0, 999999)
end

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
		},
		Darker = {
			Background = Color3.fromRGB(9, 9, 11),
			Secondary = Color3.fromRGB(15, 15, 17),
			Accent = Color3.fromRGB(34, 197, 94),
			Stroke = Color3.fromRGB(26, 26, 29),
			Text = Color3.fromRGB(235, 235, 238),
			SubText = Color3.fromRGB(130, 130, 138),
		},
		Light = {
			Background = Color3.fromRGB(250, 250, 251),
			Secondary = Color3.fromRGB(240, 240, 243),
			Accent = Color3.fromRGB(74, 158, 110),
			Stroke = Color3.fromRGB(222, 222, 227),
			Text = Color3.fromRGB(22, 22, 25),
			SubText = Color3.fromRGB(110, 110, 118),
		},
	},
	Text = { Title = 17, Label = 16, Body = 15, Small = 14 },
	Fonts = {
		Bold = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold),
		Medium = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium),
		Regular = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular),
	},
}

for _, t in Library.Config.Themes do -- TODO: Fix this (Just insert properly)
	t.AccentText = Color3.fromRGB(255, 255, 255)
end

Library.CurrentTheme = Library.Config.Themes.Darker
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
}

function Library:CreateWindow(name, iconId, sideTabs)
	name = name or "Kvant"
	local theme = Library.CurrentTheme
	local T, F = Library.Config.Text, Library.Config.Fonts
	local icons, iconN, iconsOn = {}, 0, true

	local function mkicon(id, kind, parent, size)
		local img_id = id
		if img_id == nil then
			img_id = Icons[kind]
		end
		if img_id == false then
			return
		end
		local img = Instance.new("ImageLabel")
		img.Name = rname()
		img.LayoutOrder = 1
		img.BackgroundTransparency = 1
		img.Size = size
		img.Image = img_id
		img.Visible = iconsOn
		img.Parent = parent
		iconN = iconN + 1
		icons[iconN] = img
	end

	-- Icon+label row builder
	local function rowLabel(parent, iconName, kind, text, rightGap)
		local row = Instance.new("Frame")
		row.Name = rname()
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, -(rightGap or 0), 1, 0)
		row.Parent = parent
		local rl = Instance.new("UIListLayout")
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.VerticalAlignment = Enum.VerticalAlignment.Center
		rl.Padding = UDim.new(0, 10)
		rl.Parent = row
		mkicon(iconName, kind, row, UDim2.new(0, 16, 0, 16))
		local l = Instance.new("TextLabel")
		l.Name = rname()
		l.LayoutOrder = 2
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(1, -26, 1, 0)
		l.FontFace = F.Medium
		l.Text = text
		l.TextColor3 = theme.Text
		l.TextSize = T.Label
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextTruncate = Enum.TextTruncate.AtEnd
		l.Parent = row
	end

	-- Input dispatcher
	local activeMove = nil
	local dragMoved = false
	UserInputService.InputChanged:Connect(function(i)
		if
			activeMove
			and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch)
		then
			activeMove(i.Position)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
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

	local gui = Instance.new("ScreenGui")
	gui.Name = rname()
	gui.ResetOnSpawn = false
	gui.Parent = gethui and gethui() or cloneref(game:FindFirstChild('CoreGui')) or cloneref(game:GetService("Players")).LocalPlayer:WaitForChild("PlayerGui")

	local winSize = sideTabs and UDim2.new(0.44, 0, 0.58, 0) or UDim2.new(0.36, 0, 0.52, 0)
	local winMin = sideTabs and Vector2.new(460, 360) or Vector2.new(380, 320)
	local winMax = sideTabs and Vector2.new(640, 480) or Vector2.new(560, 440)

	local main = Instance.new("Frame")
	main.Name = rname()
	main.BackgroundColor3 = theme.Background
	main.BorderSizePixel = 0
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.Size = winSize
	main.Active = true
	main.ClipsDescendants = true
	main.Parent = gui

	local mainConstraint = Instance.new("UISizeConstraint")
	mainConstraint.MinSize = winMin
	mainConstraint.MaxSize = winMax
	mainConstraint.Parent = main

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 10)
	mainCorner.Parent = main

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = theme.Stroke
	mainStroke.Parent = main

	local topbar = Instance.new("Frame")
	topbar.Name = rname()
	topbar.BackgroundColor3 = theme.Secondary
	topbar.BackgroundTransparency = 1
	topbar.Size = UDim2.new(1, 0, 0, 44)
	topbar.ZIndex = 5
	topbar.Parent = main

	local topbarCorner = Instance.new("UICorner")
	topbarCorner.CornerRadius = UDim.new(0, 10)
	topbarCorner.Parent = topbar

	local titleRow = Instance.new("Frame")
	titleRow.Name = rname()
	titleRow.BackgroundTransparency = 1
	titleRow.Size = UDim2.new(1, -110, 1, 0)
	titleRow.Position = UDim2.new(0, 16, 0, 0)
	titleRow.Parent = topbar

	local titleList = Instance.new("UIListLayout")
	titleList.FillDirection = Enum.FillDirection.Horizontal
	titleList.VerticalAlignment = Enum.VerticalAlignment.Center
	titleList.Padding = UDim.new(0, 10)
	titleList.Parent = titleRow

	mkicon(iconId, "Kvant", titleRow, UDim2.new(0, 20, 0, 20))

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = rname()
	titleLabel.LayoutOrder = 2
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, -30, 1, 0)
	titleLabel.FontFace = F.Bold
	titleLabel.Text = name
	titleLabel.TextColor3 = theme.Text
	titleLabel.TextSize = T.Title
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Parent = titleRow

	local controls = Instance.new("Frame")
	controls.Name = rname()
	controls.BackgroundTransparency = 1
	controls.Size = UDim2.new(0, 70, 1, 0)
	controls.Position = UDim2.new(1, -82, 0, 0)
	controls.Parent = topbar

	local controlsList = Instance.new("UIListLayout")
	controlsList.FillDirection = Enum.FillDirection.Horizontal
	controlsList.VerticalAlignment = Enum.VerticalAlignment.Center
	controlsList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	controlsList.Padding = UDim.new(0, 10)
	controlsList.Parent = controls

	local minBtn = Instance.new("ImageButton")
	minBtn.Name = rname()
	minBtn.BackgroundTransparency = 1
	minBtn.Size = UDim2.new(0, 22, 0, 22)
	minBtn.Image = "rbxassetid://10137941941"
	minBtn.ImageColor3 = theme.Text
	minBtn.Parent = controls

	local closeBtn = Instance.new("ImageButton")
	closeBtn.Name = rname()
	closeBtn.BackgroundTransparency = 1
	closeBtn.Size = UDim2.new(0, 22, 0, 22)
	closeBtn.Image = "rbxassetid://10137832201"
	closeBtn.ImageColor3 = theme.Text
	closeBtn.Visible = false
	closeBtn.Parent = controls

	drag(main, topbar)

	local tabHolder, pageHolder
	if sideTabs then
		tabHolder = Instance.new("ScrollingFrame")
		tabHolder.Name = rname()
		tabHolder.BackgroundColor3 = theme.Secondary
		tabHolder.BorderSizePixel = 0
		tabHolder.Position = UDim2.new(0, 0, 0, 44)
		tabHolder.Size = UDim2.new(0.32, 0, 1, -44)
		tabHolder.ScrollingDirection = Enum.ScrollingDirection.Y
		tabHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
		tabHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
		tabHolder.ScrollBarThickness = 3
		tabHolder.ScrollBarImageColor3 = theme.Stroke
		tabHolder.Parent = main

		local tabList = Instance.new("UIListLayout")
		tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
		tabList.Padding = UDim.new(0, 8)
		tabList.Parent = tabHolder

		local tabPad = Instance.new("UIPadding")
		tabPad.PaddingTop = UDim.new(0, 14)
		tabPad.Parent = tabHolder

		pageHolder = Instance.new("Frame")
		pageHolder.Name = rname()
		pageHolder.BackgroundTransparency = 1
		pageHolder.Position = UDim2.new(0.32, 0, 0, 44)
		pageHolder.Size = UDim2.new(0.68, 0, 1, -44)
		pageHolder.Parent = main
	else
		tabHolder = Instance.new("ScrollingFrame")
		tabHolder.Name = rname()
		tabHolder.BackgroundTransparency = 1
		tabHolder.BorderSizePixel = 0
		tabHolder.Position = UDim2.new(0, 16, 0, 54)
		tabHolder.Size = UDim2.new(1, -32, 0, 40)
		tabHolder.ScrollingDirection = Enum.ScrollingDirection.X
		tabHolder.AutomaticCanvasSize = Enum.AutomaticSize.X
		tabHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
		tabHolder.ScrollBarThickness = 3
		tabHolder.ScrollBarImageColor3 = theme.Stroke
		tabHolder.Parent = main

		local tabList = Instance.new("UIListLayout")
		tabList.FillDirection = Enum.FillDirection.Horizontal
		tabList.VerticalAlignment = Enum.VerticalAlignment.Center
		tabList.Padding = UDim.new(0, 8)
		tabList.Parent = tabHolder

		pageHolder = Instance.new("Frame")
		pageHolder.Name = rname()
		pageHolder.BackgroundTransparency = 1
		pageHolder.Position = UDim2.new(0, 0, 0, 102)
		pageHolder.Size = UDim2.new(1, 0, 1, -102)
		pageHolder.Parent = main
	end

	local pagePad = Instance.new("UIPadding")
	pagePad.PaddingLeft = UDim.new(0, 16)
	pagePad.PaddingRight = UDim.new(0, 16)
	pagePad.PaddingTop = UDim.new(0, 12)
	if sideTabs then
		pagePad.PaddingTop = UDim.new(0, 0)
	end
	pagePad.PaddingBottom = UDim.new(0, 16)
	pagePad.Parent = pageHolder

	local pill = Instance.new("TextButton")
	pill.Name = rname()
	pill.BackgroundColor3 = theme.Secondary
	pill.AutoButtonColor = false
	pill.Visible = false
	pill.AnchorPoint = Vector2.new(0.5, 0)
	pill.Position = UDim2.new(0.5, 0, 0.04, 0)
	pill.Size = UDim2.new(0, 150, 0, 40)
	pill.Parent = gui

	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0)
	pillCorner.Parent = pill

	local pillStroke = Instance.new("UIStroke")
	pillStroke.Color = theme.Stroke
	pillStroke.Parent = pill

	local pillLabel = Instance.new("TextLabel")
	pillLabel.Name = rname()
	pillLabel.BackgroundTransparency = 1
	pillLabel.Size = UDim2.new(1, 0, 1, 0)
	pillLabel.FontFace = F.Medium
	pillLabel.Text = name
	pillLabel.TextColor3 = theme.Text
	pillLabel.TextSize = T.Label
	pillLabel.TextTruncate = Enum.TextTruncate.AtEnd
	pillLabel.Parent = pill

	drag(pill)

	local minimized = false
	local function toggleWindow()
		minimized = not minimized
		if minimized then
			TweenService:Create(main, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
			main.Visible = false
			pill.Visible = true
		else
			main.Visible = true
			main.Size = UDim2.new(winSize.X.Scale, winSize.X.Offset, 0, 44)
			pill.Visible = false
			TweenService:Create(main, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 }):Play()
		end
	end
	minBtn.Activated:Connect(toggleWindow)
	pill.Activated:Connect(function()
		if dragMoved then
			dragMoved = false
			return
		end
		toggleWindow()
	end)
	closeBtn.Activated:Connect(function()
		gui:Destroy()
	end)

	local tabBtns, tabLabels, tabPages, tabN = {}, {}, {}, 0
	local firstUserActivated
	local window = {}

	function window:Tab(tabName, tabIcon)
		local btn = Instance.new("TextButton")
		btn.Name = rname()
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.BackgroundColor3 = theme.Secondary
		if sideTabs then
			btn.Size = UDim2.new(0.86, 0, 0, 40)
		else
			btn.AutomaticSize = Enum.AutomaticSize.X
			btn.Size = UDim2.new(0, 0, 1, 0)
		end
		btn.Parent = tabHolder

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = sideTabs and UDim.new(0, 8) or UDim.new(1, 0)
		btnCorner.Parent = btn

		local btnPad = Instance.new("UIPadding")
		btnPad.PaddingLeft = UDim.new(0, sideTabs and 14 or 16)
		btnPad.PaddingRight = UDim.new(0, sideTabs and 14 or 16)
		btnPad.Parent = btn

		local btnList = Instance.new("UIListLayout")
		btnList.FillDirection = Enum.FillDirection.Horizontal
		btnList.VerticalAlignment = Enum.VerticalAlignment.Center
		btnList.Padding = UDim.new(0, 8)
		btnList.Parent = btn

		mkicon(tabIcon, "Tab", btn, UDim2.new(0, 16, 0, 16))

		local label = Instance.new("TextLabel")
		label.Name = rname()
		label.LayoutOrder = 2
		label.BackgroundTransparency = 1
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.new(0, 0, 1, 0)
		label.FontFace = F.Medium
		label.Text = tabName
		label.TextColor3 = theme.SubText
		label.TextSize = T.Label
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = btn

		local page = Instance.new("ScrollingFrame")
		page.Name = rname()
		page.BackgroundTransparency = 1
		page.Size = UDim2.new(1, 0, 1, 0)
		page.Visible = false
		page.ScrollBarThickness = 3
		page.ScrollBarImageColor3 = theme.Stroke
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.Parent = pageHolder

		local list = Instance.new("UIListLayout")
		list.Padding = UDim.new(0, 10)
		list.Parent = page

		list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 8)
		end)

		tabN = tabN + 1
		btn.LayoutOrder = tabN
		tabBtns[tabN] = btn
		tabLabels[tabN] = label
		tabPages[tabN] = page

		local function activate()
			for i = 1, tabN do
				tabPages[i].Visible = false
				tabLabels[i].TextColor3 = theme.SubText
				tabBtns[i].BackgroundColor3 = theme.Secondary
			end
			page.Visible = true
			label.TextColor3 = theme.AccentText
			btn.BackgroundColor3 = theme.Accent
		end
		btn.Activated:Connect(activate)

		if tabName == "Settings" then
			if tabN == 1 then
				activate()
			end
		elseif not firstUserActivated then
			firstUserActivated = true
			activate()
		end

		local tab = {}
		local order = 0
		local function next_order()
			order = order + 1
			return order
		end

		function tab:Section(text)
			local l = Instance.new("TextLabel")
			l.Name = rname()
			l.LayoutOrder = next_order()
			l.BackgroundTransparency = 1
			l.Size = UDim2.new(1, 0, 0, 24)
			l.FontFace = F.Bold
			l.Text = text
			l.TextColor3 = theme.SubText
			l.TextSize = T.Label
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Parent = page
		end

		function tab:Divider()
			local d = Instance.new("Frame")
			d.Name = rname()
			d.LayoutOrder = next_order()
			d.BackgroundColor3 = theme.Stroke
			d.BorderSizePixel = 0
			d.Size = UDim2.new(1, 0, 0, 1)
			d.Parent = page
		end

		function tab:Text(title, content, iconName)
			local f = Instance.new("Frame")
			f.Name = rname()
			f.LayoutOrder = next_order()
			f.BackgroundColor3 = theme.Secondary
			f.Size = UDim2.new(1, 0, 0, 0)
			f.AutomaticSize = Enum.AutomaticSize.Y
			f.Parent = page

			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 8)
			c.Parent = f

			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 16)
			pad.PaddingRight = UDim.new(0, 16)
			pad.PaddingTop = UDim.new(0, 14)
			pad.PaddingBottom = UDim.new(0, 14)
			pad.Parent = f

			local vlist = Instance.new("UIListLayout")
			vlist.Padding = UDim.new(0, 8)
			vlist.Parent = f

			local head = Instance.new("Frame")
			head.Name = rname()
			head.LayoutOrder = 1
			head.BackgroundTransparency = 1
			head.Size = UDim2.new(1, 0, 0, T.Title + 8)
			head.Parent = f

			local headList = Instance.new("UIListLayout")
			headList.FillDirection = Enum.FillDirection.Horizontal
			headList.VerticalAlignment = Enum.VerticalAlignment.Center
			headList.Padding = UDim.new(0, 8)
			headList.Parent = head

			mkicon(iconName, "Text", head, UDim2.new(0, 18, 0, 18))

			local titleL = Instance.new("TextLabel")
			titleL.Name = rname()
			titleL.LayoutOrder = 2
			titleL.BackgroundTransparency = 1
			titleL.Size = UDim2.new(1, -26, 1, 0)
			titleL.FontFace = F.Bold
			titleL.Text = title
			titleL.TextColor3 = theme.Text
			titleL.TextSize = T.Title
			titleL.TextXAlignment = Enum.TextXAlignment.Left
			titleL.TextTruncate = Enum.TextTruncate.AtEnd
			titleL.Parent = head

			local body = Instance.new("TextLabel")
			body.Name = rname()
			body.LayoutOrder = 2
			body.BackgroundTransparency = 1
			body.Size = UDim2.new(1, 0, 0, 0)
			body.AutomaticSize = Enum.AutomaticSize.Y
			body.FontFace = F.Medium
			body.Text = content
			body.TextColor3 = theme.SubText
			body.TextSize = T.Body
			body.TextXAlignment = Enum.TextXAlignment.Left
			body.TextWrapped = true
			body.Parent = f
		end

		local function card(h)
			local f = Instance.new("Frame")
			f.Name = rname()
			f.LayoutOrder = next_order()
			f.BackgroundColor3 = theme.Secondary
			f.Size = UDim2.new(1, 0, 0, h)
			f.Parent = page
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 8)
			c.Parent = f
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 16)
			pad.PaddingRight = UDim.new(0, 16)
			pad.Parent = f
			return f
		end

		function tab:Button(text, callback, iconName)
			local f = card(46)
			rowLabel(f, iconName, "Button", text, 0)
			local clickBtn = Instance.new("TextButton")
			clickBtn.Name = rname()
			clickBtn.BackgroundTransparency = 1
			clickBtn.Size = UDim2.new(1, 0, 1, 0)
			clickBtn.Text = ""
			clickBtn.Parent = f
			clickBtn.Activated:Connect(function()
				TweenService:Create(f, TweenInfo.new(0.08), { BackgroundColor3 = theme.Accent }):Play()
				task.delay(0.12, function()
					TweenService:Create(f, TweenInfo.new(0.15), { BackgroundColor3 = theme.Secondary }):Play()
				end)
				callback()
			end)
		end

		function tab:Toggle(text, callback, default, iconName)
			local f = card(46)
			rowLabel(f, iconName, "Toggle", text, 46)
			local sw = Instance.new("Frame")
			sw.Name = rname()
			sw.BackgroundColor3 = default and theme.Accent or theme.Stroke
			sw.AnchorPoint = Vector2.new(1, 0.5)
			sw.Position = UDim2.new(1, 0, 0.5, 0)
			sw.Size = UDim2.new(0, 40, 0, 22)
			sw.Parent = f
			local swc = Instance.new("UICorner")
			swc.CornerRadius = UDim.new(1, 0)
			swc.Parent = sw
			local circ = Instance.new("Frame")
			circ.Name = rname()
			circ.BackgroundColor3 = Color3.new(1, 1, 1)
			circ.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
			circ.Size = UDim2.new(0, 16, 0, 16)
			circ.Parent = sw
			local circc = Instance.new("UICorner")
			circc.CornerRadius = UDim.new(1, 0)
			circc.Parent = circ
			local clickBtn = Instance.new("TextButton")
			clickBtn.Name = rname()
			clickBtn.BackgroundTransparency = 1
			clickBtn.Size = UDim2.new(1, 0, 1, 0)
			clickBtn.Text = ""
			clickBtn.Parent = f
			local state = default and true or false
			clickBtn.Activated:Connect(function()
				state = not state
				TweenService:Create(
					circ,
					TweenInfo.new(0.15),
					{ Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) }
				):Play()
				TweenService
					:Create(sw, TweenInfo.new(0.15), { BackgroundColor3 = state and theme.Accent or theme.Stroke })
					:Play()
				callback(state)
			end)
		end

		function tab:Slider(text, min, max, default, callback, iconName)
			local f = card(70)
			local row = Instance.new("Frame")
			row.Name = rname()
			row.BackgroundTransparency = 1
			row.Position = UDim2.new(0, 0, 0, 10)
			row.Size = UDim2.new(1, 0, 0, 22)
			row.Parent = f
			local rl = Instance.new("UIListLayout")
			rl.FillDirection = Enum.FillDirection.Horizontal
			rl.VerticalAlignment = Enum.VerticalAlignment.Center
			rl.Padding = UDim.new(0, 8)
			rl.Parent = row
			mkicon(iconName, "Slider", row, UDim2.new(0, 14, 0, 14))
			local l = Instance.new("TextLabel")
			l.Name = rname()
			l.LayoutOrder = 2
			l.BackgroundTransparency = 1
			l.Size = UDim2.new(0.6, 0, 1, 0)
			l.FontFace = F.Medium
			l.Text = text
			l.TextColor3 = theme.Text
			l.TextSize = T.Label
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Parent = row
			local val = Instance.new("TextLabel")
			val.Name = rname()
			val.BackgroundTransparency = 1
			val.Size = UDim2.new(0.3, 0, 0, 22)
			val.Position = UDim2.new(0.7, 0, 0, 10)
			val.FontFace = F.Bold
			val.Text = tostring(default)
			val.TextColor3 = theme.Accent
			val.TextSize = T.Label
			val.TextXAlignment = Enum.TextXAlignment.Right
			val.Parent = f
			local bar = Instance.new("Frame")
			bar.Name = rname()
			bar.BackgroundColor3 = theme.Stroke
			bar.BorderSizePixel = 0
			bar.Position = UDim2.new(0, 0, 0, 46)
			bar.Size = UDim2.new(1, 0, 0, 6)
			bar.Parent = f
			local barc = Instance.new("UICorner")
			barc.CornerRadius = UDim.new(1, 0)
			barc.Parent = bar
			local fill = Instance.new("Frame")
			fill.Name = rname()
			fill.BackgroundColor3 = theme.Accent
			fill.BorderSizePixel = 0
			fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
			fill.Parent = bar
			local fillc = Instance.new("UICorner")
			fillc.CornerRadius = UDim.new(1, 0)
			fillc.Parent = fill
			local function move(x)
				local pos = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				local value = math.floor(min + (max - min) * pos + 0.5)
				fill.Size = UDim2.new(pos, 0, 1, 0)
				val.Text = tostring(value)
				callback(value)
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
		end

		function tab:Dropdown(text, options, callback, default, multi, iconName)
			local selected = {}
			if multi then
				if default then
					for i = 1, #default do
						selected[default[i]] = true
					end
				end
			else
				default = default or options[1]
			end
			local f = card(46)
			f.ClipsDescendants = true

			local function labelText()
				if not multi then
					return text .. ": " .. tostring(default)
				end
				local parts, n = {}, 0
				for i = 1, #options do
					local v = options[i]
					if selected[v] then
						n = n + 1
						parts[n] = tostring(v)
					end
				end
				if n == 0 then
					return text .. ": None"
				end
				return text .. ": " .. table.concat(parts, ", ")
			end

			local head = Instance.new("Frame")
			head.Name = rname()
			head.BackgroundTransparency = 1
			head.Size = UDim2.new(1, 0, 0, 22)
			head.Position = UDim2.new(0, 0, 0, 12)
			head.Parent = f
			local headList = Instance.new("UIListLayout")
			headList.FillDirection = Enum.FillDirection.Horizontal
			headList.VerticalAlignment = Enum.VerticalAlignment.Center
			headList.Padding = UDim.new(0, 10)
			headList.Parent = head
			mkicon(iconName, "Dropdown", head, UDim2.new(0, 16, 0, 16))

			local label = Instance.new("TextLabel")
			label.Name = rname()
			label.LayoutOrder = 2
			label.BackgroundTransparency = 1
			label.Size = UDim2.new(1, -26, 1, 0)
			label.FontFace = F.Medium
			label.Text = labelText()
			label.TextColor3 = theme.Text
			label.TextSize = T.Label
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextTruncate = Enum.TextTruncate.AtEnd
			label.Parent = head
			local list2 = Instance.new("Frame")
			list2.Name = rname()
			list2.BackgroundTransparency = 1
			list2.Position = UDim2.new(0, 0, 0, 46)
			list2.Size = UDim2.new(1, 0, 0, 0)
			list2.Parent = f
			local vl = Instance.new("UIListLayout")
			vl.Padding = UDim.new(0, 6)
			vl.Parent = list2
			local clickBtn = Instance.new("TextButton")
			clickBtn.Name = rname()
			clickBtn.LayoutOrder = 0
			clickBtn.BackgroundTransparency = 1
			clickBtn.Size = UDim2.new(1, 0, 0, 46)
			clickBtn.Text = ""
			clickBtn.Parent = f
			local opened = false
			clickBtn.Activated:Connect(function()
				opened = not opened
				local h = opened and (46 + #options * 34 + 8) or 46
				TweenService:Create(f, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, h) }):Play()
			end)
			for i = 1, #options do
				local v = options[i]
				local opt = Instance.new("TextButton")
				opt.Name = rname()
				opt.LayoutOrder = i
				local isSel = multi and selected[v]
				opt.BackgroundColor3 = isSel and theme.Accent or theme.Background
				opt.Size = UDim2.new(1, 0, 0, 32)
				opt.FontFace = F.Medium
				opt.Text = tostring(v)
				opt.TextColor3 = isSel and theme.AccentText or theme.SubText
				opt.TextSize = T.Body
				opt.TextTruncate = Enum.TextTruncate.AtEnd
				opt.Parent = list2
				local oc = Instance.new("UICorner")
				oc.CornerRadius = UDim.new(0, 6)
				oc.Parent = opt
				if multi then
					opt.Activated:Connect(function()
						if selected[v] then
							selected[v] = nil
							opt.BackgroundColor3 = theme.Background
							opt.TextColor3 = theme.SubText
						else
							selected[v] = true
							opt.BackgroundColor3 = theme.Accent
							opt.TextColor3 = theme.AccentText
						end
						label.Text = labelText()
						local list, n = {}, 0
						for j = 1, #options do
							local ov = options[j]
							if selected[ov] then
								n = n + 1
								list[n] = ov
							end
						end
						callback(list)
					end)
				else
					opt.Activated:Connect(function()
						default = v
						label.Text = labelText()
						opened = false
						f.Size = UDim2.new(1, 0, 0, 46)
						callback(v)
					end)
				end
			end
		end

		function tab:Keybind(text, callback, default, iconName)
			local f = card(46)
			rowLabel(f, iconName, "Keybind", text, 110)
			local bind = Instance.new("TextButton")
			bind.Name = rname()
			bind.BackgroundColor3 = theme.Background
			bind.AnchorPoint = Vector2.new(1, 0.5)
			bind.Position = UDim2.new(1, 0, 0.5, 0)
			bind.AutomaticSize = Enum.AutomaticSize.X
			bind.Size = UDim2.new(0, 0, 0, 30)
			bind.FontFace = F.Bold
			bind.Text = default.Name
			bind.TextColor3 = theme.Text
			bind.TextSize = T.Body
			bind.Parent = f
			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 6)
			bc.Parent = bind
			local bindPad = Instance.new("UIPadding")
			bindPad.PaddingLeft = UDim.new(0, 5)
			bindPad.PaddingRight = UDim.new(0, 5)
			bindPad.Parent = bind
			local bindMin = Instance.new("UISizeConstraint")
			bindMin.MinSize = Vector2.new(40, 0)
			bindMin.Parent = bind

			local key = default
			local listening = false

			bind.Activated:Connect(function()
				listening = true
				bind.Text = "..."
			end)
			UserInputService.InputBegan:Connect(function(i, gpe)
				if listening then
					if i.UserInputType == Enum.UserInputType.Keyboard then
						if i.KeyCode == Enum.KeyCode.Backspace then
							key = nil
							bind.Text = "None"
						else
							key = i.KeyCode
							bind.Text = key.Name
						end
						listening = false
					end
					return -- swallow
				end
				if not gpe and key and i.KeyCode == key then
					callback()
				end
			end)
		end

		function tab:Color(text, callback, default, iconName)
			local f = card(46)
			rowLabel(f, iconName, "Color", text, 58)
			local sw = Instance.new("TextButton")
			sw.Name = rname()
			sw.BackgroundColor3 = default
			sw.AnchorPoint = Vector2.new(1, 0.5)
			sw.Position = UDim2.new(1, 0, 0.5, 0)
			sw.Size = UDim2.new(0, 38, 0, 24)
			sw.Text = ""
			sw.Parent = f
			local sc = Instance.new("UICorner")
			sc.CornerRadius = UDim.new(0, 6)
			sc.Parent = sw
			local palette = {
				default,
				Color3.fromRGB(239, 68, 68),
				Color3.fromRGB(34, 197, 94),
				Color3.fromRGB(59, 130, 246),
				Color3.fromRGB(234, 179, 8),
				Color3.fromRGB(168, 85, 247),
				Color3.fromRGB(20, 184, 166),
				Color3.fromRGB(244, 244, 246),
			}
			local idx = 1
			sw.Activated:Connect(function()
				idx = idx % 8 + 1
				sw.BackgroundColor3 = palette[idx]
				callback(palette[idx])
			end)
		end

		return tab
	end

	function window.Settings()
		local settings = window:Tab("Settings", Icons.Settings)
		settings:Toggle("Show Icons", function(state)
			iconsOn = state
			for i = 1, iconN do
				icons[i].Visible = state
			end
		end, true)
		settings:Toggle("Close Button", function(state)
			closeBtn.Visible = state
		end, false)
		settings:Keybind("Collapse Window", toggleWindow, Enum.KeyCode.K)
	end

	return window
end

return Library