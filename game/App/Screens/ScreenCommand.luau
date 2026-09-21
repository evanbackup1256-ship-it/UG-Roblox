--!strict
-- ScreenCommand: Primary Tactical Workstation & Processing Terminal
local AppContext = require(script.Parent.Parent.AppContext)

local ScreenCommand = {}

function ScreenCommand.build(ctx: AppContext.Context)
	local Elements = ctx.Elements
	local Buttons = ctx.Buttons
	local Inputs = ctx.Inputs
	local Feedback = ctx.Feedback
	local Springs = ctx.Springs
	local Theme = ctx.Theme
	local C = ctx.C
	local Config = ctx.Config
	local fmt = ctx.fmt

	local root = ctx.screens.overview

	-- =========================================================================
	-- 1. COMMAND CENTER (Workstation Console)
	-- =========================================================================
	local hero = Elements.card(root, "ProcessingCore", 200, C.card)

	-- Top identity rail
	local subHeader = Elements.text(hero, "SubHeader", "Workspace", 12, C.textMuted, true)
	Elements.place(subHeader, 24, 18, 300, 18)

	local statusDot = Elements.statusDot(hero, "Active", C.success, 8)
	statusDot.AnchorPoint = Vector2.new(1, 0)
	statusDot.Position = UDim2.new(1, -24, 0, 18)

	local divider = Elements.divider(hero, true)
	Elements.place(divider, 24, 42, 100, 1)

	-- Hero Title
	local heroTitle = Elements.text(hero, "Title", "Command Center", 24, C.textPrimary, true)
	heroTitle.Font = Theme.typography.fontDisplay
	Elements.place(heroTitle, 24, 50, 450, 26)

	local heroDesc = Elements.text(
		hero,
		"Desc",
		"Generate compute cycles manually to run your servers and scale your infrastructure.",
		14,
		C.textSecondary
	)
	heroDesc.TextWrapped = true
	Elements.place(heroDesc, 24, 82, 520, 36)

	-- Actuation Deck: Primary Process Button
	local jobButton: TextButton
	jobButton = Buttons.button(hero, "ProcessJob", "Generate Compute", function()
		if ctx.state then
			local gain = Config.job(ctx.state)
			Feedback.floatText(hero, string.format("+%s", fmt(gain)), C.compute, UDim2.fromScale(0.35, 0.45))
			Feedback.confetti(hero, C.compute)
			Feedback.ringPulse(hero, UDim2.fromScale(0.2, 0.7), C.compute)
			Feedback.pulse(jobButton, 0.95)
			heroTitle.TextColor3 = C.compute
			Springs.target(heroTitle, { TextColor3 = C.textPrimary }, "smooth")
		end
		ctx.act("job")
	end, "primary")

	-- Tactile Yield Readout Well
	local yieldWell = Elements.recessedWell(hero, "YieldWell", 44)
	local yieldTag = Elements.text(yieldWell, "Tag", "Yield", 11, C.textMuted, true)
	Elements.place(yieldTag, 14, 6, 120, 14)

	local yieldVal = Elements.text(yieldWell, "Val", "+1", 14, C.compute, true)
	yieldVal.Font = Theme.typography.fontBold
	Elements.place(yieldVal, 14, 22, 140, 18)

	-- Quick dispatch shortcut button
	local opsBtn = Buttons.button(hero, "QuickOps", "Missions", function()
		ctx.switchScreen("operations")
	end, "secondary")

	-- =========================================================================
	-- 2. TELEMETRY CLUSTER TILES
	-- =========================================================================
	local metricTiles = {
		{
			key = "energy",
			title = "Energy",
			subtitle = "Capacity",
			icon = "energy",
			color = C.energy,
			hasBar = true,
		},
		{
			key = "units",
			title = "Hardware",
			subtitle = "Active Units",
			icon = "infrastructure",
			color = C.accent,
		},
		{
			key = "data",
			title = "Data",
			subtitle = "Storage",
			icon = "data",
			color = C.data,
		},
		{
			key = "prestige",
			title = "Multiplier",
			subtitle = "Bonus",
			icon = "rewards",
			color = C.reputation,
		},
	}

	local tileCards = {}
	for i, def in ipairs(metricTiles) do
		local tile = Elements.card(root, "Metric_" .. def.key, 120, C.card)

		local icon = Elements.icon(tile, "Icon", def.icon, def.color)
		Elements.place(icon, 18, 16, 20, 20)

		local title = Elements.text(tile, "Title", def.title, 13, C.textSecondary, true)
		Elements.place(title, 46, 16, 180, 20)

		local val = Elements.text(tile, "Val", "0", 22, C.textPrimary, true)
		val.Font = Theme.typography.fontDisplay
		Elements.place(val, 18, 44, 180, 28)

		local subLabel = Elements.text(tile, "Sub", def.subtitle, 12, def.color, true)
		Elements.place(subLabel, 18, 76, 180, 18)

		local miniBar = nil
		if def.hasBar then
			miniBar = Inputs.progressBar(tile, "MiniMeter", 4, def.color)
			Elements.place(miniBar.instance, 18, 98, 160, 4)
		end

		tileCards[i] = {
			card = tile,
			val = val,
			subLabel = subLabel,
			miniBar = miniBar,
			def = def,
			title = title,
			bump = Feedback.bump(val),
		}
	end

	-- =========================================================================
	-- 3. STATE BINDING
	-- =========================================================================
	ctx.bind("overview", function(s)
		local gain = Config.job(s)
		yieldVal.Text = string.format("+%s", fmt(gain))

		for _, tile in ipairs(tileCards) do
			local k = tile.def.key
			local formatted = "0"
			if k == "energy" then
				local cap = Config.energyCapacity(s)
				local cur = math.floor(s.energy or 0)
				formatted = string.format("%d / %d", cur, cap)
				if tile.miniBar then
					tile.miniBar.setProgress(math.clamp(cur / math.max(1, cap), 0, 1))
				end
			elseif k == "units" then
				formatted = fmt(Config.units(s))
			elseif k == "data" then
				formatted = fmt(s.data or 0)
			elseif k == "prestige" then
				local bonus = Config.prestigeBonus(s)
				formatted = string.format("x%.2f", 1 + bonus)
				tile.subLabel.Text = fmt(s.prestigeTokens or 0) .. " Tokens"
			end

			if formatted ~= tile.val.Text then
				tile.val.Text = formatted
				tile.bump()
			end
		end
	end)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	ctx.layoutScreen("overview", function(w)
		local narrow = w < 680
		local heroH = if narrow then 250 else 190

		Elements.place(hero, 0, 0, w, heroH)
		Elements.place(divider, 24, 42, w - 48, 1)

		if narrow then
			heroTitle.Size = UDim2.fromOffset(w - 48, 26)
			heroDesc.Size = UDim2.fromOffset(w - 48, 36)
			Elements.place(jobButton, 24, 126, w - 48, 44)
			local halfW = math.floor((w - 58) / 2)
			Elements.place(yieldWell, 24, 180, halfW, 44)
			yieldTag.Size = UDim2.fromOffset(math.max(80, halfW - 24), 14)
			yieldVal.Size = UDim2.fromOffset(math.max(80, halfW - 24), 18)
			Elements.place(opsBtn, 24 + halfW + 10, 180, halfW, 44)
		else
			heroTitle.Size = UDim2.fromOffset(w - 48, 26)
			heroDesc.Size = UDim2.fromOffset(w - 48, 30)
			Elements.place(jobButton, 24, 124, 190, 46)
			Elements.place(yieldWell, 224, 124, 160, 46)
			yieldTag.Size = UDim2.fromOffset(130, 14)
			yieldVal.Size = UDim2.fromOffset(140, 18)
			Elements.place(opsBtn, 394, 124, 120, 46)
		end

		local tileStartY = heroH + 16
		local cols = if w >= 880 then 4 elseif w >= 520 then 2 else 1
		local tileW = math.floor((w - (cols - 1) * 14) / cols)
		local tileH = 120

		for idx, item in ipairs(tileCards) do
			local localIdx = idx - 1
			local col = localIdx % cols
			local row = localIdx // cols
			local tx = col * (tileW + 14)
			local ty = tileStartY + row * (tileH + 14)
			Elements.place(item.card, tx, ty, tileW, tileH)
			item.val.Size = UDim2.fromOffset(tileW - 36, 28)
			item.subLabel.Size = UDim2.fromOffset(tileW - 36, 18)
			if item.miniBar then
				Elements.place(item.miniBar.instance, 18, 98, tileW - 36, 4)
			end
		end

		local totalRows = math.ceil(#tileCards / cols)
		return tileStartY + totalRows * (tileH + 14) + 32
	end)
end

return ScreenCommand
