--!strict
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local InterfaceShared = require(script.Parent.InterfaceShared)
local ThemePresets = require(script.Parent.DesignKit.ThemePresets)
local Tokens = require(script.Parent.DesignKit.Tokens)

local InterfacePageSettings = {}

function InterfacePageSettings.build(Shared: InterfaceShared.Shared)
	local Kit = Shared.Kit
	local C = Shared.C
	local positionText = Shared.positionText
	local liven = Shared.liven
	local layoutPage = Shared.layoutPage
	local own = Shared.own
	local connect = Shared.connect
	local cancel = Shared.cancel
	local defer = Shared.defer
	local trace = Shared.trace
	local preferences = Shared.preferences
	local pages = Shared.pages
	local settingRefresh = Shared.fn.settingRefresh

	local settingRows = {}
	local flushThread: thread? = nil

	local function flushPreferences()
		if flushThread then
			cancel(flushThread)
			flushThread = nil
			pcall(Shared.Preferences.FireServer, Shared.Preferences, preferences)
		end
	end
	own(flushPreferences)

	local function changePreference(key: string, value: any)
		if preferences[key] == value then return end

		local previous = preferences[key]
		preferences[key] = value

		if type(value) == "boolean" then
			Kit.sound(if value then "toggle_on" else "toggle_off")
		else
			Kit.sound("slider")
		end

		trace("settings: %s %s -> %s", key, tostring(previous), tostring(value))
		Shared.refreshPresentation()

		for _, callback in ipairs(settingRefresh) do
			callback()
		end

		cancel(flushThread)
		flushThread = defer(0.25, flushPreferences)
	end

	local settingDefinitions = {
		{ "music", "Background Music", "Ambient background soundtrack." },
		{ "sfx", "Sound Effects", "Audio cues for actions, clicks, and milestones." },
		{ "hover", "Hover Feedback", "Subtle audio cue when hovering interactive elements." },
		{ "masterVolume", "Master Volume", "Overall game sound level.", true },
		{ "sfxVolume", "Effects Volume", "Volume for clicks, upgrades, and rewards.", true },
		{ "musicVolume", "Music Volume", "Volume for background soundtrack.", true },
		{ "motion", "Interface Motion", "Smooth spring transitions and button physics." },
		{ "notifications", "Notifications", "Toast alerts for milestone completions." },
		{ "previews", "3D Viewports", "Render interactive 3D hardware previews." },
		{ "autoOrbit", "Auto Viewport Rotation", "Slowly orbit visible 3D hardware cameras." },
		{ "orbitSpeed", "Auto Orbit Speed", "Rotational speed of 3D viewports.", true },
		{ "particles", "Ambient Particles", "Celebratory confetti and particle effects." },
	}

	local dragging: { input: InputObject, update: (number) -> () }? = nil

	for _, definition in ipairs(settingDefinitions) do
		local key = definition[1]
		local isSlider = definition[4] == true

		local card = Kit.interactiveCard(pages.settings, "Setting_" .. key, 88, C.panel)

		local title = positionText(card, "Title", definition[2], 20, 16, 500, 24, 15, C.text, true)
		local detail = positionText(card, "Detail", definition[3], 20, 44, 500, 28, 12, C.textSub)
		detail.TextWrapped = true

		local control: GuiObject

		if isSlider then
			local sliderBtn = Kit.create("TextButton", card, {
				Name = "Slider",
				Text = "",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(200, 40),
				AutoButtonColor = false,
			})
			control = sliderBtn

			local trackRoot, fill = Kit.progress(sliderBtn, "Track")
			trackRoot.Position = UDim2.new(0, 0, 0.5, -2)
			trackRoot.Size = UDim2.new(1, -44, 0, 4)

			local thumb = Kit.create("Frame", trackRoot, {
				Name = "Thumb",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(16, 16),
				BackgroundColor3 = C.text,
				BorderSizePixel = 0,
			})
			Kit.corner(thumb, 8)

			local valLabel = Kit.text(sliderBtn, "Value", "100%", 11, C.accent, true)
			valLabel.Font = Enum.Font.RobotoMono
			valLabel.Position = UDim2.new(1, -38, 0, 0)
			valLabel.Size = UDim2.fromOffset(38, 40)
			valLabel.TextXAlignment = Enum.TextXAlignment.Right

			local function updateSlider(x: number)
				local span = math.max(1, trackRoot.AbsoluteSize.X)
				local ratio = math.clamp((x - trackRoot.AbsolutePosition.X) / span, 0, 1)
				changePreference(key, math.floor(ratio * 100 + 0.5) / 100)
			end

			sliderBtn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = { input = input, update = updateSlider }
					pages.settings.ScrollingEnabled = false
					updateSlider(input.Position.X)
				end
			end)

			table.insert(settingRefresh, function()
				local amount = preferences[key] or 1
				fill.Size = UDim2.fromScale(amount, 1)
				thumb.Position = UDim2.fromScale(amount, 0.5)
				valLabel.Text = math.floor(amount * 100 + 0.5) .. "%"
			end)
		else
			local toggle = Kit.toggle(card, "Toggle", preferences[key] == true, function(val)
				changePreference(key, val)
			end)
			control = toggle.instance

			table.insert(settingRefresh, function()
				toggle.set(preferences[key] == true, false)
			end)
		end

		table.insert(settingRows, {
			card = card,
			title = title,
			detail = detail,
			control = control,
			slider = isSlider,
		})
	end

	local function stopDrag()
		if dragging then
			dragging = nil
			pages.settings.ScrollingEnabled = true
		end
	end

	connect(UserInputService.InputChanged, function(input)
		if dragging and (input == dragging.input or input.UserInputType == Enum.UserInputType.MouseMovement) then
			dragging.update(input.Position.X)
		end
	end)

	connect(UserInputService.InputEnded, function(input)
		if dragging and (input == dragging.input or input.UserInputType == Enum.UserInputType.MouseButton1) then
			stopDrag()
		end
	end)

	connect(UserInputService.WindowFocusReleased, stopDrag)

	-- =========================================================================
	-- 2. OPERATOR CALL SIGN CARD
	-- =========================================================================
	local callsignCard = Kit.interactiveCard(pages.settings, "Callsign", 110, C.panel)

	local callsignBadge = Kit.badge(callsignCard, "Identity", "accent", true)
	Kit.place(callsignBadge, 20, 16, 70, 20)

	local callsignTitle = positionText(callsignCard, "Title", "Operator Call Sign", 98, 14, 400, 24, 15, C.text, true)
	local callsignDetail = positionText(
		callsignCard,
		"Detail",
		"Broadcast handle displayed on navigation telemetry and global standings.",
		20,
		42,
		500,
		26,
		12,
		C.textSub
	)
	callsignDetail.TextWrapped = true

	local callsignField = Kit.input(callsignCard, "Field", "Enter call sign…")

	local callsignSave = liven(Kit.button(callsignCard, "Save", "Save Handle", function()
		Shared.fn.act("callsign", callsignField.Text)
		Kit.floatText(callsignSave, "Handle Saved", C.accent, Vector2.new(0.5, 0.4))
	end, "primary"))

	local callsignSeeded = false
	Shared.bind("settings", function(s)
		if not callsignSeeded then
			callsignSeeded = true
			callsignField.Text = s.callsign or ""
		end
	end)

	-- =========================================================================
	-- 3. THEME ACCENT PICKER
	-- =========================================================================
	local themeCard = Kit.interactiveCard(pages.settings, "ThemePalette", 110, C.panel)

	local themeBadge = Kit.badge(themeCard, "Palette", "accent", true)
	Kit.place(themeBadge, 20, 16, 64, 20)

	local themeTitle = positionText(themeCard, "Title", "Accent Color Theme", 92, 14, 400, 24, 15, C.text, true)
	local themeDetail = positionText(
		themeCard,
		"Detail",
		"Accent highlight applied across buttons, indicators, and telemetry.",
		20,
		42,
		500,
		26,
		12,
		C.textSub
	)
	themeDetail.TextWrapped = true

	local themeSwatches = {}
	for _, key in ipairs(ThemePresets.order) do
		local preset = ThemePresets.presets[key]
		local swatch = Kit.create("TextButton", themeCard, {
			Name = "Swatch_" .. key,
			Text = "",
			BackgroundColor3 = preset.accent,
			AutoButtonColor = false,
			Size = UDim2.fromOffset(32, 32),
		})
		Kit.corner(swatch, 16)
		local ring = Kit.stroke(swatch, C.text, 1, false)
		ring.Thickness = 2

		local scale = Kit.create("UIScale", swatch, { Name = "Scale" })

		swatch.MouseEnter:Connect(function()
			if preferences.motion ~= false and Shared.SpringDriver then
				Shared.SpringDriver.animate(scale, "hover", { Scale = 1.12 }, "snappy")
			end
		end)
		swatch.MouseLeave:Connect(function()
			if preferences.motion ~= false and Shared.SpringDriver then
				local active = preferences.accentTheme or ThemePresets.default
				Shared.SpringDriver.animate(scale, "hover", { Scale = if key == active then 1.08 else 1.0 }, "snappy")
			end
		end)

		swatch.Activated:Connect(function()
			changePreference("accentTheme", key)
			if preferences.motion ~= false and Shared.SpringDriver then
				Shared.SpringDriver.animate(scale, "click", { Scale = 1.15 }, "snappy")
			end
		end)

		themeSwatches[key] = { button = swatch, ring = ring, scale = scale }
	end

	local function refreshThemeSwatches()
		local active = preferences.accentTheme or ThemePresets.default
		for key, entry in pairs(themeSwatches) do
			local isActive = key == active
			entry.ring.Transparency = if isActive then 0 else 1
			if Shared.SpringDriver and (preferences.motion ~= false) then
				Shared.SpringDriver.animate(entry.scale, "hover", { Scale = if isActive then 1.08 else 1.0 }, "smooth")
			end
		end
	end
	refreshThemeSwatches()
	table.insert(settingRefresh, refreshThemeSwatches)

	-- =========================================================================
	-- 4. GUIDED SETUP TOUR REPLAY
	-- =========================================================================
	local guideCard = Kit.interactiveCard(pages.settings, "GuidedSetup", 110, C.panel)
	local guideBadge = Kit.badge(guideCard, "Tour", "accent", true)
	Kit.place(guideBadge, 20, 16, 50, 20)

	local guideTitle = positionText(guideCard, "Title", "Interactive Guided Tour", 78, 14, 360, 24, 15, C.text, true)
	local guideDetail = positionText(guideCard, "Detail", "Relaunch the interactive console walkthrough at any time.", 20, 42, 420, 26, 12, C.textSub)
	guideDetail.TextWrapped = true

	local guideButton = liven(Kit.button(guideCard, "Replay", "Replay Walkthrough", function()
		Shared.fn.showTutorial(1)
	end, "primary"))

	-- =========================================================================
	-- 5. RESPONSIVE STACK LAYOUT
	-- =========================================================================
	layoutPage("settings", function(w)
		local narrow = w < 620
		local rowHeight = if narrow then 146 else 88

		local cards = {}
		for _, item in ipairs(settingRows) do
			table.insert(cards, { item.card, rowHeight })
		end
		local y = Kit.stack(cards, 0, 137, w, 10)

		for _, item in ipairs(settingRows) do
			local copyWidth = w - (if narrow then 40 elseif item.slider then 280 else 110)

			item.title.Size = UDim2.fromOffset(copyWidth, if narrow then 32 else 26)
			item.title.TextSize = if narrow then 14 else 15
			item.detail.Position = UDim2.fromOffset(20, if narrow then 48 else 44)
			item.detail.Size = UDim2.fromOffset(copyWidth, if narrow then 38 else 28)

			if item.slider then
				Kit.place(item.control, if narrow then 20 else w - 240, if narrow then 94 else 24, if narrow then w - 40 else 220, 40)
			else
				Kit.place(item.control, if narrow then 20 else w - 60, if narrow then 94 else 24, 40, 40)
			end
		end

		-- Callsign
		local narrowCallsign = w < 540
		Kit.place(callsignCard, 0, y, w, if narrowCallsign then 160 else 110)
		callsignTitle.Size = UDim2.fromOffset(w - 120, 24)
		callsignDetail.Size = UDim2.fromOffset(w - 40, 28)
		if narrowCallsign then
			Kit.place(callsignField, 20, 80, w - 40, 40)
			Kit.place(callsignSave, 20, 122, math.min(160, w - 40), 38)
		else
			Kit.place(callsignField, 20, 58, math.max(120, w - 220), 40)
			Kit.place(callsignSave, w - 180, 58, 160, 40)
		end
		y += (if narrowCallsign then 160 else 110) + 10

		-- Theme
		Kit.place(themeCard, 0, y, w, 110)
		themeTitle.Size = UDim2.fromOffset(w - 110, 24)
		themeDetail.Size = UDim2.fromOffset(w - 40, 28)
		for index, key in ipairs(ThemePresets.order) do
			Kit.place(themeSwatches[key].button, 20 + (index - 1) * 44, 58, 32, 32)
		end
		y += 110 + 10

		-- Guide
		local compactGuide = w < 540
		Kit.place(guideCard, 0, y, w, if compactGuide then 150 else 110)
		guideTitle.Size = UDim2.fromOffset(w - 90, 24)
		guideDetail.Size = UDim2.fromOffset(w - 40, 28)
		Kit.place(guideButton, 20, if compactGuide then 96 else 58, math.min(200, w - 40), 40)

		return y + (if compactGuide then 160 else 120)
	end)
end

return InterfacePageSettings
