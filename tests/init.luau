--local Kvant = require(game:GetService("ReplicatedStorage").Kvant)
local Kvant = loadstring(game:HttpGet("http://127.0.0.1:6969/src/init.luau"))()

local function runTests(Kvant)
	local passed, failed = 0, 0
	local function check(name, fn)
		local ok, err = pcall(fn)
		if ok then passed += 1
		else
			failed += 1
			warn(("[X] %s -- %s"):format(name, tostring(err)))
		end
	end

	local function assertEq(got, want, label)
		if got ~= want then
			error(
				("%s: expected %s (%s), got %s (%s)"):format(
					label or "assertEq",
					tostring(want),
					typeof(want),
					tostring(got),
					typeof(got)
				),
				2
			)
		end
	end

	local function assertDeepEq(got, want, label)
		if typeof(got) ~= typeof(want) then
			error(
				("%s: type mismatch (got %s, expected %s)"):format(label or "assertDeepEq", typeof(got), typeof(want)),
				2
			)
		end
		if typeof(got) ~= "table" then
			if got ~= want then
				error(("%s: expected %s, got %s"):format(label or "assertDeepEq", tostring(want), tostring(got)), 2)
			end
			return
		end
		for k, v in pairs(want) do
			assertDeepEq(got[k], v, ("%s[%s]"):format(label or "assertDeepEq", tostring(k)))
		end
		for k, _ in pairs(got) do
			if want[k] == nil then
				error(("%s: unexpected extra key '%s'"):format(label or "assertDeepEq", tostring(k)), 2)
			end
		end
	end

	local function assertColorEq(got, want, label)
		local function close(a, b)
			return math.abs(a - b) < (2 / 255)
		end
		if not (close(got.R, want.R) and close(got.G, want.G) and close(got.B, want.B)) then
			error(
				("%s mismatch (expected %s, got %s)"):format(label or "assertColorEq", tostring(want), tostring(got)),
				2
			)
		end
	end

	local function assertErrors(fn, label)
		local ok, _ = pcall(fn)
		if ok then
			error((label or "assertErrors") .. ": expected an error, but function succeeded", 2)
		end
	end

	do -- 1. Library-Level APIs: Theme & Font Engine
		check("Library:SetFont with family identifier", function()
			Kvant:SetFont("Ubuntu")
			assertEq(typeof(Kvant.Config.Fonts.Medium), "Font", "Font instance set")
			Kvant:SetFont("Roboto") -- Reset
		end)
		check("Kvant:GetThemeNames returns built-in theme names", function()
			local names = Kvant:GetThemeNames()
			assertEq(typeof(names), "table", "Names is table")
			local found = false
			for _, n in names do
				if n == "Darker" then
					found = true
				end
			end
			assertEq(found, true, "Contains 'Darker'")
		end)
		check("Kvant:GetThemePreset returns a built-in theme table", function()
			local preset = Kvant:GetThemePreset("Dark")
			assertEq(typeof(preset), "table", "Preset is table")
			assertEq(typeof(preset.Accent), "Color3", "Preset has Accent Color3")
		end)
		check("Kvant:GetThemePreset returns nil for an unknown name", function()
			assertEq(Kvant:GetThemePreset("NoSuchTheme"), nil, "Unknown preset is nil")
		end)
		check("Kvant:SetTheme applies a built-in preset by name", function()
			Kvant:SetTheme("Light")
			assertEq(
				Kvant:GetTheme().Background,
				Kvant:GetThemePreset("Light").Background,
				"Active theme matches Light preset"
			)
			Kvant:SetTheme("Darker") -- Reset
		end)
		check("Kvant:SetTheme rejects a table missing required keys", function()
			local before = Kvant:GetTheme()
			Kvant:SetTheme({ Background = Color3.new(0, 0, 0) }) -- missing Secondary/Accent/Stroke/Text/SubText - it's ok
			assertEq(Kvant:GetTheme(), before, "Invalid theme left the active theme unchanged")
		end)
		check("Kvant.Icons exposes a built-in icon name map", function()
			assertEq(typeof(Kvant.Icons), "table", "Icons is a table")
			assertEq(typeof(Kvant.Icons.button), "string", "Icons.button resolves to an asset id")
		end)
	end

	do -- 2. Declarative Scope Guard Tests
		check("Declarative methods outside any active scope throw errors", function()
			assertErrors(function()
				(Kvant.Toggle)("Fail", false)
			end, "Toggle outside scope")
			assertErrors(function()
				(Kvant.Slider)("Fail", 0, 10, 5)
			end, "Slider outside scope")
			assertErrors(function()
				(Kvant.Section)("Fail", function() end)
			end, "Section outside scope")
		end)
		check("Window Builder scope only exposes Tab declaratively", function()
			local tabWorked, othersFailed
			local scopeWin = Kvant:CreateWindow({
				Name = "__ScopeTest",
				ShowSearch = false,
				Builder = function()
					tabWorked = pcall(function()
						(Kvant.Tab)("Probe")
					end)
					othersFailed = not pcall(function()
						(Kvant.Toggle)("Fail", false)
					end)
				end,
			})
			assertEq(tabWorked, true, "Tab is callable at window scope")
			assertEq(othersFailed, true, "Toggle is not callable at window scope")
			scopeWin:Destroy()
		end)
	end

	-- 3. Window & Tab Lifecycle
	local win = Kvant:CreateWindow({ Name = "__KvantTest", ShowSearch = false })
	local tab = win:Tab("CoreTest")

	check("Window & Tab Instance Hierarchy", function()
		assertEq(typeof(win), "table", "Window handle")
		assertEq(typeof(tab), "table", "Tab handle")
		assertEq(tab.Instance:IsA("ScrollingFrame"), true, "Tab.Instance is ScrollingFrame")
		assertEq(tab.TabButton:IsA("TextButton"), true, "Tab.TabButton is TextButton")
	end)

	check("Window:Notify executes without error", function()
		win:Notify("Test Notification", 0.5)
	end)

	-- Common Surface Assertion for Interactive Elements
	local function checkCommon(label, h)
		check(label .. " base properties: Instance type", function()
			assertEq(h.Instance:IsA("Frame"), true, "Instance is Frame")
		end)
		check(label .. " base properties: Label read/write", function()
			local original = h.Label
			h.Label = "ModifiedLabel"
			assertEq(h.Label, "ModifiedLabel", "Label set")
			h.Label = original
		end)
		check(label .. " base properties: Icon read/write", function()
			h.Icon = "rbxassetid://12345"
			assertEq(h.Icon, "rbxassetid://12345", "Icon set")
			h.Icon = nil
			assertEq(h.Icon, nil, "Icon cleared")
		end)
		check(label .. " base properties: Tooltip read/write", function()
			h.Tooltip = "Tooltip info"
			assertEq(h.Tooltip, "Tooltip info", "Tooltip set")
			h.Tooltip = nil
			assertEq(h.Tooltip, nil, "Tooltip cleared")
		end)
		check(label .. " base properties: Locked interaction guard", function()
			h.Locked = true
			assertEq(h.Locked, true, "Locked = true")
			h.Locked = false
			assertEq(h.Locked, false, "Locked = false")
		end)
		check(label .. " metatable safety: strict property access", function()
			assertErrors(function()
				return h.NonExistentField
			end, "Unknown field read")
			assertErrors(function()
				h.NonExistentField = 123
			end, "Unknown field write")
		end)
	end

	do -- 4. Toggle Component
		local fired, lastState, lastFromUser = 0, nil, nil
		local h = tab:Toggle("ToggleElem", false, function(state, fromUser)
			fired += 1
			lastState = state
			lastFromUser = fromUser
		end, nil, "Toggle tooltip")
		check("Toggle default state", function()
			assertEq(h.Value, false, "Default Value")
		end)
		check("Toggle programmatic write updates state & invokes callback", function()
			h.Value = true
			assertEq(h.Value, true, "Updated Value")
			assertEq(fired, 1, "Callback fired once")
			assertEq(lastState, true, "Callback state payload")
			assertEq(lastFromUser, false, "Callback fromUser false")
		end)
		check("Toggle.Changed event dispatches correctly", function()
			local sigFired, sigState, sigFromUser = 0, nil, nil
			local conn = h.Changed:Connect(function(st, user)
				sigFired += 1
				sigState = st
				sigFromUser = user
			end)
			h.Value = false
			assertEq(sigFired, 1, "Signal fired")
			assertEq(sigState, false, "Signal state payload")
			assertEq(sigFromUser, false, "Signal fromUser payload")
			conn:Disconnect()
		end)
		checkCommon("Toggle", h)
	end

	do -- 5. Slider Component
		local fired, lastVal = 0, nil
		local h = tab:Slider("SliderElem", 0, 100, 25, 5, function(val)
			fired += 1
			lastVal = val
		end)
		check("Slider default value and step clamping", function()
			assertEq(h.Value, 25, "Default Value")
			assertEq(h.Min, 0, "Min")
			assertEq(h.Max, 100, "Max")
			assertEq(h.Step, 5, "Step")
		end)
		check("Slider clamps values to Min and Max", function()
			h.Value = 250
			assertEq(h.Value, 100, "Clamped to Max")
			h.Value = -50
			assertEq(h.Value, 0, "Clamped to Min")
		end)
		check("Slider respects step rounding", function()
			h.Value = 23 -- Closest step of 5 is 25
			assertEq(h.Value, 25, "Rounded to step")
			h.Value = 22 -- Closest step of 5 is 20
			assertEq(h.Value, 20, "Rounded to step")
		end)
		check("Slider dynamic Min/Max/Step mutators reclamp current value", function()
			h.Max = 15
			assertEq(h.Max, 15, "New Max")
			assertEq(h.Value, 15, "Value reclamped to new Max")

			h.Step = 0.5
			assertEq(h.Step, 0.5, "New Step")
			h.Value = 10.24
			assertEq(h.Value, 10, "Value rounded by new Step")
		end)
		check("Slider.Dragging is read-only", function()
			assertEq(h.Dragging, false, "Dragging default")
			assertErrors(function()
				(h).Dragging = true
			end, "Dragging write")
		end)
		checkCommon("Slider", h)
	end

	check("Slider opts.Suffix appends a unit to the displayed value", function()
		local h = tab:Slider("SuffixSlider", 0, 100, 50, 1, nil, nil, nil, { Suffix = "%" })
		assertEq(h.Suffix, "%", "Suffix from opts")
		h.Suffix = "pts"
		assertEq(h.Suffix, "pts", "Suffix updated")
	end)

	do -- 6. Dropdown Component (Single & Multi-Select)
		local hSingle = tab:Dropdown("SingleDD", { "A", "B", "C" }, "A", nil)
		check("Dropdown (Single) default and selection", function()
			assertEq(hSingle.Multi, false, "Multi flag false")
			assertEq(hSingle.Value, "A", "Default Value")
			hSingle.Value = "C"
			assertEq(hSingle.Value, "C", "Updated Value")
		end)
		check("Dropdown.Options rebuilds list", function()
			hSingle.Options = { "Alpha", "Beta", "Gamma" }
			assertDeepEq(hSingle.Options, { "Alpha", "Beta", "Gamma" }, "New Options")
		end)
		check("Dropdown.Open state controls visibility", function()
			hSingle.Open = true
			assertEq(hSingle.Open, true, "Open true")
			hSingle.Open = false
			assertEq(hSingle.Open, false, "Open false")
		end)
		check("Dropdown.Multi property is runtime modifyable", function()
			hSingle.Multi = true
			assertEq(hSingle.Multi, true, "modify Multi at runtime")
			hSingle.Multi = false
			assertEq(hSingle.Multi, false, "modify Multi at runtime")
		end)
		checkCommon("Dropdown (Single)", hSingle)
		local hMulti = tab:Dropdown("MultiDD", { "X", "Y", "Z" }, { "X", "Z" }, nil)
		check("Dropdown (Multi) default and array assignment", function()
			assertEq(hMulti.Multi, true, "Multi flag true")
			assertDeepEq(hMulti.Value, { "X", "Z" }, "Default Multi Value")
			hMulti.Value = { "Y" }
			assertDeepEq(hMulti.Value, { "Y" }, "Updated Multi Value")
		end)
		checkCommon("Dropdown (Multi)", hMulti)
		check("Dropdown opts.Multi forces multi-select with a scalar default", function()
			local h = tab:Dropdown("SingleDefaultMultiDD", { "P", "Q" }, "P", nil, nil, nil, { Multi = true })
			assertEq(h.Multi, true, "Multi flag true via opts")
			assertDeepEq(h.Value, { "P" }, "Scalar default pre-selects one item")
		end)
		check("Dropdown opts.Searchable toggles the inline filter box", function()
			local h = tab:Dropdown(
				"SearchableDD",
				{ "One", "Two", "Three" },
				"One",
				nil,
				nil,
				nil,
				{ Searchable = true }
			)
			assertEq(h.Searchable, true, "Searchable from opts")
			h.Searchable = false
			assertEq(h.Searchable, false, "Searchable updated")
		end)
	end

	do -- 7. Keybind Component
		local h = tab:Keybind("KeybindElem", Enum.KeyCode.F)
		check("Keybind default Value", function()
			assertEq(h.Value, Enum.KeyCode.F, "Default KeyCode")
		end)
		check("Keybind accepts Enum.KeyCode, string name, and nil", function()
			h.Value = Enum.KeyCode.E
			assertEq(h.Value, Enum.KeyCode.E, "Set via EnumItem")
			h.Value = "R"
			assertEq(h.Value, Enum.KeyCode.R, "Set via string name")
			h.Value = "None"
			assertEq(h.Value, nil, "Cleared via 'None'")
			h.Value = nil
			assertEq(h.Value, nil, "Cleared via nil")
		end)
		check("Keybind.Changed fires when the binding changes", function()
			local fired, lastVal = 0, nil
			local conn = h.Changed:Connect(function(v)
				fired += 1
				lastVal = v
			end)
			h.Value = Enum.KeyCode.G
			assertEq(fired, 1, "Changed fired once")
			assertEq(lastVal, Enum.KeyCode.G, "Changed payload")
			conn:Disconnect()
		end)
		check("Keybind.Pressed is a connectable signal", function()
			assertEq(typeof(h.Pressed.Connect), "function", "Pressed exposes Connect")
		end)
		check("Keybind.Listening is read-only", function()
			assertEq(h.Listening, false, "Listening default")
			assertErrors(function()
				(h).Listening = true
			end, "Listening write")
		end)
		checkCommon("Keybind", h)
	end

	do -- 8. Input Component
		local h = tab:Input("InputElem", "Placeholder...", "InitialText", nil)
		check("Input default and placeholder", function()
			assertEq(h.Value, "InitialText", "Default Value")
			assertEq(h.Placeholder, "Placeholder...", "Default Placeholder")
			h.Placeholder = "New Hint"
			assertEq(h.Placeholder, "New Hint", "Updated Placeholder")
		end)
		check("Input MaxLength truncates text", function()
			h.MaxLength = 5
			assertEq(h.MaxLength, 5, "MaxLength property")
			h.Value = "HelloWorld"
			assertEq(h.Value, "Hello", "Value truncated to MaxLength")
			h.MaxLength = nil
			h.Value = "HelloWorld"
			assertEq(h.Value, "HelloWorld", "Value accepts full string with MaxLength nil")
		end)
		checkCommon("Input", h)
	end

	check("Input opts.DigitsOnly strips non-digit characters live", function()
		local h = tab:Input("DigitsInput", "", "", nil, nil, nil, { DigitsOnly = true })
		assertEq(h.DigitsOnly, true, "DigitsOnly from opts")
		h.Value = "abc123"
		assertEq(h.Value, "123", "Non-digit characters stripped")
		h.DigitsOnly = false
		h.Value = "abc123"
		assertEq(h.Value, "abc123", "Filter disabled after DigitsOnly = false")
	end)

	do -- 9. Textarea Component
		local h = tab:Textarea("TextareaElem", "Placeholder...", "Initial\nBody", nil)
		check("Textarea default and placeholder", function()
			assertEq(h.Value, "Initial\nBody", "Default Value")
			assertEq(h.Placeholder, "Placeholder...", "Default Placeholder")
			h.Placeholder = "New Hint"
			assertEq(h.Placeholder, "New Hint", "Updated Placeholder")
		end)
		check("Textarea MaxLength truncates text", function()
			h.MaxLength = 5
			assertEq(h.MaxLength, 5, "MaxLength property")
			h.Value = "HelloWorld"
			assertEq(h.Value, "Hello", "Value truncated to MaxLength")
			h.MaxLength = nil
		end)
		check("Textarea.Changed dispatches correctly", function()
			local fired, lastVal = 0, nil
			local conn = h.Changed:Connect(function(v)
				fired += 1
				lastVal = v
			end)
			h.Value = "Updated"
			assertEq(fired, 1, "Changed fired once")
			assertEq(lastVal, "Updated", "Changed payload")
			conn:Disconnect()
		end)
		checkCommon("Textarea", h)
	end

	do -- 10. Color Component
		local defaultCol = Color3.fromRGB(255, 128, 64)
		local h = tab:Color("ColorElem", defaultCol)
		check("Color default Value and Hex accessor", function()
			assertColorEq(h.Value, defaultCol, "Default Value")
			assertEq(h.Hex, "#FF8040", "Hex string representation")
		end)
		check("Color set via Color3, Hex string, and RGB dictionary", function()
			h.Value = Color3.fromRGB(0, 255, 0)
			assertColorEq(h.Value, Color3.fromRGB(0, 255, 0), "Set via Color3")
			assertEq(h.Hex, "#00FF00", "Hex updated")

			h.Hex = "#0000FF"
			assertColorEq(h.Value, Color3.fromRGB(0, 0, 255), "Set via Hex property")

			h.Value = { R = 255, G = 255, B = 0 }
			assertColorEq(h.Value, Color3.fromRGB(255, 255, 0), "Set via RGB table")
		end)

		checkCommon("Color", h)
	end
	check("Color default accepts a hex string, matching .Value setter semantics", function()
		local h = tab:Color("ColorFromHex", "#336699")
		assertColorEq(h.Value, Color3.fromRGB(0x33, 0x66, 0x99), "Default parsed from hex string")
	end)

	do -- 11. Button Component
		local firedCount = 0
		local h = tab:Button("ButtonElem", function()
			firedCount += 1
		end)

		check("Button:Fire() executes callback and fires Activated signal", function()
			local sigFired = false
			local conn = h.Activated:Connect(function()
				sigFired = true
			end)
			h:Fire()
			assertEq(firedCount, 1, "Callback executed")
			assertEq(sigFired, true, "Activated signal fired")
			conn:Disconnect()
		end)

		checkCommon("Button", h)
	end

	do -- 12. Text Component
		local hDual = tab:Text("Heading", "Content body")
		local hSingle = tab:Text("Sole content")
		check("Text dual constructor sets Title and Value", function()
			assertEq(hDual.Title, "Heading", "Title set")
			assertEq(hDual.Value, "Content body", "Value set")
		end)
		check("Text single constructor leaves Title nil", function()
			assertEq(hSingle.Title, nil, "Title is nil")
			assertEq(hSingle.Value, "Sole content", "Value set")
		end)
		check("Text Title mutation controls visibility", function()
			hSingle.Title = "Added Title"
			assertEq(hSingle.Title, "Added Title", "Title assigned")
			hSingle.Title = ""
			assertEq(hSingle.Title, nil, "Title reset to nil when set empty")
		end)
		check("Text component excludes Locked property", function()
			assertErrors(function()
				return (hDual).Locked
			end, "Text.Locked read")
			assertErrors(function()
				(hDual).Locked = true
			end, "Text.Locked write")
		end)
	end

	do -- 13. Section & Divider Components
		local sec = tab:Section("CollapsibleSection", false)
		local div = tab:Divider()
		check("Divider returns Frame instance", function()
			assertEq(div.Instance:IsA("Frame"), true, "Divider Instance is Frame")
		end)
		check("Section exposes Header and sub-container elements", function()
			assertEq(sec.Instance:IsA("Frame"), true, "Section Instance is Frame")
			assertEq(sec.Header:IsA("TextButton"), true, "Section Header is TextButton")
		end)
		check("Section.Open is a reactive property, not a method", function()
			assertEq(sec.Open, true, "Open defaults to true (collapsed = false)")
			sec.Open = false
			assertEq(sec.Open, false, "Open set to false")
			sec.Open = true
			assertEq(sec.Open, true, "Open set back to true")
		end)
		check("Section acts as a functional nested Container", function()
			local nestedToggle = sec:Toggle("NestedToggle", true)
			assertEq(nestedToggle.Value, true, "Nested Toggle instantiated")
			assertEq(nestedToggle.Instance.Parent, sec.Instance, "Nested element parented to Section")
		end)
	end

	do -- 14. opts.Id and opts.Locked
		check("opts.Locked disables a control immediately on creation", function()
			local h = tab:Toggle("PreLocked", false, nil, nil, nil, { Locked = true })
			assertEq(h.Locked, true, "Locked at creation via opts")
		end)
		check("opts.Id is accepted without altering the control's Label", function()
			local h = tab:Toggle("RenameableLabel", false, nil, nil, nil, { Id = "stable_toggle_key" })
			assertEq(h.Label, "RenameableLabel", "Label unaffected by opts.Id")
		end)
	end
	-- 15. Icon token resolution
	check("Named icon tokens resolve via Kvant.Icons", function()
		local probe = tab:Button("__IconProbe", function() end)
		probe.Icon = "close"
		assertEq(probe.Icon, Kvant.Icons.close, "Icon resolved through the built-in icon map")
	end)

	win:Destroy() -- Clean up first test window

	do -- 16. Declarative Scoped Window Builder & Dev Mode Reset Test
		local capturedToggle = nil
		local devWin = Kvant:CreateWindow({
			Name = "__DevTest",
			Dev = true,
			ShowSearch = false,
			Builder = function(w)
				w:Tab("DevTab", function()
					capturedToggle = (Kvant.Toggle)("ResetOnDestroy", true)
				end)
			end,
		})
		check("Window Builder executed declaratively", function()
			assertEq(typeof(capturedToggle), "table", "Toggle created within Builder")
			assertEq(capturedToggle.Value, true, "Toggle initialized true")
		end)
		check("Window Dev mode resets all toggles to false on Destroy()", function()
			devWin:Destroy()
			assertEq(capturedToggle.Value, false, "Toggle value reset to false")
		end)
	end
	print(("Results: %d Passed, %d Failed"):format(passed, failed))
end

runTests(Kvant)
