--!strict
local InterfaceShared = require(script.Parent.InterfaceShared)
local Fuzzy = require(script.Parent.Fuzzy)

local InterfacePageInfrastructure = {}

function InterfacePageInfrastructure.build(Shared: InterfaceShared.Shared)
	local Kit = Shared.Kit
	local C = Shared.C
	local Config = Shared.Config
	local positionText = Shared.positionText
	local liven = Shared.liven
	local bind = Shared.bind
	local layoutPage = Shared.layoutPage
	local relayout = Shared.relayout
	local connect = Shared.connect
	local fmt = Shared.fmt
	local preferences = Shared.preferences

	local pageRoot = Shared.pages.infrastructure

	-- Page-local interactive state
	local quantity = 1
	local query = ""
	local filterMode = "all"
	local pageIndex = 1

	-- =========================================================================
	-- 1. TOP TOOLBAR: SEARCH & CONTROL SEGMENTS
	-- =========================================================================
	local searchInput = Kit.input(pageRoot, "HardwareSearch", "Search hardware tiers…")

	local filterSegment = Kit.segmented(
		pageRoot,
		"FilterSegment",
		{ "All Units", "Deployed", "Available" },
		1,
		function(idx)
			filterMode = if idx == 2 then "owned" elseif idx == 3 then "unlocked" else "all"
			pageIndex = 1
			relayout("infrastructure")
			Shared.fn.revealPageChange("infrastructure")
		end
	)

	local quantitySegment = Kit.segmented(
		pageRoot,
		"QuantitySegment",
		{ "×1", "×5", "×10" },
		1,
		function(idx)
			quantity = if idx == 2 then 5 elseif idx == 3 then 10 else 1
			Shared.quantity = quantity
			if Shared.state then
				Shared.fn.apply(Shared.state)
			end
		end
	)

	local placePager = Shared.pager(pageRoot, function()
		pageIndex = math.max(1, pageIndex - 1)
		relayout("infrastructure")
		Shared.fn.revealPageChange("infrastructure")
	end, function()
		pageIndex += 1
		relayout("infrastructure")
		Shared.fn.revealPageChange("infrastructure")
	end)

	-- =========================================================================
	-- 2. HARDWARE TIER CARD GRID
	-- =========================================================================
	local tierCards = {}
	for index, tier in ipairs(Config.Tiers) do
		local card = Kit.interactiveCard(pageRoot, "Tier_" .. tier.key, 270, C.panel)

		Kit.place(Kit.icon(card, "Icon", tier.icon or "infrastructure", tier.color or C.accent), 20, 20, 22, 22)

		local title = positionText(card, "Title", tier.name, 52, 18, 220, 24, 16, C.text, true)
		local ownedLabel = positionText(card, "Owned", "0 deployed", 20, 48, 140, 20, 12, C.muted)

		local tierBadge = Kit.badge(card, string.format("Tier %02d", index), "raised", true)
		Kit.place(tierBadge, 210, 18, 64, 20)

		local status = Kit.statusDot(card, C.muted, "Offline", 6)
		Kit.place(status, 164, 25, 6, 6)

		local stageRoot = Kit.create("Frame", card, {
			Name = "PreviewStage",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 70),
			Size = UDim2.new(1, 0, 0, 110),
		})
		Shared.director:Add(stageRoot, index, tier.color)

		local output = positionText(
			card,
			"Output",
			"+" .. fmt(tier.rate) .. "/s each",
			20,
			186,
			240,
			22,
			13,
			tier.color or C.accent,
			true
		)
		output.Font = Enum.Font.RobotoMono

		local deployButton = liven(Kit.button(card, "Deploy", "Connecting…", function()
			if preferences.particles ~= false then
				Kit.confetti(card, tier.color or C.accent)
			end
			Kit.floatText(card, "+1 " .. tier.name, tier.color or C.compute, Vector2.new(0.5, 0.45))
			Shared.fn.act("buy", tier.key)
		end, "primary"))

		tierCards[index] = {
			card = card,
			tier = tier,
			title = title,
			ownedLabel = ownedLabel,
			tierBadge = tierBadge,
			status = status,
			output = output,
			deployButton = deployButton,
			searchString = string.lower(tier.name .. " " .. (tier.subtitle or "")),
		}
	end

	local emptyLabel = positionText(pageRoot, "Empty", "No hardware matching current filter criteria.", 0, 0, 600, 44, 14, C.muted)
	emptyLabel.TextWrapped = true
	emptyLabel.Visible = false

	-- Search Query Listener
	connect(searchInput:GetPropertyChangedSignal("Text"), function()
		local clean = string.lower(searchInput.Text)
		if clean == query then return end
		query = clean
		pageIndex = 1
		relayout("infrastructure")
	end)

	-- =========================================================================
	-- 3. STATE BINDING
	-- =========================================================================
	bind("infrastructure", function(s)
		local units = s.units or 0
		local compute = s.compute or 0

		for _, item in ipairs(tierCards) do
			local count = s.owned[item.tier.key] or 0
			local cost = Config.buyCost(item.tier, count, s)
			local isUnlocked = units >= item.tier.unlock

			item.ownedLabel.Text = count .. " deployed"
			item.status.Dot.BackgroundColor3 = if count > 0 then C.compute else C.muted

			Kit.lock(item.card, not isUnlocked, item.deployButton)

			Kit.enable(
				item.deployButton,
				isUnlocked and count < 200 and compute >= cost,
				if count >= 200 then "At Max Capacity"
					elseif not isUnlocked then item.tier.unlock .. " units required"
					elseif quantity > 1 then "Deploy ×" .. quantity .. " · " .. fmt(cost)
					else "Deploy · " .. fmt(cost),
				true
			)
		end

		relayout("infrastructure")
	end)

	-- =========================================================================
	-- 4. RESPONSIVE GRID LAYOUT
	-- =========================================================================
	layoutPage("infrastructure", function(w)
		local columns = math.clamp((w + 16) // 320, 1, 3)
		local cardWidth = (w - (columns - 1) * 16) / columns
		local narrow = w < 680

		-- Top Controls Placement
		if narrow then
			Kit.place(searchInput, 0, 137, w, 40)
			Kit.place(filterSegment.instance, 0, 183, math.floor((w - 10) * 0.65), 36)
			Kit.place(quantitySegment.instance, math.floor((w - 10) * 0.65) + 10, 183, w - math.floor((w - 10) * 0.65) - 10, 36)
		else
			local searchW = math.floor(w * 0.42)
			Kit.place(searchInput, 0, 137, searchW, 40)
			local filterW = math.floor((w - searchW - 24) * 0.66)
			Kit.place(filterSegment.instance, searchW + 12, 137, filterW, 40)
			Kit.place(quantitySegment.instance, searchW + filterW + 24, 137, w - (searchW + filterW + 24), 40)
		end

		local gridStartY = if narrow then 231 else 189

		-- Filter Matching
		local matchedCards = {}
		local s = Shared.state
		local totalUnits = (s and s.units) or 0

		for _, item in ipairs(tierCards) do
			local matchesSearch = query == "" or Fuzzy.score(query, item.searchString) > 0
			local count = (s and s.owned[item.tier.key]) or 0
			local isUnlocked = totalUnits >= item.tier.unlock

			local matchesFilter = true
			if filterMode == "owned" then
				matchesFilter = count > 0
			elseif filterMode == "unlocked" then
				matchesFilter = isUnlocked
			end

			if matchesSearch and matchesFilter then
				table.insert(matchedCards, item)
			end
		end

		-- Pagination Calculations
		local perPage = columns * 4
		local totalPages = math.max(1, math.ceil(#matchedCards / perPage))
		pageIndex = math.clamp(pageIndex, 1, totalPages)

		local pageStart = (pageIndex - 1) * perPage + 1
		local pageEnd = math.min(#matchedCards, pageIndex * perPage)

		for _, item in ipairs(tierCards) do
			item.card.Visible = false
		end

		if #matchedCards == 0 then
			emptyLabel.Visible = true
			Kit.place(emptyLabel, 0, gridStartY + 40, w, 44)
			return gridStartY + 120
		else
			emptyLabel.Visible = false
		end

		local cardHeight = 270
		local visibleCount = pageEnd - pageStart + 1

		for idx = pageStart, pageEnd do
			local item = matchedCards[idx]
			local localIdx = idx - pageStart
			local col = localIdx % columns
			local row = localIdx // columns

			local cardX = col * (cardWidth + 16)
			local cardY = gridStartY + row * (cardHeight + 16)

			item.card.Visible = true
			Kit.place(item.card, cardX, cardY, cardWidth, cardHeight)

			item.title.Size = UDim2.fromOffset(cardWidth - 110, 24)
			Kit.place(item.deployButton, 20, 214, cardWidth - 40, 38)
		end

		local totalRows = math.ceil(visibleCount / columns)
		local endY = gridStartY + totalRows * (cardHeight + 16)

		if totalPages > 1 then
			placePager(w, endY + 8, pageIndex, totalPages, #matchedCards, "tiers")
			return endY + 68
		end

		return endY + 16
	end)
end

return InterfacePageInfrastructure
