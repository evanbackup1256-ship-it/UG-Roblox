local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageOperations = {}

function InterfacePageOperations.build(Shared: InterfaceShared.Shared)
	local Kit, C, Config = Shared.Kit, Shared.C, Shared.Config
	local positionText, liven = Shared.positionText, Shared.liven
	local bind, layoutPage = Shared.bind, Shared.layoutPage
	local fmt = Shared.fmt

	local operationSummary = Kit.card(Shared.pages.operations, "NetworkState", 150)
	positionText(operationSummary, "Eyebrow", "SHIFT TELEMETRY", 22, 18, 260, 20, 10, C.muted, true).Font = Enum.Font.RobotoMono

	local energyValue = positionText(operationSummary, "Energy", "100 / 100 ENERGY", 22, 44, 280, 30, 22, C.warning, true)
	energyValue.Font = Enum.Font.RobotoMono

	local energyBar, energyFill = Kit.progress(operationSummary, "EnergyReserve")
	Kit.progressShimmer(energyFill)
	local wasEnergyFull = false
	local operationTelemetry = positionText(operationSummary, "Telemetry", "", 22, 108, 700, 22, 12, C.muted)
	operationTelemetry.Font = Enum.Font.RobotoMono

	local rechargeButton = liven(Kit.button(operationSummary, "Recharge", "Emergency recharge", function()
		Shared.fn.act("recharge")
	end))

	local operationCards = {}
	for index, operation in ipairs(Config.Operations) do
		local card = Kit.card(Shared.pages.operations, "Operation_" .. operation.key, 242)

		local iconShell = Kit.create("Frame", card, {
			Name = "IconShell",
			BackgroundColor3 = C.raised,
			BorderSizePixel = 0,
		})
		Kit.corner(iconShell, 12)
		Kit.place(
			Kit.icon(iconShell, "Icon", operation.icon or "operations", if index % 3 == 0 then C.accent2 else C.accent),
			13, 13, 24, 24
		)

		local title = positionText(card, "Title", operation.name, 84, 18, 300, 28, 17, C.text, true)
		title.TextWrapped = true

		local detail = positionText(card, "Detail", operation.subtitle, 20, 68, 360, 42, 12, C.muted)
		detail.TextWrapped = true

		local chance = positionText(card, "Chance", "", 20, 119, 180, 22, 11, C.accent, true)
		local reward = positionText(card, "Reward", "", 20, 145, 360, 22, 12, C.text, true)
		chance.Font = Enum.Font.RobotoMono
		reward.Font = Enum.Font.RobotoMono
		reward.Text = string.format(
			"+%s COMPUTE   +%s DATA   +%s XP",
			fmt(operation.reward),
			fmt(operation.data),
			fmt(operation.xp)
		)

		local launch = liven(Kit.button(card, "Launch", "Connecting…", function()
			Shared.fn.act("operation", operation.key)
		end, true))

		operationCards[index] = {
			card = card,
			operation = operation,
			index = index,
			iconShell = iconShell,
			title = title,
			detail = detail,
			chance = chance,
			reward = reward,
			launch = launch,
		}
	end

	bind("operations", function(s)
		local level = s.level or 1
		local energy = s.energy or 0
		local capacity = math.max(1, s.energyCapacity or 100)
		local mastery = s.operationMastery or {}
		local sharedChance = Config.moduleEffect(s, "success") + math.min(0.08, (s.reputation or 0) / 25000)

		energyValue.Text = string.format("%d / %d ENERGY", math.floor(energy), math.floor(capacity))
		Kit.animate(energyFill, {
			Size = UDim2.fromScale(math.clamp(energy / capacity, 0, 1), 1),
		}, 0.24)

		operationTelemetry.Text = string.format(
			"LEVEL %d   ·   %s DATA   ·   %s REPUTATION   ·   ×%d STREAK   ·   %d CRITICAL   ·   %d FLAWLESS",
			level,
			fmt(s.data),
			fmt(s.reputation),
			s.operationCombo or 0,
			s.criticalSuccesses or 0,
			s.flawlessSuccesses or 0
		)

		local full = energy >= capacity - 1
		if full and not wasEnergyFull then
			Kit.progressFull(energyBar)
		end
		wasEnergyFull = full

		local rechargeCost = math.floor(120 * level ^ 1.35)
		Kit.enable(
			rechargeButton,
			not full and (s.compute or 0) >= rechargeCost,
			if full then "Reserve full" else "Recharge 40% · " .. fmt(rechargeCost),
			false
		)

		for _, item in ipairs(operationCards) do
			local operation = item.operation
			local unlocked = level >= operation.unlock
			local ranks = mastery[operation.key] or 0
			local chance = math.clamp(operation.chance + ranks * 0.005 + sharedChance, 0.15, 0.98)

			item.chance.Text = if unlocked
				then string.format("OP-%02d / %d%% / E%d / M%d", item.index, math.floor(chance * 100 + 0.5), operation.energy, ranks)
				else string.format("OP-%02d / LOCKED UNTIL L%d", item.index, operation.unlock)

			Kit.lock(item.card, not unlocked, item.launch)

			Kit.enable(
				item.launch,
				unlocked and energy >= operation.energy,
				if not unlocked then "Locked"
					elseif energy < operation.energy then "Energy recovering"
					else "Begin operation",
				true
			)
		end
	end)

	layoutPage("operations", function(w)
		local columns = if w >= 720 then 2 else 1
		local cw = (w - (columns - 1) * 16) / columns
		local compact = w < 650
		local telemetryWraps = w < 470
		local summaryHeight = if telemetryWraps then 258 elseif compact then 220 else 150

		Kit.place(operationSummary, 0, 137, w, summaryHeight)
		Kit.place(energyBar, 22, 82, w - 44, 6)

		operationTelemetry.Position = UDim2.fromOffset(22, 108)
		operationTelemetry.Size = UDim2.fromOffset(w - 44, if telemetryWraps then 58 else 22)
		operationTelemetry.TextWrapped = telemetryWraps

		if compact then
			Kit.place(rechargeButton, 22, if telemetryWraps then 182 else 158, w - 44, 44)
		else
			Kit.place(rechargeButton, w - 218, 28, 196, 44)
		end

		local startY = 137 + summaryHeight + 16

		for index, item in ipairs(operationCards) do
			local row = (index - 1) // columns
			local column = (index - 1) % columns

			Kit.place(item.card, column * (cw + 16), startY + row * 258, cw, 242)
			Kit.place(item.iconShell, 20, 16, 50, 50)

			item.title.Size = UDim2.fromOffset(cw - 104, 42)
			item.detail.Size = UDim2.fromOffset(cw - 40, 42)
			item.chance.Size = UDim2.fromOffset(cw - 40, 22)
			item.chance.TextSize = if cw < 390 then 9 else 11
			item.reward.Size = UDim2.fromOffset(cw - 40, 22)
			item.reward.TextSize = if cw < 330 then 10 else 12

			Kit.place(item.launch, 20, 182, cw - 40, 44)
		end

		return startY + math.ceil(#operationCards / columns) * 258
	end)
end

return InterfacePageOperations
