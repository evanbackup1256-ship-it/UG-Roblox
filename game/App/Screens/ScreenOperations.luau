--!strict
-- ScreenOperations: Tactical fleet mission dispatch and energy grid monitor
local AppContext = require(script.Parent.Parent.AppContext)

local ScreenOperations = {}

function ScreenOperations.build(ctx: AppContext.Context)
	local Elements = ctx.Elements
	local Buttons = ctx.Buttons
	local Inputs = ctx.Inputs
	local Feedback = ctx.Feedback
	local C = ctx.C
	local Config = ctx.Config
	local fmt = ctx.fmt

	local root = ctx.screens.operations

	-- =========================================================================
	-- 1. ENERGY GRID TELEMETRY HERO
	-- =========================================================================
	local summary = Elements.card(root, "GridTelemetry", 146, C.card)


	local eyebrow = Elements.text(summary, "Eyebrow", "Power Grid", 12, C.textSecondary, true)
	Elements.place(eyebrow, 22, 16, 140, 20)

	local statusBadge = Elements.badge(summary, "Online", "energy", true)
	statusBadge.AnchorPoint = Vector2.new(1, 0)
	statusBadge.Position = UDim2.new(1, -22, 0, 16)

	local energyValue = Elements.text(summary, "Energy", "100 / 100", 22, C.energy, true)
	energyValue.Font = ctx.Theme.typography.fontDisplay
	Elements.place(energyValue, 22, 42, 280, 30)

	local energyBar = Inputs.progressBar(summary, "ReserveBar", 6, C.energy)

	local telemetry = Elements.text(summary, "Telemetry", "", 12, C.textMuted)
	Elements.place(telemetry, 22, 108, 600, 20)

	local rechargeBtn = Buttons.button(summary, "Recharge", "Recharge", function()
		Feedback.ringPulse(summary, UDim2.fromScale(0.85, 0.5), C.energy)
		ctx.act("recharge")
	end, "secondary")

	-- =========================================================================
	-- 2. OPERATION MISSION CARDS
	-- =========================================================================
	local operationCards = {}
	for index, op in ipairs(Config.Operations) do
		local card = Elements.interactiveCard(root, "Operation_" .. op.key, 216, C.card)

		local badgeStyle = if index > 8 then "danger" elseif index > 4 then "warning" else "accent"
		local opBadge = Elements.badge(card, string.format("Task %02d", index), badgeStyle, true)
		Elements.place(opBadge, 20, 16, 80, 22)

		local title = Elements.text(card, "Title", op.name, 16, C.textPrimary, true)
		title.TextWrapped = true
		Elements.place(title, 20, 46, 280, 22)

		local detail = Elements.text(card, "Detail", op.subtitle or "Server deployment operation", 13, C.textSecondary)
		detail.TextWrapped = true
		Elements.place(detail, 20, 70, 300, 28)

		local chance = Elements.text(card, "Chance", "Success Rate: 0%", 12, C.accent, true)
		Elements.place(chance, 20, 102, 200, 18)

		local reward = Elements.text(
			card,
			"Reward",
			string.format("+%s Compute · +%s Data · +%s XP", fmt(op.reward), fmt(op.data), fmt(op.xp)),
			12,
			C.textPrimary,
			true
		)
		Elements.place(reward, 20, 122, 300, 18)

		local dispatchBtn = Buttons.button(card, "Dispatch", "Start", function()
			if ctx.state then
				Feedback.floatText(card, "Starting...", C.energy, UDim2.fromScale(0.85, 0.45))
			end
			ctx.act("operation", op.key)
		end, "primary")
		Elements.place(dispatchBtn, 20, 156, 140, 42)

		operationCards[index] = {
			op = op,
			card = card,
			title = title,
			detail = detail,
			chance = chance,
			reward = reward,
			dispatchBtn = dispatchBtn,
		}
	end

	-- =========================================================================
	-- 3. STATE BINDING
	-- =========================================================================
	ctx.bind("operations", function(s)
		local level = s.level or 1
		local energy = s.energy or 0
		local cap = math.max(1, Config.energyCapacity(s))
		local mastery = s.operationMastery or {}
		local sharedChance = Config.moduleEffect(s, "success") + math.min(0.08, (s.reputation or 0) / 25000)

		energyValue.Text = string.format("%d / %d", math.floor(energy), math.floor(cap))
		energyBar:setProgress(math.clamp(energy / cap, 0, 1), true)

		telemetry.Text = string.format(
			"Level %d  ·  %s Data  ·  %s Reputation  ·  x%d Streak  ·  %d Criticals",
			level,
			fmt(s.data or 0),
			fmt(s.reputation or 0),
			s.operationCombo or 0,
			s.criticalSuccesses or 0
		)

		local rechargeCost = if Config.rechargeCost then Config.rechargeCost(s) else 100
		local needsRecharge = energy < cap - 1
		local canAffordRecharge = (s.compute or 0) >= rechargeCost
		Buttons.enable(
			rechargeBtn,
			needsRecharge and canAffordRecharge,
			if not needsRecharge then "Fully Charged"
				elseif canAffordRecharge then string.format("Recharge · %s C", fmt(rechargeCost))
				else string.format("Recharge · Need %s C", fmt(rechargeCost)),
			true
		)

		for _, item in ipairs(operationCards) do
			local op = item.op
			local unlocked = level >= op.unlock
			local hasEnergy = energy >= op.energy
			local opMastery = mastery[op.key] or 0
			local successChance = math.clamp(op.chance + opMastery * 0.005 + sharedChance, 0.15, 0.98)

			item.chance.Text = string.format("Success Rate: %d%% · Cost: %d", math.floor(successChance * 100), op.energy)
			Feedback.lock(item.card, not unlocked, item.dispatchBtn)

			Buttons.enable(
				item.dispatchBtn,
				unlocked and hasEnergy,
				if not unlocked then "Unlocks at Level " .. op.unlock
					elseif not hasEnergy then "Requires " .. op.energy .. " Energy"
					else "Start",
				true
			)
		end
	end)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	ctx.layoutScreen("operations", function(w)
		local narrow = w < 680

		Elements.place(summary, 0, 0, w, if narrow then 170 else 146)
		Elements.place(energyBar.instance, 22, 78, if narrow then w - 44 else w - 240, 6)
		Elements.place(rechargeBtn, if narrow then 22 else w - 210, if narrow then 96 else 50, if narrow then w - 44 else 188, 38)
		telemetry.Position = UDim2.fromOffset(22, if narrow then 144 else 108)
		telemetry.Size = UDim2.fromOffset(w - 44, 20)

		local gridStartY = (if narrow then 170 else 146) + 16
		local cols = if w >= 860 then 2 else 1
		local cardW = math.floor((w - (cols - 1) * 16) / cols)
		local cardH = 216

		for idx, item in ipairs(operationCards) do
			local localIdx = idx - 1
			local col = localIdx % cols
			local row = localIdx // cols
			local cx = col * (cardW + 16)
			local cy = gridStartY + row * (cardH + 16)

			Elements.place(item.card, cx, cy, cardW, cardH)
			item.title.Position = UDim2.fromOffset(20, 46)
			item.title.Size = UDim2.fromOffset(cardW - 40, 22)
			item.detail.Position = UDim2.fromOffset(20, 70)
			item.detail.Size = UDim2.fromOffset(cardW - 40, 28)
			item.chance.Position = UDim2.fromOffset(20, 102)
			item.chance.Size = UDim2.fromOffset(cardW - 40, 18)
			item.reward.Position = UDim2.fromOffset(20, 122)
			item.reward.Size = UDim2.fromOffset(cardW - 40, 18)
			Elements.place(item.dispatchBtn, 20, 156, cardW - 40, 42)
		end

		local totalRows = math.ceil(#operationCards / cols)
		return gridStartY + totalRows * (cardH + 16) + 32
	end)
end

return ScreenOperations

