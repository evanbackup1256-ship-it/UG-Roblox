--!strict
-- ScreenPreferences: Configuration console for acoustics, kinematics, display accents, and identity
local AppContext = require(script.Parent.Parent.AppContext)

local ScreenPreferences = {}

function ScreenPreferences.build(ctx: AppContext.Context)
	local Theme = ctx.Theme
	local Springs = ctx.Springs
	local Elements = ctx.Elements
	local Buttons = ctx.Buttons
	local Inputs = ctx.Inputs
	local Feedback = ctx.Feedback
	local Acoustics = ctx.Acoustics
	local C = ctx.C

	local root = ctx.screens.settings
	local prefs = ctx.preferences

	-- =========================================================================
	-- DEBOUNCED PREFERENCE SYNC
	-- =========================================================================
	local flushThread: thread? = nil
	local function flushPreferences()
		flushThread = nil
		-- Send preferences update to server via dedicated RemoteEvent
		if ctx.savePreferences then
			ctx.savePreferences(prefs)
		end
	end
	ctx.own(flushPreferences)

	local function changePref(key: string, value: any)
		if prefs[key] == value then return end

		prefs[key] = value

		-- React to acoustic / kinematic setting changes immediately
		if key == "masterVolume" then
			Acoustics.setMasterVolume(value)
		elseif key == "sfxVolume" then
			Acoustics.setSfxVolume(value)
		elseif key == "musicVolume" then
			Acoustics.setMusicVolume(value)
		elseif key == "motion" then
			Springs.setMotionEnabled(value == true)
		elseif key == "accentTheme" then
			Theme.applyPreset(value)
		end

		for _, cb in ipairs(ctx.settingRefresh) do
			cb()
		end

		if flushThread then
			pcall(task.cancel, flushThread)
			flushThread = nil
		end
		flushThread = ctx.defer(0.3, flushPreferences)
	end

	-- =========================================================================
	-- 1. HEADER HERO
	-- =========================================================================
	local header = Elements.card(root, "PreferencesHeader", 90, C.card)


	local headerBadge = Elements.badge(header, "LOCAL WORKSTATION", "azure", true)
	Elements.place(headerBadge, 24, 18, 150, 22)

	local headerTitle = Elements.text(header, "Title", "System Preferences", 20, C.textPrimary, true)
	Elements.place(headerTitle, 24, 46, 400, 26)

	-- =========================================================================
	-- 2. SETTINGS ROWS DEFINITIONS
	-- =========================================================================
	type SettingDef = {
		key: string,
		section: string,
		title: string,
		detail: string,
		isSlider: boolean,
		min: number?,
		max: number?,
		default: any,
	}

	local definitions: { SettingDef } = {
		-- Audio
		{ key = "masterVolume", section = "ACOUSTICS", title = "Master Volume", detail = "Master balance across interface and environment.", isSlider = true, default = 0.8 },
		{ key = "sfxVolume", section = "ACOUSTICS", title = "Interface Effects", detail = "Physical tactile clicks, rewards, and warning cues.", isSlider = true, default = 0.9 },
		{ key = "musicVolume", section = "ACOUSTICS", title = "Soundtrack Volume", detail = "Ambient background synthesizer mix.", isSlider = true, default = 0.5 },
		{ key = "sfx", section = "ACOUSTICS", title = "Enable Sound Effects", detail = "Auditory feedback for button presses and actions.", isSlider = false, default = true },
		{ key = "music", section = "ACOUSTICS", title = "Enable Ambient Music", detail = "Keep background soundtrack active during shifts.", isSlider = false, default = true },
		{ key = "hover", section = "ACOUSTICS", title = "Hover Cues", detail = "Subtle acoustic clicks when pointing at controls.", isSlider = false, default = true },

		-- Motion & Visuals
		{ key = "motion", section = "KINEMATICS & VISUALS", title = "Physical Spring Motion", detail = "Real-time mechanical spring animations and compressions.", isSlider = false, default = true },
		{ key = "notifications", section = "KINEMATICS & VISUALS", title = "Alert Toasts", detail = "Non-intrusive notification capsules in top corner.", isSlider = false, default = true },
		{ key = "previews", section = "KINEMATICS & VISUALS", title = "3D Viewport Previews", detail = "Real-time rendered hardware modules and fleet stages.", isSlider = false, default = true },
		{ key = "autoOrbit", section = "KINEMATICS & VISUALS", title = "Automatic Orbit", detail = "Slowly revolve 3D staging preview models.", isSlider = false, default = true },
		{ key = "orbitSpeed", section = "KINEMATICS & VISUALS", title = "Orbit Angular Velocity", detail = "Speed of the automated camera preview rotation.", isSlider = true, default = 0.5 },
		{ key = "particles", section = "KINEMATICS & VISUALS", title = "Particle Effects", detail = "Floating compute sparks and celebratory bursts.", isSlider = false, default = true },
	}

	type RowItem = {
		def: SettingDef,
		card: Frame,
		title: TextLabel,
		detail: TextLabel,
		control: any,
	}

	local rows: { RowItem } = {}

	for i, def in ipairs(definitions) do
		local card = Elements.interactiveCard(root, "Pref_" .. def.key, 84, C.card)

		local title = Elements.text(card, "Title", def.title, 15, C.textPrimary, true)
		Elements.place(title, 20, 16, 400, 22)

		local detail = Elements.text(card, "Detail", def.detail, 12, C.textSecondary)
		detail.TextWrapped = true
		Elements.place(detail, 20, 42, 420, 28)

		local control: any
		if def.isSlider then
			local initial = prefs[def.key]
			if initial == nil then initial = def.default end
			control = Inputs.slider(card, "Slider", initial, function(val)
				changePref(def.key, val)
			end)
		else
			local initial = prefs[def.key]
			if initial == nil then initial = def.default end
			control = Inputs.toggle(card, "Toggle", initial == true, function(val)
				changePref(def.key, val)
			end)
		end

		rows[i] = {
			def = def,
			card = card,
			title = title,
			detail = detail,
			control = control,
		}
	end

	-- Sync setting controls when external preferences refresh occurs
	table.insert(ctx.settingRefresh, function()
		for _, row in ipairs(rows) do
			local val = prefs[row.def.key]
			if val == nil then val = row.def.default end
			if row.def.isSlider then
				row.control.set(val, false)
			else
				row.control.set(val == true, false)
			end
		end
	end)

	-- =========================================================================
	-- 3. ACCENT THEME PALETTE PICKER
	-- =========================================================================
	local themeCard = Elements.card(root, "ThemePalette", 125, C.card)


	local themeBadge = Elements.badge(themeCard, "PALETTE ACCENT", "accent", true)
	Elements.place(themeBadge, 24, 18, 130, 22)

	local themeTitle = Elements.text(themeCard, "Title", "Accent Color System", 18, C.textPrimary, true)
	Elements.place(themeTitle, 24, 46, 300, 24)

	local themeDetail = Elements.text(
		themeCard,
		"Detail",
		"Select the physical color accent used across telemetry, highlights, and buttons.",
		12,
		C.textSecondary
	)
	Elements.place(themeDetail, 24, 72, 500, 20)

	local themeSwatches: { [string]: { btn: TextButton, ring: UIStroke } } = {}
	local order = Theme.presetOrder or { "azure", "mint", "amber", "purple", "rose" }

	for _, key in ipairs(order) do
		local p = (Theme.presets and Theme.presets[key]) or { accent = C.accent }
		local swatchBtn = Elements.create("TextButton", themeCard, {
			Name = "Swatch_" .. key,
			BackgroundColor3 = p.accent,
			AutoButtonColor = false,
			Text = "",
			Size = UDim2.fromOffset(36, 36),
		})
		Elements.corner(swatchBtn, 18)

		local ring = Elements.stroke(swatchBtn, C.textPrimary, 2, 1)

		swatchBtn.Activated:Connect(function()
			Acoustics.play("tab", 0.05)
			changePref("accentTheme", key)
			Feedback.floatText(themeCard, p.name or key, p.accent, UDim2.fromScale(0.5, 0.4))
		end)

		swatchBtn.MouseEnter:Connect(function()
			Springs.target(swatchBtn, { Size = UDim2.fromOffset(40, 40) }, "snappy")
		end)
		swatchBtn.MouseLeave:Connect(function()
			Springs.target(swatchBtn, { Size = UDim2.fromOffset(36, 36) }, "snappy")
		end)

		themeSwatches[key] = { btn = swatchBtn, ring = ring }
	end

	local function refreshSwatches()
		local active = prefs.accentTheme or "azure"
		for key, entry in pairs(themeSwatches) do
			local isActive = (key == active)
			Springs.target(entry.ring, {
				Transparency = if isActive then 0 else 1,
			}, "smooth")
		end
	end
	table.insert(ctx.settingRefresh, refreshSwatches)
	refreshSwatches()

	-- =========================================================================
	-- 4. CALL SIGN & OPERATOR IDENTITY
	-- =========================================================================
	local callsignCard = Elements.card(root, "OperatorCallsign", 130, C.card)

	local csBadge = Elements.badge(callsignCard, "FLEET IDENTITY", "azure", true)
	Elements.place(csBadge, 24, 18, 120, 22)

	local csTitle = Elements.text(callsignCard, "Title", "Operator Call Sign", 18, C.textPrimary, true)
	Elements.place(csTitle, 24, 46, 300, 24)

	local csDetail = Elements.text(
		callsignCard,
		"Detail",
		"Shown on public leaderboards and fleet records in place of your account username.",
		12,
		C.textSecondary
	)
	Elements.place(csDetail, 24, 72, 500, 20)

	local csInput = Inputs.searchInput(callsignCard, "CallsignInput", "Enter Callsign…")
	local csSaveBtn = Buttons.button(callsignCard, "SaveCallsign", "Save Callsign", function()
		local text = csInput.getText()
		local clean = string.gsub(text, "[^%w%s%-%_]", "")
		if #clean > 20 then clean = string.sub(clean, 1, 20) end
		ctx.act("callsign", clean)
		Feedback.floatText(callsignCard, "Callsign saved", C.mint, UDim2.fromScale(0.5, 0.4))
	end, "primary")

	local callsignSeeded = false
	ctx.bind("settings", function(s)
		if not callsignSeeded and s.callsign then
			callsignSeeded = true
			csInput.setText(s.callsign)
		end
	end)

	-- =========================================================================
	-- 5. GUIDED ONBOARDING REPLAY
	-- =========================================================================
	local tourCard = Elements.card(root, "GuidedTour", 110, C.card)

	local tourBadge = Elements.badge(tourCard, "DOCUMENTATION", "amber", true)
	Elements.place(tourBadge, 24, 18, 140, 22)

	local tourTitle = Elements.text(tourCard, "Title", "Replay System Orientation", 18, C.textPrimary, true)
	Elements.place(tourTitle, 24, 46, 350, 24)

	local tourDetail = Elements.text(
		tourCard,
		"Detail",
		"Rerun the interactive console walkthrough highlighting core telemetry and workflows.",
		12,
		C.textSecondary
	)
	Elements.place(tourDetail, 24, 72, 450, 20)

	local tourBtn = Buttons.button(tourCard, "ReplayTour", "Launch Tour", function()
		ctx.showTour(1)
	end, "secondary")

	-- =========================================================================
	-- 6. RESPONSIVE LAYOUT
	-- =========================================================================
	ctx.layoutScreen("settings", function(w)
		local y = 20
		local isCompact = w < 640

		-- 1. Header
		Elements.place(header, 0, y, w, 90)
		Elements.place(headerTitle, 24, 46, w - 48, 26)
		y += 90 + 16

		-- 2. Setting Rows
		local rowHeight = if isCompact then 120 else 76
		for _, row in ipairs(rows) do
			Elements.place(row.card, 0, y, w, rowHeight)

			if isCompact then
				Elements.place(row.title, 20, 14, w - 40, 20)
				Elements.place(row.detail, 20, 36, w - 40, 24)

				if row.def.isSlider then
					Elements.place(row.control.instance, 20, 68, w - 40, 38)
				else
					Elements.place(row.control.instance, 20, 68, 48, 26)
				end
			else
				local copyWidth = w - 300
				Elements.place(row.title, 24, 14, copyWidth, 22)
				Elements.place(row.detail, 24, 38, copyWidth, 24)

				if row.def.isSlider then
					Elements.place(row.control.instance, w - 264, 18, 240, 40)
				else
					Elements.place(row.control.instance, w - 76, 25, 48, 26)
				end
			end

			y += rowHeight + 10
		end

		y += 10

		-- 3. Theme Swatches
		Elements.place(themeCard, 0, y, w, 130)
		Elements.place(themeTitle, 24, 46, w - 48, 24)
		Elements.place(themeDetail, 24, 72, w - 48, 20)

		local swatchStartX = 24
		for idx, key in ipairs(order) do
			local entry = themeSwatches[key]
			if entry then
				Elements.place(entry.btn, swatchStartX + (idx - 1) * 48, 92, 36, 36)
			end
		end
		y += 130 + 16

		-- 4. Callsign
		local csHeight = if isCompact then 180 else 130
		Elements.place(callsignCard, 0, y, w, csHeight)
		Elements.place(csTitle, 24, 46, w - 48, 24)
		Elements.place(csDetail, 24, 72, w - 48, 20)

		if isCompact then
			Elements.place(csInput.instance, 20, 96, w - 40, 38)
			Elements.place(csSaveBtn, 20, 138, w - 40, 36)
		else
			Elements.place(csInput.instance, 24, 96, w - 210, 38)
			Elements.place(csSaveBtn, w - 170, 96, 146, 38)
		end
		y += csHeight + 16

		-- 5. Guided Tour
		local tourHeight = if isCompact then 160 else 110
		Elements.place(tourCard, 0, y, w, tourHeight)
		Elements.place(tourTitle, 24, 46, w - 48, 24)
		Elements.place(tourDetail, 24, 72, w - 48, 20)

		if isCompact then
			Elements.place(tourBtn, 20, 106, w - 40, 38)
		else
			Elements.place(tourBtn, w - 180, 48, 156, 38)
		end
		y += tourHeight + 24

		return y
	end)
end

return ScreenPreferences

