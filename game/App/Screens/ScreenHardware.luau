--!strict
-- ScreenHardware: Infrastructure hardware procurement rack grid
local AppContext = require(script.Parent.Parent.AppContext)
local Fuzzy = require(script.Parent.Parent.Parent.Fuzzy)

local ScreenHardware = {}

function ScreenHardware.build(ctx: AppContext.Context)
	local Elements = ctx.Elements
	local Buttons = ctx.Buttons
	local Inputs = ctx.Inputs
	local Feedback = ctx.Feedback
	local C = ctx.C
	local Config = ctx.Config
	local fmt = ctx.fmt

	local root = ctx.screens.infrastructure
	local quantity = 1
	local query = ""
	local filterMode = "all"
	local pageIndex = 1
	local updateCards: ((s: any) -> ())? = nil

	-- =========================================================================
	-- 1. SEARCH & CONTROL SEGMENTS
	-- =========================================================================
	local searchInput = Inputs.input(root, "HardwareSearch", "Search hardware tiers…", function(q)
		query = q
		pageIndex = 1
		ctx.relayout("infrastructure")
	end)

	local filterSegment = Inputs.segmented(
		root,
		"FilterSegment",
		{ "All Units", "Deployed", "Available" },
		1,
		function(idx)
			filterMode = if idx == 2 then "owned" elseif idx == 3 then "unlocked" else "all"
			pageIndex = 1
			ctx.relayout("infrastructure")
		end
	)

	local quantitySegment = Inputs.segmented(
		root,
		"QuantitySegment",
		{ "×1", "×5", "×10" },
		1,
		function(idx)
			quantity = if idx == 2 then 5 elseif idx == 3 then 10 else 1
			ctx.quantity = quantity
			if updateCards and ctx.state then
				updateCards(ctx.state)
			end
		end
	)

	-- =========================================================================
	-- 2. TIER CARDS
	-- =========================================================================
	local tierCards = {}
	for i, tier in ipairs(Config.Tiers) do
		local card = Elements.interactiveCard(root, "Tier_" .. tier.key, 140, C.card)

		local orderBadge = Elements.badge(card, string.format("Tier %02d", i), "accent", true)
		Elements.place(orderBadge, 20, 18, 68, 22)

		-- Rare/apex hardware tier shimmer
		if i >= 5 or i >= #Config.Tiers - 2 then

		end

		local title = Elements.text(card, "Title", tier.name, 16, C.textPrimary, true)
		Elements.place(title, 96, 18, 240, 22)

		local countLabel = Elements.text(card, "Count", "0 Active", 12, C.textMuted, true)
		countLabel.TextXAlignment = Enum.TextXAlignment.Right
		Elements.place(countLabel, 340, 18, 120, 22)

		local rateLabel = Elements.text(card, "Rate", "+" .. fmt(tier.rate) .. "/s", 13, C.compute, true)
		Elements.place(rateLabel, 20, 48, 200, 20)

		local detail = Elements.text(card, "Detail", tier.subtitle or "Server array compute node", 13, C.textSecondary)
		detail.TextWrapped = true
		Elements.place(detail, 20, 70, 320, 24)

		local deployBtn = Buttons.button(card, "Deploy", "Purchase", function()
			if ctx.state then
				Feedback.floatText(card, "+Purchase", C.accent, UDim2.fromScale(0.85, 0.45))
			end
			ctx.act("buy", tier.key, quantity)
		end, "primary")
		Elements.place(deployBtn, 20, 96, 120, 36)

		tierCards[i] = {
			tier = tier,
			card = card,
			title = title,
			countLabel = countLabel,
			rateLabel = rateLabel,
			detail = detail,
			deployBtn = deployBtn,
			searchString = string.lower(tier.name .. " " .. (tier.subtitle or "")),
		}
	end

	local emptyLabel = Elements.text(root, "Empty", "No hardware modules match your search filter.", 14, C.textMuted)
	emptyLabel.TextWrapped = true
	emptyLabel.Visible = false

	local function calcBuyCost(tier: any, currentOwned: number, qty: number, state: any): number
		local amount = (qty == 5 or qty == 10) and qty or 1
		local total = 0
		for step = 0, amount - 1 do
			if (currentOwned + step) < 200 then
				total += Config.buyCost(tier, currentOwned + step, state)
			end
		end
		return total
	end

	updateCards = function(s: any)
		if not s then return end
		local owned = s.owned or {}
		local compute = s.compute or 0

		for _, item in ipairs(tierCards) do
			local count = owned[item.tier.key] or 0
			local cost = calcBuyCost(item.tier, count, quantity, s)
			local canAfford = compute >= cost and count < 200

			item.countLabel.Text = string.format("%d Active", count)
			item.rateLabel.Text = string.format("+%s/s", fmt(item.tier.rate * (count > 0 and count or 1)))

			local btnLabel = if count >= 200 then "Max Capacity"
				elseif quantity > 1 then string.format("Purchase ×%d · %s", quantity, fmt(cost))
				else string.format("Purchase · %s", fmt(cost))

			Buttons.enable(
				item.deployBtn,
				canAfford,
				btnLabel,
				true
			)
		end
	end

	-- =========================================================================
	-- 3. STATE BINDING
	-- =========================================================================
	ctx.bind("infrastructure", updateCards)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	ctx.layoutScreen("infrastructure", function(w)
		local compact = w < 440
		local narrow = w < 680

		if compact then
			Elements.place(searchInput, 0, 0, w, 38)
			Elements.place(filterSegment.instance, 0, 46, w, 36)
			Elements.place(quantitySegment.instance, 0, 90, w, 36)
		elseif narrow then
			Elements.place(searchInput, 0, 0, w, 38)
			Elements.place(filterSegment.instance, 0, 48, w - 120, 36)
			Elements.place(quantitySegment.instance, w - 110, 48, 110, 36)
		else
			Elements.place(searchInput, 0, 0, w - 380, 38)
			Elements.place(filterSegment.instance, w - 370, 0, 240, 38)
			Elements.place(quantitySegment.instance, w - 120, 0, 120, 38)
		end

		local matchedCards = {}
		local s = ctx.state or {}
		local owned = s.owned or {}

		for _, item in ipairs(tierCards) do
			local count = owned[item.tier.key] or 0
			local passesFilter = true
			if filterMode == "owned" and count <= 0 then
				passesFilter = false
			elseif filterMode == "unlocked" and count > 0 then
				passesFilter = false
			end

			if passesFilter and (query == "" or (Fuzzy.score(query, item.searchString) or 0) > 0) then
				table.insert(matchedCards, item)
			end
		end

		for _, item in ipairs(tierCards) do
			item.card.Visible = false
		end

		local gridStartY = if compact then 136 elseif narrow then 96 else 54

		if #matchedCards == 0 then
			emptyLabel.Visible = true
			Elements.place(emptyLabel, 0, gridStartY + 40, w, 40)
			return gridStartY + 100
		else
			emptyLabel.Visible = false
		end

		local cols = if w >= 860 then 2 else 1
		local cardW = math.floor((w - (cols - 1) * 16) / cols)
		local cardH = 152

		for idx, item in ipairs(matchedCards) do
			local localIdx = idx - 1
			local col = localIdx % cols
			local row = localIdx // cols
			local cx = col * (cardW + 16)
			local cy = gridStartY + row * (cardH + 16)

			item.card.Visible = true
			Elements.place(item.card, cx, cy, cardW, cardH)

			local titleW = math.max(60, cardW - 96 - 150)
			item.title.Position = UDim2.fromOffset(96, 18)
			item.title.Size = UDim2.fromOffset(titleW, 22)
			item.title.TextTruncate = Enum.TextTruncate.AtEnd

			item.countLabel.AnchorPoint = Vector2.new(1, 0)
			item.countLabel.Position = UDim2.new(1, -20, 0, 18)
			item.countLabel.Size = UDim2.fromOffset(120, 22)

			item.rateLabel.Position = UDim2.fromOffset(20, 48)
			item.rateLabel.Size = UDim2.fromOffset(cardW - 40, 20)

			item.detail.Position = UDim2.fromOffset(20, 72)
			item.detail.Size = UDim2.fromOffset(cardW - 40, 24)

			Elements.place(item.deployBtn, 20, 102, cardW - 40, 38)
		end

		local totalRows = math.ceil(#matchedCards / cols)
		return gridStartY + totalRows * (cardH + 16) + 32
	end)
end

return ScreenHardware

