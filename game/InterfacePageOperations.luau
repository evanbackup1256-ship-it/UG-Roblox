--!strict
local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageOperations = {}

function InterfacePageOperations.build(Shared: InterfaceShared.Shared)
	local Kit = Shared.Kit
	local C = Shared.C
	local Config = Shared.Config
	local positionText = Shared.positionText
	local liven = Shared.liven
	local bind = Shared.bind
	local layoutPage = Shared.layoutPage
	local fmt = Shared.fmt
	local Tokens = Shared.Tokens

	local pageRoot = Shared.pages.operations

	-- =========================================================================
	-- 1. TELEMETRY HEADER: ENERGY GRID & SHIFT METRICS
	-- =========================================================================
	local operationSummary = Kit.card(pageRoot, "ShiftTelemetry", 150, C.panel)

	local eyebrow = positionText(operationSummary, "Eyebrow", "Tactical Fleet Operations", 22, 16, 260, 20, 11, C.textSub, true)

	local statusBadge = Kit.badge(operationSummary, "Grid Nominal", "energy", true)
	Kit.place(statusBadge, 220, 16, 90, 20)

	local energyValue = positionText(operationSummary, "Energy", "100 / 100 Energy", 22, 40, 300, 30, 20, C.energy, true)
	energyValue.Font = Enum.Font.RobotoMono

	local energyProgressBar = Kit.progressBar(operationSummary, "EnergyReserve", 6, C.energy)

	local operationTelemetry = positionText(operationSummary, "Telemetry", "", 22, 110, 700, 20, 11, C.muted)
	operationTelemetry.Font = Enum.Font.RobotoMono

	local rechargeButton = liven(Kit.button(operationSummary, "Recharge", "Emergency Recharge", function()
		Shared.fn.act("recharge")
	end, "secondary"))

	-- =========================================================================
	-- 2. DISPATCH MISSION CARDS
	-- =========================================================================
	local operationCards = {}
	for index, operation in ipairs(Config.Operations) do
		local card = Kit.interactiveCard(pageRoot, "Operation_" .. operation.key, 240, C.panel)

		local opBadge = Kit.badge(
			card,
			string.format("Mission %02d", index),
			if index > 8 then "danger" elseif index > 4 then "warning" else "accent",
			true
		)
		Kit.place(opBadge, 20, 16, 80, 20)

		local iconShell = Kit.create("Frame", card, {
			Name = "IconShell",
			BackgroundColor3 = C.raised,
			BorderSizePixel = 0,
		})
		Kit.corner(iconShell, Kit.radius.control)
		Kit.place(
			Kit.icon(iconShell, "Icon", operation.icon or "operations", if index % 3 == 0 then C.accent2 else C.accent),
			11,
			11,
			22,
			22
		)

		local title = positionText(card, "Title", operation.name, 20, 44, 300, 26, 16, C.text, true)
		title.TextWrapped = true

		local detail = positionText(card, "Detail", operation.subtitle, 20, 68, 360, 38, 12, C.textSub)
		detail.TextWrapped = true

		local chance = positionText(card, "Chance", "Reliability: 0%", 20, 112, 200, 20, 11, C.accent, true)
		chance.Font = Enum.Font.RobotoMono

		local reward = positionText(card, "Reward", "", 20, 136, 360, 20, 11, C.text, true)
		reward.Font = Enum.Font.RobotoMono
		reward.Text = string.format(
			"+%s Compute   +%s Data   +%s XP",
			fmt(operation.reward),
			fmt(operation.data),
			fmt(operation.xp)
		)

		local launchBtn = liven(Kit.button(card, "Launch", "Connecting…", function()
			Kit.floatText(card, "Dispatching…", C.energy, Vector2.new(0.5, 0.45))
			Shared.fn.act("operation", operation.key)
		end, "primary"))

		operationCards[index] = {
			card = card,
			operation = operation,
			index = index,
			iconShell = iconShell,
			title = title,
			detail = detail,
			chance = chance,
			reward = reward,
			launchBtn = launchBtn,
		}
	end

	-- =========================================================================
	-- 3. STATE BINDING
	-- =========================================================================
	bind("operations", function(s)
		local level = s.level or 1
		local energy = s.energy or 0
		local capacity = math.max(1, s.energyCapacity or 100)
		local mastery = s.operationMastery or {}
		local sharedChance = Config.moduleEffect(s, "success") + math.min(0.08, (s.reputation or 0) / 25000)

		energyValue.Text = string.format("%d / %d Energy", math.floor(energy), math.floor(capacity))
		energyProgressBar:SetProgress(math.clamp(energy / capacity, 0, 1), true)

		operationTelemetry.Text = string.format(
			"Level %d  ·  %s Data  ·  %s Reputation  ·  ×%d Streak  ·  %d Critical  ·  %d Flawless",
			level,
			fmt(s.data or 0),
			fmt(s.reputation or 0),
			s.operationCombo or 0,
			s.criticalSuccesses or 0,
			s.flawlessSuccesses or 0
		)

		local energyDepleted = energy < 10
		Kit.enable(
			rechargeButton,
			energyDepleted and (s.compute or 0) >= 100,
			if energyDepleted then "Emergency Recharge · 100 C" else "Reserve Stable",
			true
		)

		for _, item in ipairs(operationCards) do
			local op = item.operation
			local unlocked = level >= op.unlock
			local enoughEnergy = energy >= op.energy
			local opMastery = mastery[op.key] or 0

			local successChance = math.clamp(
				op.chance + opMastery * 0.005 + sharedChance,
				0.15,
				0.98
			)

			item.chance.Text = string.format("Reliability: %d%% · %d Energy", math.floor(successChance * 100), op.energy)
			Kit.lock(item.card, not unlocked, item.launchBtn)

			Kit.enable(
				item.launchBtn,
				unlocked and enoughEnergy,
				if not unlocked then "Unlocks at Level " .. op.unlock
					elseif not enoughEnergy then "Requires " .. op.energy .. " Energy"
					else "Dispatch Mission",
				true
			)
		end
	end)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	layoutPage("operations", function(w)
		local narrow = w < 680

		Kit.place(operationSummary, 0, 137, w, if narrow then 170 else 146)
		Kit.place(energyProgressBar.instance, 22, 78, if narrow then w - 44 else w - 240, 6)
		Kit.place(rechargeButton, if narrow then 22 else w - 210, if narrow then 96 else 52, if narrow then w - 44 else 188, 38)
		operationTelemetry.Position = UDim2.fromOffset(22, if narrow then 144 else 108)
		operationTelemetry.Size = UDim2.fromOffset(w - 44, 20)

		local gridStartY = 137 + (if narrow then 170 else 146) + 16

		local columns = if w >= 880 then 2 else 1
		local cardWidth = (w - (columns - 1) * 16) / columns
		local cardHeight = 240

		for idx, item in ipairs(operationCards) do
			local localIdx = idx - 1
			local col = localIdx % columns
			local row = localIdx // columns

			local cardX = col * (cardWidth + 16)
			local cardY = gridStartY + row * (cardHeight + 16)

			Kit.place(item.card, cardX, cardY, cardWidth, cardHeight)

			item.title.Size = UDim2.fromOffset(cardWidth - 110, 26)
			item.detail.Size = UDim2.fromOffset(cardWidth - 40, 38)
			Kit.place(item.iconShell, cardWidth - 60, 16, 44, 44)
			Kit.place(item.launchBtn, 20, 178, cardWidth - 40, 40)
		end

		local totalRows = math.ceil(#operationCards / columns)
		return gridStartY + totalRows * (cardHeight + 16)
	end)
end

return InterfacePageOperations
