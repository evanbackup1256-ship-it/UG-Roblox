local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageOverview = {}

function InterfacePageOverview.build(Shared: InterfaceShared.Shared)
	local Kit, C, Config = Shared.Kit, Shared.C, Shared.Config
	local positionText, liven = Shared.positionText, Shared.liven
	local bind, layoutPage = Shared.bind, Shared.layoutPage
	local bumpPeak, fmt = Shared.bumpPeak, Shared.fmt

	local home = Shared.pages.overview

	local hero = Kit.card(home, "Operations", 294, C.paper)
	positionText(hero, "Eyebrow", "ACTIVE SHIFT", 24, 22, 280, 22, 10, C.ink, true).Font = Enum.Font.RobotoMono

	local heroTitle = positionText(hero, "Title", "Keep the fleet\ninside limits.", 24, 58, 350, 91, 34, C.ink, true)
	heroTitle.TextWrapped = true
	heroTitle.TextTruncate = Enum.TextTruncate.None

	local heroCopy = positionText(hero, "Copy", "Run the queue, add hardware, and respond before the energy reserve bottoms out.", 24, 157, 340, 50, 14, C.ink)
	heroCopy.TextWrapped = true
	heroCopy.TextTruncate = Enum.TextTruncate.None

	local job = liven(Kit.button(hero, "RunJob", "Clear next job", function()
		Shared.fn.act("job")
	end, true))

	local sceneCard = Kit.card(home, "FleetPreview", 294)
	local stage = Kit.create("Frame", sceneCard, {
		Name = "Stage",
		Position = UDim2.fromOffset(0, 32),
		Size = UDim2.new(1, 0, 1, -58),
		BackgroundTransparency = 1,
	})
	Shared.director:Add(stage, 2, C.accent)

	positionText(sceneCard, "Label", "RACK CAMERA", 20, 12, 240, 22, 10, C.muted, true).Font = Enum.Font.RobotoMono

	local sceneHint = Kit.text(sceneCard, "Hint", "Drag to explore", 11, C.muted)
	sceneHint.Position = UDim2.new(0, 20, 1, -30)

	local metrics = {}
	for index, definition in ipairs({
		{ "BALANCE", "Available compute" },
		{ "THROUGHPUT", "Compute per second" },
		{ "INSTALLED", "Hardware units" },
		}) do
		local card = Kit.card(home, "Metric" .. index, 116)
		positionText(card, "Label", definition[1], 20, 14, 220, 20, 10, C.muted, true)

		local value = positionText(card, "Value", "—", 20, 39, 220, 36, 27, if index == 2 then C.accent else C.text, true)
		value.Font = Enum.Font.RobotoMono

		local caption = positionText(card, "Caption", definition[2], 20, 82, 220, 18, 11, C.muted)

		metrics[index] = { card = card, value = value, caption = caption }
	end

	local commandStrip = Kit.card(home, "CommandStatus", 96)
	local commandValues = {}
	for index, definition in ipairs({
		{ "LEVEL", C.accent },
		{ "DATA", C.accent2 },
		{ "ENERGY", C.warning },
		{ "REPUTATION", C.text },
		}) do
		local label = positionText(commandStrip, "Label" .. index, definition[1], 0, 15, 160, 18, 9, C.muted, true)
		local value = positionText(commandStrip, "Value" .. index, "—", 0, 39, 160, 32, 20, definition[2], true)
		label.Font = Enum.Font.RobotoMono
		value.Font = Enum.Font.RobotoMono
		commandValues[index] = { label = label, value = value }
	end

	local mission = Kit.card(home, "NextOperation", 184)
	Kit.place(Kit.icon(mission, "Icon", "operations", C.accent), 22, 22, 24, 24)
	positionText(mission, "Label", "NEXT DISPATCH", 58, 22, 240, 22, 10, C.muted, true)

	local missionTitle = positionText(mission, "Title", "Connecting…", 22, 58, 460, 28, 20, C.text, true)
	local missionDetail = positionText(mission, "Detail", "", 22, 92, 460, 36, 12, C.muted)
	missionDetail.TextWrapped = true

	local missionButton = liven(Kit.button(mission, "OpenOperations", "Open dispatch", function()
		Shared.fn.switchPage("operations")
	end))

	local boost = Kit.card(home, "Overclock", 184)
	Kit.place(Kit.icon(boost, "Icon", "operations", C.accent), 22, 22, 24, 24)
	positionText(boost, "Label", "MANUAL OVERRIDE", 58, 22, 230, 22, 10, C.muted, true)

	local boostTitle = positionText(boost, "Title", "Redline the fleet", 22, 58, 450, 28, 20, C.text, true)
	local boostDetail = positionText(boost, "Detail", "Double throughput, then wait for the thermal lockout.", 22, 92, 450, 32, 12, C.muted)
	boostDetail.TextWrapped = true

	local boostButton = liven(Kit.button(boost, "Activate", "Activate ×2", function()
		Shared.fn.act("boost")
	end, true))

	bind("overview", function(s)
		local research = s.research or {}

		Kit.setValue(metrics[1].value, fmt(s.compute), bumpPeak(1.05))
		Kit.setValue(metrics[2].value, fmt(s.rate) .. "/s", bumpPeak(1.055))
		Kit.setValue(metrics[3].value, fmt(s.units), bumpPeak(1.05))

		Kit.setValue(commandValues[1].value, tostring(s.level or 1), bumpPeak(1.06))
		Kit.setValue(commandValues[2].value, fmt(s.data), bumpPeak(1.045))
		Kit.setValue(commandValues[3].value, string.format("%d / %d", math.floor(s.energy or 0), math.floor(s.energyCapacity or 100)), bumpPeak(1.045))
		Kit.setValue(commandValues[4].value, fmt(s.reputation), bumpPeak(1.045))

		job.Text = "Clear next job   +" .. fmt(Config.job(s))

		local nextOperation = Config.Operations[math.clamp(s.level or 1, 1, #Config.Operations)]
		missionTitle.Text = nextOperation.name
		missionDetail.Text = nextOperation.subtitle

		local now = workspace:GetServerTimeNow()
		local active = math.max(0, math.ceil((s.boostUntil or 0) - now))
		local cooldown = math.max(0, math.ceil((s.boostReady or 0) - now))

		Kit.enable(
			boostButton,
			cooldown == 0 and (s.units or 0) > 0,
			if active > 0 then active .. "s active"
				elseif cooldown > 0 then cooldown .. "s recharge"
				else "Activate ×2",
			true
		)

		boostDetail.Text = string.format(
			"Double production for %d seconds.",
			30 + (research.overclock or 0) * 5 + (research.redundancy or 0) * 3
		)
	end)

	layoutPage("overview", function(w)
		local narrow = w < 720
		local first = if narrow then w else math.floor((w - 16) * 0.53)
		local tiny = narrow and w < 230

		Kit.place(hero, 0, 137, first, 294)
		Kit.place(job, 24, 226, math.min(230, first - 48), 44)

		heroTitle.Size = UDim2.fromOffset(math.max(1, first - 48), if tiny then 112 else 91)
		heroTitle.TextSize = if tiny then 27 else 36
		heroCopy.Size = UDim2.fromOffset(first - 48, 50)

		sceneCard.Visible = not narrow
		Kit.place(sceneCard, first + 16, 137, w - first - 16, 294)

		local y = 449
		local stack = w < 480
		local mw = if stack then w else (w - 24) / 3

		for i, item in ipairs(metrics) do
			Kit.place(
				item.card,
				if stack then 0 else (i - 1) * (mw + 12),
				y + (if stack then (i - 1) * 106 else 0),
				mw,
				if stack then 94 else 116
			)
			item.value.Size = UDim2.fromOffset(mw - 40, 36)
			item.caption.Visible = not stack
		end

		y += if stack then 326 else 134

		local statusColumns = if w < 520 then 2 else 4
		local statusWidth = w / statusColumns

		Kit.place(commandStrip, 0, y, w, if statusColumns == 2 then 140 else 96)

		for index, item in ipairs(commandValues) do
			local row = (index - 1) // statusColumns
			local column = (index - 1) % statusColumns
			item.label.Position = UDim2.fromOffset(column * statusWidth + 20, 15 + row * 44)
			item.value.Position = UDim2.fromOffset(column * statusWidth + 20, 35 + row * 44)
			item.label.Size = UDim2.fromOffset(statusWidth - 28, 18)
			item.value.Size = UDim2.fromOffset(statusWidth - 28, 30)
		end

		y += if statusColumns == 2 then 156 else 112

		local cw = if narrow then w else (w - 16) / 2
		Kit.place(mission, 0, y, cw, 198)
		Kit.place(boost, if narrow then 0 else cw + 16, y + (if narrow then 214 else 0), cw, 198)

		local textWidth = math.max(1, cw - 44)
		for _, text in { missionTitle, missionDetail, boostTitle, boostDetail } do
			text.Size = UDim2.fromOffset(textWidth, text.Size.Y.Offset)
		end
		boostTitle.TextSize = if cw < 220 then 17 else 20

		Kit.place(missionButton, 22, 138, cw - 44, 44)
		Kit.place(boostButton, 22, 138, cw - 44, 44)

		return y + (if narrow then 412 else 198)
	end)
end

return InterfacePageOverview
