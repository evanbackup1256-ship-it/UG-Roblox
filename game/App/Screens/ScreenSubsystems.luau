--!strict
-- ScreenSubsystems: Firmware module calibration and subsystem tuning
local AppContext = require(script.Parent.Parent.AppContext)
local Fuzzy = require(script.Parent.Parent.Parent.Fuzzy)

local ScreenSubsystems = {}

function ScreenSubsystems.build(ctx: AppContext.Context)
	local Elements = ctx.Elements
	local Buttons = ctx.Buttons
	local Inputs = ctx.Inputs
	local Feedback = ctx.Feedback
	local C = ctx.C
	local Config = ctx.Config
	local fmt = ctx.fmt

	local root = ctx.screens.modules
	local query = ""

	local searchInput = Inputs.input(root, "ModuleSearch", "Search firmware modules…", function(q)
		query = q
		ctx.relayout("modules")
	end)

	local effectNames = {
		production = "Automated Fleet Output",
		job = "Manual Workstation Payout",
		energy = "Energy Grid Capacity",
		success = "Mission Success Probability",
		operation = "Mission Operation Payout",
		reputation = "Prestige Token Yield",
		recovery = "Energy Recovery Rate",
		data = "Field Data Extraction",
		hardware = "Hardware Purchase Discount",
	}

	local SERIES = { "Core Series", "Array Series", "Nexus Series" }

	local moduleCards = {}
	for index, mod in ipairs(Config.Modules) do
		local card = Elements.interactiveCard(root, "Module_" .. mod.key, 210, C.card)

		local seriesIdx = math.clamp((index - 1) // 12 + 1, 1, 3)
		local seriesColor = if seriesIdx == 1 then C.accent elseif seriesIdx == 2 then C.data else C.energy
		local seriesBadge = Elements.badge(card, SERIES[seriesIdx], if seriesIdx == 1 then "accent" elseif seriesIdx == 2 then "data" else "warning", true)
		Elements.place(seriesBadge, 20, 16, 88, 22)

		-- Shimmer gleam on highest tier Nexus series
		if seriesIdx == 3 then

		end

		local levelLabel = Elements.text(card, "Level", "Tier 0 / 5", 11, C.textMuted, true)
		levelLabel.Font = ctx.Theme.typography.fontMono
		levelLabel.AnchorPoint = Vector2.new(1, 0)
		levelLabel.TextXAlignment = Enum.TextXAlignment.Right
		levelLabel.Position = UDim2.new(1, -20, 0, 16)
		levelLabel.Size = UDim2.fromOffset(110, 22)

		local title = Elements.text(card, "Title", mod.name, 16, C.textPrimary, true)
		Elements.place(title, 20, 44, 320, 24)

		local detail = Elements.text(card, "Detail", mod.subtitle or "Subsystem calibration firmware", 12, C.textSecondary)
		detail.TextWrapped = true
		Elements.place(detail, 20, 70, 340, 32)

		local effectLabel = Elements.text(card, "Effect", effectNames[mod.effect] or string.upper(mod.effect), 11, seriesColor, true)
		effectLabel.Font = ctx.Theme.typography.fontMono
		Elements.place(effectLabel, 20, 108, 340, 18)

		local progressBar = Inputs.progressBar(card, "Progress", 6, seriesColor)
		Elements.place(progressBar.instance, 20, 132, 300, 6)

		local calibrateBtn = Buttons.button(card, "Calibrate", "Calibrate", function()
			if ctx.state then
				Feedback.floatText(card, "+1 " .. mod.name, seriesColor, UDim2.fromScale(0.85, 0.45))
			end
			ctx.act("module", mod.key)
		end, "primary")
		Elements.place(calibrateBtn, 20, 150, 140, 38)

		moduleCards[index] = {
			mod = mod,
			card = card,
			title = title,
			detail = detail,
			levelLabel = levelLabel,
			effectLabel = effectLabel,
			progressBar = progressBar,
			calibrateBtn = calibrateBtn,
			searchString = string.lower(mod.name .. " " .. (mod.subtitle or "")),
		}
	end

	local emptyLabel = Elements.text(root, "Empty", "No firmware modules match your search.", 14, C.textMuted)
	emptyLabel.TextWrapped = true
	emptyLabel.Visible = false

	-- =========================================================================
	-- 2. STATE BINDING
	-- =========================================================================
	ctx.bind("modules", function(s)
		local modLevels = s.modules or {}
		local compute = s.compute or 0
		local fieldData = s.data or 0

		for _, item in ipairs(moduleCards) do
			local curLevel = modLevels[item.mod.key] or 0
			local costCompute, costData = Config.moduleCost(item.mod, curLevel)
			local isMax = curLevel >= item.mod.max
			local progressRatio = math.clamp(curLevel / item.mod.max, 0, 1)

			item.levelLabel.Text = string.format("Tier %d / %d", curLevel, item.mod.max)
			item.progressBar:setProgress(progressRatio, true)

			local canAfford = compute >= costCompute and fieldData >= costData
			Buttons.enable(
				item.calibrateBtn,
				not isMax and canAfford,
				if isMax then "Calibrated" else string.format("Tune · %s C · %s D", fmt(costCompute), fmt(costData)),
				true
			)
		end
	end)

	-- =========================================================================
	-- 3. RESPONSIVE LAYOUT
	-- =========================================================================
	ctx.layoutScreen("modules", function(w)
		Elements.place(searchInput, 0, 0, w, 38)
		local gridStartY = 48

		local matchedCards = {}
		for _, item in ipairs(moduleCards) do
			if query == "" or (Fuzzy.score(query, item.searchString) or 0) > 0 then
				table.insert(matchedCards, item)
			end
		end

		for _, item in ipairs(moduleCards) do
			item.card.Visible = false
		end

		if #matchedCards == 0 then
			emptyLabel.Visible = true
			Elements.place(emptyLabel, 0, gridStartY + 40, w, 40)
			return gridStartY + 100
		else
			emptyLabel.Visible = false
		end

		local cols = if w >= 860 then 2 else 1
		local cardW = math.floor((w - (cols - 1) * 16) / cols)
		local cardH = 202

		for idx, item in ipairs(matchedCards) do
			local localIdx = idx - 1
			local col = localIdx % cols
			local row = localIdx // cols
			local cx = col * (cardW + 16)
			local cy = gridStartY + row * (cardH + 16)

			item.card.Visible = true
			Elements.place(item.card, cx, cy, cardW, cardH)

			item.levelLabel.AnchorPoint = Vector2.new(1, 0)
			item.levelLabel.Position = UDim2.new(1, -20, 0, 16)
			item.levelLabel.Size = UDim2.fromOffset(110, 22)

			item.title.Position = UDim2.fromOffset(20, 44)
			item.title.Size = UDim2.fromOffset(cardW - 40, 22)
			item.detail.Position = UDim2.fromOffset(20, 68)
			item.detail.Size = UDim2.fromOffset(cardW - 40, 32)
			Elements.place(item.effectLabel, 20, 102, cardW - 40, 18)
			Elements.place(item.progressBar.instance, 20, 124, cardW - 40, 6)
			Elements.place(item.calibrateBtn, 20, 142, cardW - 40, 42)
		end

		local totalRows = math.ceil(#matchedCards / cols)
		return gridStartY + totalRows * (cardH + 16) + 32
	end)
end

return ScreenSubsystems

