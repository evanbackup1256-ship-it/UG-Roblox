local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageSettings = {}

function InterfacePageSettings.build(Shared: InterfaceShared.Shared)
	local Kit, C = Shared.Kit, Shared.C
	local positionText, liven = Shared.positionText, Shared.liven
	local layoutPage = Shared.layoutPage
	local own, connect, cancel, defer = Shared.own, Shared.connect, Shared.cancel, Shared.defer
	local trace = Shared.trace
	local preferences = Shared.preferences
	local pages = Shared.pages
	-- Same table as Shared.fn.settingRefresh (not a copy): both this file's
	-- own startup sequence/apply() and this module's table.insert calls
	-- append to one shared list.
	local settingRefresh = Shared.fn.settingRefresh

	local settingRows = {}
	local flushThread

	local function flushPreferences()
		if flushThread then
			cancel(flushThread)
			flushThread = nil
			pcall(Shared.Preferences.FireServer, Shared.Preferences, preferences)
		end
	end

	own(flushPreferences)

	local function changePreference(key, value)
		if preferences[key] == value then
			return
		end

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
		{ "music", "Background music", "Keep the soundtrack playing." },
		{ "sfx", "Interface sounds", "Feedback for actions and rewards." },
		{ "hover", "Hover sounds", "A quiet cue when you point at a control." },
		{ "masterVolume", "Master volume", "The overall mix.", true },
		{ "sfxVolume", "Effects volume", "Clicks, purchases, and reward cues.", true },
		{ "musicVolume", "Music volume", "Keep it in the background.", true },
		{ "motion", "Interface motion", "Smooth transitions and button feedback." },
		{ "notifications", "Reward notifications", "Show completion and purchase messages." },
		{ "previews", "3D previews", "Render hardware and fleet packages." },
		{ "autoOrbit", "Automatic orbit", "Slowly rotate visible 3D previews." },
		{ "orbitSpeed", "Orbit speed", "Set the pace of automatic rotation.", true },
		{ "particles", "Ambient motion", "A subtle light moving through the preview stage." },
	}

	local dragging

	for i, definition in ipairs(settingDefinitions) do
		local key = definition[1]
		local card = Kit.card(pages.settings, "Setting_" .. key, 96)

		local title = positionText(card, "Title", definition[2], 20, 15, 500, 28, 16, C.text, true)
		title.TextWrapped = true
		title.TextTruncate = Enum.TextTruncate.None

		local detail = positionText(card, "Detail", definition[3], 20, 48, 500, 30, 12, C.muted)
		detail.TextWrapped = true

		local control

		if definition[4] then
			control = Kit.create("TextButton", card, {
				Name = "Slider",
				Text = "",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(210, 44),
				AutoButtonColor = false,
			})

			local trackRoot, fill = Kit.progress(control, "Track")
			trackRoot.Position = UDim2.new(0, 0, 0.5, -2)
			trackRoot.Size = UDim2.new(1, -46, 0, 4)

			local thumb = Kit.create("Frame", trackRoot, {
				Name = "Thumb",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(18, 18),
				BackgroundColor3 = C.text,
				BorderSizePixel = 0,
			})
			Kit.corner(thumb, 9)

			local value = Kit.text(control, "Value", "", 11, C.accent, true)
			value.Position = UDim2.new(1, -38, 0, 0)
			value.Size = UDim2.fromOffset(38, 44)
			value.TextXAlignment = Enum.TextXAlignment.Right

			local function update(x)
				local span = math.max(1, trackRoot.AbsoluteSize.X)
				local ratio = math.clamp((x - trackRoot.AbsolutePosition.X) / span, 0, 1)
				changePreference(key, math.floor(ratio * 100 + 0.5) / 100)
			end

			connect(control.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					dragging = { input = input, update = update }
					pages.settings.ScrollingEnabled = false
					update(input.Position.X)
					return
				end

				-- Guard against any Left/Right/DPad input reaching this
				-- handler when this slider isn't actually the gamepad's
				-- current selection (TextButton.InputBegan only fires
				-- KeyCode events when it's the focused/selected object in
				-- normal cases, but this makes that explicit rather than
				-- relying on it implicitly).
				if GuiService.SelectedObject ~= control then
					return
				end

				local dir = 0
				if input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.DPadRight then
					dir = 1
				elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.DPadLeft then
					dir = -1
				end
				if dir ~= 0 then
					changePreference(key, math.clamp(math.floor((preferences[key] + dir * 0.05) * 100 + 0.5) / 100, 0, 1))
				end
			end)

			table.insert(settingRefresh, function()
				local amount = preferences[key]
				fill.Size = UDim2.fromScale(amount, 1)
				thumb.Position = UDim2.fromScale(amount, 0.5)
				value.Text = math.floor(amount * 100 + 0.5) .. "%"
			end)
		else
			local checkbox = Kit.checkbox(card, "Toggle", preferences[key] == true, function(value)
				changePreference(key, value)
			end)
			control = checkbox.instance

			local shown

			table.insert(settingRefresh, function()
				local on = preferences[key] == true
				if on == shown then
					return
				end
				shown = on
				checkbox:SetChecked(on)
			end)
		end

		settingRows[i] = {
			card = card,
			title = title,
			detail = detail,
			control = control,
			slider = definition[4],
		}
	end

	local stopDrag = function()
		if dragging then
			dragging = nil
			pages.settings.ScrollingEnabled = true
		end
	end
	Shared.fn.stopDrag = stopDrag

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

	local guideCard = Kit.card(pages.settings, "GuidedSetup", 112, C.paper)
	local guideTitle = positionText(guideCard, "Title", "Guided setup", 20, 16, 360, 28, 17, C.ink, true)
	local guideDetail = positionText(guideCard, "Detail", "Replay the interactive tour at any time.", 20, 50, 420, 28, 12, C.ink)
	guideDetail.TextWrapped = true

	local guideButton = liven(Kit.button(guideCard, "Replay", "Replay tutorial", function()
		Shared.fn.showTutorial(1)
	end, "primary"))

	layoutPage("settings", function(w)
		local narrow = w < 620
		local height = if narrow then 156 else 96
		local y = 137

		for _, item in ipairs(settingRows) do
			local copyWidth = w - (if narrow then 40 elseif item.slider then 300 else 130)

			Kit.place(item.card, 0, y, w, height)

			item.title.Size = UDim2.fromOffset(copyWidth, if narrow then 36 else 28)
			item.title.TextSize = if narrow then 15 else 16
			item.detail.Position = UDim2.fromOffset(20, if narrow then 54 else 48)
			item.detail.Size = UDim2.fromOffset(copyWidth, if narrow then 42 else 30)

			if item.slider then
				Kit.place(item.control, if narrow then 20 else w - 250, if narrow then 102 else 26, if narrow then w - 40 else 230, 44)
			else
				-- Kit.checkbox is a fixed 44x44 touch target (the minimum
				-- guideline size) with a smaller visible box centered
				-- inside it.
				Kit.place(item.control, if narrow then 20 else w - 64, if narrow then 102 else 26, 44, 44)
			end

			y += height + 12
		end

		local compactGuide = w < 540
		Kit.place(guideCard, 0, y, w, if compactGuide then 164 else 112)
		guideTitle.Size = UDim2.fromOffset(w - 40, 28)
		guideDetail.Size = UDim2.fromOffset(w - 40, 38)
		Kit.place(guideButton, 20, if compactGuide then 104 else 60, math.min(190, w - 40), 42)

		return y + (if compactGuide then 176 else 124)
	end)
end

return InterfacePageSettings
