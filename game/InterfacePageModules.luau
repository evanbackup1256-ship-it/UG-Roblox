--!strict
local InterfaceShared = require(script.Parent.InterfaceShared)
local Fuzzy = require(script.Parent.Fuzzy)

local InterfacePageModules = {}

function InterfacePageModules.build(Shared: InterfaceShared.Shared)
	local Kit = Shared.Kit
	local C = Shared.C
	local Config = Shared.Config
	local positionText = Shared.positionText
	local liven = Shared.liven
	local bump = Shared.bump
	local bind = Shared.bind
	local layoutPage = Shared.layoutPage
	local relayout = Shared.relayout
	local connect = Shared.connect
	local fmt = Shared.fmt

	local pageRoot = Shared.pages.modules
	local pageIndex = 1
	local query = ""

	local searchInput = Kit.input(pageRoot, "ModuleSearch", "Search firmware modules…")

	local effectDisplayNames = {
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

	local GENERATION_NAMES = { "Core Series", "Array Series", "Nexus Series" }

	local moduleCards = {}
	for index, module in ipairs(Config.Modules) do
		local card = Kit.interactiveCard(pageRoot, "Module_" .. module.key, 230, C.panel)

		local genIdx = math.clamp((index - 1) // 12 + 1, 1, 3)
		local genColor = if genIdx == 1 then C.accent elseif genIdx == 2 then C.data else C.energy
		local genBadgeStyle = if genIdx == 1 then "accent" elseif genIdx == 2 then "data" else "warning"

		local genBadge = Kit.badge(card, GENERATION_NAMES[genIdx], genBadgeStyle, true)
		Kit.place(genBadge, 20, 16, 90, 20)

		local status = Kit.statusDot(card, C.muted, "Idle", 6)
		Kit.place(status, 118, 23, 6, 6)

		local level = positionText(card, "Level", "Tier 0 / 5", 140, 16, 180, 20, 11, C.muted, true)
		level.Font = Enum.Font.RobotoMono
		level.TextXAlignment = Enum.TextXAlignment.Right

		local title = positionText(card, "Title", module.name, 20, 44, 330, 26, 16, C.text, true)
		title.TextWrapped = true

		local detail = positionText(card, "Detail", module.subtitle, 20, 72, 330, 32, 12, C.textSub)
		detail.TextWrapped = true

		local effectName = effectDisplayNames[module.effect] or string.upper(module.effect)
		local effect = positionText(card, "Effect", effectName, 20, 112, 330, 20, 11, genColor, true)
		effect.Font = Enum.Font.RobotoMono

		local progressBar = Kit.progressBar(card, "CalibrationBar", 6, genColor)

		local calibrateBtn = liven(Kit.button(card, "Calibrate", "Connecting…", function()
			if Shared.state then
				local curLvl = Shared.state.modules[module.key] or 0
				if curLvl + 1 >= module.max then
					Kit.fanfare(card, genColor)
					Kit.floatText(card, "Max Level Reached", genColor, Vector2.new(0.5, 0.45))
				else
					Kit.floatText(card, "+1 " .. module.name, genColor, Vector2.new(0.5, 0.45))
				end
			end
			Shared.fn.act("module", module.key)
		end, "primary"))

		moduleCards[index] = {
			card = card,
			module = module,
			title = title,
			detail = detail,
			level = level,
			effect = effect,
			progressBar = progressBar,
			status = status,
			calibrateBtn = calibrateBtn,
			genColor = genColor,
			bumpLevel = bump(level),
			searchString = string.lower(module.name .. " " .. (module.subtitle or "")),
		}
	end

	local emptyLabel = positionText(pageRoot, "Empty", "No firmware modules match your search.", 0, 0, 600, 44, 14, C.muted)
	emptyLabel.TextWrapped = true
	emptyLabel.Visible = false

	local placePager = Shared.pager(pageRoot, function()
		pageIndex = math.max(1, pageIndex - 1)
		relayout("modules")
		Shared.fn.revealPageChange("modules")
	end, function()
		pageIndex += 1
		relayout("modules")
		Shared.fn.revealPageChange("modules")
	end)

	connect(searchInput:GetPropertyChangedSignal("Text"), function()
		local clean = string.lower(searchInput.Text)
		if clean == query then return end
		query = clean
		pageIndex = 1
		relayout("modules")
	end)

	-- =========================================================================
	-- STATE BINDING
	-- =========================================================================
	bind("modules", function(s)
		local moduleLevels = s.modules or {}
		local compute = s.compute or 0
		local data = s.data or 0

		for _, mc in ipairs(moduleCards) do
			local curLevel = moduleLevels[mc.module.key] or 0
			local isMax = curLevel >= mc.module.max
			local progressRatio = math.clamp(curLevel / mc.module.max, 0, 1)

			local computeCost = Config.moduleComputeCost(mc.module, curLevel, s)
			local dataCost = Config.moduleDataCost(mc.module, curLevel, s)

			mc.level.Text = string.format("Tier %d / %d", curLevel, mc.module.max)
			mc.progressBar:SetProgress(progressRatio, true)
			mc.status.Dot.BackgroundColor3 = if isMax then C.gold elseif curLevel > 0 then mc.genColor else C.muted

			Kit.enable(
				mc.calibrateBtn,
				not isMax and compute >= computeCost and data >= dataCost,
				if isMax then "Max Calibrated" else "Calibrate · " .. fmt(computeCost) .. "C " .. fmt(dataCost) .. "D",
				true
			)
		end

		relayout("modules")
	end)

	-- =========================================================================
	-- RESPONSIVE LAYOUT
	-- =========================================================================
	layoutPage("modules", function(w)
		Kit.place(searchInput, 0, 137, w, 40)

		local matchedCards = {}
		for _, mc in ipairs(moduleCards) do
			if query == "" or Fuzzy.score(query, mc.searchString) > 0 then
				table.insert(matchedCards, mc)
			end
		end

		for _, mc in ipairs(moduleCards) do
			mc.card.Visible = false
		end

		local gridStartY = 189

		if #matchedCards == 0 then
			emptyLabel.Visible = true
			Kit.place(emptyLabel, 0, gridStartY + 40, w, 44)
			return gridStartY + 120
		else
			emptyLabel.Visible = false
		end

		local columns = math.clamp((w + 16) // 320, 1, 3)
		local cardWidth = (w - (columns - 1) * 16) / columns
		local cardHeight = 230

		local perPage = columns * 4
		local totalPages = math.max(1, math.ceil(#matchedCards / perPage))
		pageIndex = math.clamp(pageIndex, 1, totalPages)

		local pageStart = (pageIndex - 1) * perPage + 1
		local pageEnd = math.min(#matchedCards, pageIndex * perPage)
		local visibleCount = pageEnd - pageStart + 1

		for idx = pageStart, pageEnd do
			local mc = matchedCards[idx]
			local localIdx = idx - pageStart
			local col = localIdx % columns
			local row = localIdx // columns

			local cardX = col * (cardWidth + 16)
			local cardY = gridStartY + row * (cardHeight + 16)

			mc.card.Visible = true
			Kit.place(mc.card, cardX, cardY, cardWidth, cardHeight)

			mc.title.Size = UDim2.fromOffset(cardWidth - 40, 26)
			mc.detail.Size = UDim2.fromOffset(cardWidth - 40, 32)
			mc.level.Position = UDim2.fromOffset(cardWidth - 160, 16)
			mc.level.Size = UDim2.fromOffset(140, 20)

			Kit.place(mc.progressBar.instance, 20, 138, cardWidth - 40, 6)
			Kit.place(mc.calibrateBtn, 20, 158, cardWidth - 40, 40)
		end

		local totalRows = math.ceil(visibleCount / columns)
		local endY = gridStartY + totalRows * (cardHeight + 16)

		if totalPages > 1 then
			placePager(w, endY + 8, pageIndex, totalPages, #matchedCards, "modules")
			return endY + 68
		end

		return endY + 16
	end)
end

return InterfacePageModules
