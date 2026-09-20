--!strict
local Workspace = game:GetService("Workspace")

local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageOverview = {}

function InterfacePageOverview.build(Shared: InterfaceShared.Shared)
	local Kit = Shared.Kit
	local C = Shared.C
	local Config = Shared.Config
	local positionText = Shared.positionText
	local liven = Shared.liven
	local bind = Shared.bind
	local layoutPage = Shared.layoutPage
	local bumpPeak = Shared.bumpPeak
	local fmt = Shared.fmt
	local preferences = Shared.preferences

	local home = Shared.pages.overview

	-- =========================================================================
	-- 1. FLEET COMMAND HERO & CLICKER WORKSTATION
	-- =========================================================================
	local hero = Kit.interactiveCard(home, "OperationsHero", 280, C.panel)

	local heroBadge = Kit.badge(hero, "System Operations", "accent", true)
	Kit.place(heroBadge, 24, 22, 140, 20)

	local heroTitle = positionText(hero, "Title", "Fleet Operating\nNominal.", 24, 54, 380, 84, 28, C.text, true)
	heroTitle.TextWrapped = true
	heroTitle.TextTruncate = Enum.TextTruncate.None

	local heroCopy = positionText(
		hero,
		"Copy",
		"Process manual compute queue, expand server racks, and monitor thermal energy reserves.",
		24,
		144,
		360,
		44,
		13,
		C.textSub
	)
	heroCopy.TextWrapped = true
	heroCopy.TextTruncate = Enum.TextTruncate.None

	local jobButton = liven(Kit.button(hero, "RunJob", "Process Queue", function()
		if Shared.state then
			local gain = Config.job(Shared.state)
			Kit.floatText(hero, "+" .. fmt(gain) .. " COMPUTE", C.compute, Vector2.new(0.5, 0.4))
			Kit.bump(heroTitle, 1.03)
		end
		Shared.fn.act("job")
	end, "primary"))

	-- =========================================================================
	-- 2. 3D RACK VIEWPORT PREVIEW STAGE
	-- =========================================================================
	local sceneCard = Kit.card(home, "FleetPreview", 280, C.panel)

	local stage = Kit.create("Frame", sceneCard, {
		Name = "Stage",
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(1, 0, 1, -64),
		BackgroundTransparency = 1,
	})
	Shared.director:Add(stage, 2, C.accent)

	local stageLabel = positionText(sceneCard, "Label", "Live Hardware Camera", 20, 14, 200, 20, 11, C.textSub, true)

	local liveBadge = Kit.badge(sceneCard, "Online", "compute", true)
	Kit.place(liveBadge, 170, 12, 60, 20)

	local sceneHint = Kit.text(sceneCard, "Hint", "Drag to orbit camera", 11, C.muted, false)
	sceneHint.Position = UDim2.new(0, 20, 1, -26)

	-- =========================================================================
	-- 3. CORE METRIC TILES
	-- =========================================================================
	local metricDefs = {
		{ label = "Compute Balance", caption = "Liquid currency available", color = C.compute },
		{ label = "Fleet Throughput", caption = "Automated compute per second", color = C.accent },
		{ label = "Hardware Units", caption = "Total racks & nodes online", color = C.text },
	}

	local metrics = {}
	for index, def in ipairs(metricDefs) do
		local card = Kit.interactiveCard(home, "MetricCard" .. index, 110, C.panel)
		local lbl = positionText(card, "Label", def.label, 20, 16, 240, 18, 11, C.textSub, true)

		local val = positionText(card, "Value", "—", 20, 36, 240, 34, 24, def.color, true)
		val.Font = Enum.Font.RobotoMono

		local cap = positionText(card, "Caption", def.caption, 20, 76, 240, 18, 11, C.muted)

		metrics[index] = { card = card, value = val, caption = cap, label = lbl }
	end

	-- =========================================================================
	-- 4. FLEET STATUS SUMMARY BAR
	-- =========================================================================
	local commandStrip = Kit.card(home, "CommandStatus", 88, C.panel)

	local telemetryDefs = {
		{ label = "Operator Level", color = C.accent },
		{ label = "Field Data", color = C.data },
		{ label = "Energy Reserve", color = C.energy },
		{ label = "Prestige Tokens", color = C.reputation },
	}

	local commandValues = {}
	for index, def in ipairs(telemetryDefs) do
		local label = positionText(commandStrip, "Label" .. index, def.label, 0, 14, 180, 18, 11, C.muted, true)

		local value = positionText(commandStrip, "Value" .. index, "—", 0, 36, 180, 30, 18, def.color, true)
		value.Font = Enum.Font.RobotoMono

		commandValues[index] = { label = label, value = value }
	end

	-- =========================================================================
	-- 5. QUICK DISPATCH & OVERCLOCK ACTION MODULES
	-- =========================================================================
	local mission = Kit.interactiveCard(home, "NextOperation", 175, C.panel)
	Kit.place(Kit.icon(mission, "Icon", "operations", C.accent), 22, 22, 22, 22)
	local missionEyebrow = positionText(mission, "Label", "Next Tactical Operation", 54, 22, 260, 20, 11, C.muted, true)

	local missionTitle = positionText(mission, "Title", "Connecting…", 22, 54, 460, 26, 18, C.text, true)
	local missionDetail = positionText(mission, "Detail", "", 22, 82, 460, 30, 12, C.textSub)
	missionDetail.TextWrapped = true

	local missionButton = liven(Kit.button(mission, "OpenOperations", "Open Dispatch", function()
		Shared.fn.switchPage("operations")
	end, "secondary"))

	local boost = Kit.interactiveCard(home, "Overclock", 175, C.panel)
	Kit.place(Kit.icon(boost, "Icon", "operations", C.energy), 22, 22, 22, 22)
	local boostEyebrow = positionText(boost, "Label", "Overclock Booster", 54, 22, 260, 20, 11, C.energy, true)

	local boostTitle = positionText(boost, "Title", "Engage Overclock", 22, 54, 460, 26, 18, C.text, true)
	local boostDetail = positionText(boost, "Detail", "Double throughput for a limited duration.", 22, 82, 460, 30, 12, C.textSub)
	boostDetail.TextWrapped = true

	local boostButton = liven(Kit.button(boost, "Activate", "Engage 2.0x", function()
		Shared.fn.act("boost")
	end, "primary"))

	-- =========================================================================
	-- 6. REAL-TIME DATA BINDING
	-- =========================================================================
	bind("overview", function(s)
		local research = s.research or {}

		Kit.tickValue(metrics[1].value, s.compute or 0, fmt, "smooth", bumpPeak(1.03))
		Kit.tickValue(metrics[2].value, s.rate or 0, function(value)
			return "+" .. fmt(value) .. "/s"
		end, "smooth", bumpPeak(1.03))
		Kit.tickValue(metrics[3].value, s.units or 0, fmt, "smooth", bumpPeak(1.03))

		Kit.setValue(commandValues[1].value, "Level " .. tostring(s.level or 1), bumpPeak(1.04))
		Kit.setValue(commandValues[2].value, fmt(s.data or 0) .. " MB", bumpPeak(1.03))
		Kit.setValue(
			commandValues[3].value,
			string.format("%d / %d", math.floor(s.energy or 0), math.floor(s.energyCapacity or 100)),
			bumpPeak(1.03)
		)
		Kit.setValue(commandValues[4].value, fmt(s.reputation or 0), bumpPeak(1.03))

		jobButton.Text = "Process Queue  +" .. fmt(Config.job(s))

		local nextOperation = Config.Operations[math.clamp(s.level or 1, 1, #Config.Operations)]
		if nextOperation then
			missionTitle.Text = nextOperation.name
			missionDetail.Text = nextOperation.subtitle
		end

		local now = Workspace:GetServerTimeNow()
		local active = math.max(0, math.ceil((s.boostUntil or 0) - now))
		local cooldown = math.max(0, math.ceil((s.boostReady or 0) - now))

		Kit.enable(
			boostButton,
			cooldown == 0 and (s.units or 0) > 0,
			if active > 0 then active .. "s Active"
				elseif cooldown > 0 then cooldown .. "s Cooling"
				else "Engage 2.0x Overclock",
			true
		)

		boostDetail.Text = string.format(
			"Double fleet throughput for %d seconds.",
			30 + (research.overclock or 0) * 5 + (research.redundancy or 0) * 3
		)
	end)

	-- =========================================================================
	-- 7. DYNAMIC RESPONSIVE LAYOUT ENGINE
	-- =========================================================================
	layoutPage("overview", function(w)
		local narrow = w < 740
		local first = if narrow then w else math.floor((w - 16) * 0.54)
		local tiny = narrow and w < 260

		-- Hero Placement
		Kit.place(hero, 0, 137, first, 280)
		Kit.place(jobButton, 24, 216, math.min(240, first - 48), 40)

		heroTitle.Size = UDim2.fromOffset(math.max(1, first - 48), if tiny then 90 else 84)
		heroTitle.TextSize = if tiny then 24 else 28
		heroCopy.Size = UDim2.fromOffset(first - 48, 44)

		-- 3D Stage Placement
		sceneCard.Visible = not narrow
		if not narrow then
			Kit.place(sceneCard, first + 16, 137, w - first - 16, 280)
		end

		-- Metrics Placement
		local y = 433
		local stack = w < 500
		local mw = if stack then w else (w - 24) / 3

		for i, item in ipairs(metrics) do
			Kit.place(
				item.card,
				if stack then 0 else (i - 1) * (mw + 12),
				y + (if stack then (i - 1) * 100 else 0),
				mw,
				if stack then 88 else 110
			)
			item.value.Size = UDim2.fromOffset(mw - 40, 34)
			item.caption.Visible = not stack
		end

		y += if stack then 312 else 126

		-- Telemetry Strip
		local statusColumns = if w < 560 then 2 else 4
		local statusWidth = w / statusColumns

		Kit.place(commandStrip, 0, y, w, if statusColumns == 2 then 136 else 88)

		for index, item in ipairs(commandValues) do
			local row = (index - 1) // statusColumns
			local column = (index - 1) % statusColumns
			item.label.Position = UDim2.fromOffset(column * statusWidth + 20, 14 + row * 44)
			item.value.Position = UDim2.fromOffset(column * statusWidth + 20, 36 + row * 44)
			item.label.Size = UDim2.fromOffset(statusWidth - 28, 18)
			item.value.Size = UDim2.fromOffset(statusWidth - 28, 28)
		end

		y += if statusColumns == 2 then 152 else 104

		-- Bottom Actions
		local cw = if narrow then w else (w - 16) / 2
		Kit.place(mission, 0, y, cw, 175)
		Kit.place(boost, if narrow then 0 else cw + 16, y + (if narrow then 191 else 0), cw, 175)

		local textWidth = math.max(1, cw - 44)
		for _, text in { missionTitle, missionDetail, boostTitle, boostDetail } do
			text.Size = UDim2.fromOffset(textWidth, text.Size.Y.Offset)
		end

		Kit.place(missionButton, 22, 122, cw - 44, 38)
		Kit.place(boostButton, 22, 122, cw - 44, 38)

		return y + (if narrow then 382 else 191)
	end)
end

return InterfacePageOverview
