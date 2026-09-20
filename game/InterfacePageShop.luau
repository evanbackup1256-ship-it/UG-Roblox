--!strict
local InterfaceShared = require(script.Parent.InterfaceShared)
local Fuzzy = require(script.Parent.Fuzzy)

local InterfacePageShop = {}

function InterfacePageShop.build(Shared: InterfaceShared.Shared)
	local Kit = Shared.Kit
	local C = Shared.C
	local Config = Shared.Config
	local Shop = Shared.Shop
	local positionText = Shared.positionText
	local liven = Shared.liven
	local bind = Shared.bind
	local layoutPage = Shared.layoutPage
	local relayout = Shared.relayout
	local connect = Shared.connect
	local fmt = Shared.fmt

	local pageRoot = Shared.pages.shop
	local pageIndex = 1
	local query = ""

	local searchInput = Kit.input(pageRoot, "ShopSearch", "Search hardware packages…")

	local offerCards = {}
	for i, offer in ipairs(Config.ShopOffers) do
		local card = Kit.interactiveCard(pageRoot, "Offer_" .. offer.key, 330, C.panel)

		local stageRoot = Kit.create("Frame", card, {
			Name = "PreviewStage",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 175),
		})
		Shared.director:Add(stageRoot, i, offer.color, true)

		local discountPct = math.floor((offer.discount or 0.05) * 100)
		local discountBadge = Kit.badge(card, string.format("Save %d%%", discountPct), "compute", true)
		Kit.place(discountBadge, 18, 16, 76, 20)

		local title = positionText(card, "Title", offer.name, 20, 180, 350, 26, 17, C.text, true)
		local detail = positionText(card, "Detail", offer.subtitle, 20, 208, 350, 32, 12, C.textSub)
		detail.TextWrapped = true

		local savingsLabel = positionText(
			card,
			"Savings",
			string.format("%d units · %d%% bundle savings", offer.quantity, discountPct),
			20,
			244,
			300,
			20,
			11,
			C.accent,
			true
		)
		savingsLabel.Font = Enum.Font.RobotoMono

		local buyBtn = liven(Kit.button(card, "BuyPackage", "Connecting…", function()
			Kit.fanfare(card, offer.color or C.gold)
			Kit.floatText(card, string.format("+%d UNITS", offer.quantity), offer.color or C.gold, Vector2.new(0.5, 0.45))
			Shared.fn.act("buyPackage", offer.key)
		end, "primary"))

		offerCards[i] = {
			card = card,
			offer = offer,
			title = title,
			detail = detail,
			savingsLabel = savingsLabel,
			buyBtn = buyBtn,
			searchString = string.lower(offer.name .. " " .. (offer.subtitle or "")),
		}

		bind("shop", function(s)
			local price, reason = Shop.quote(Config, s, offer.key)
			Kit.enable(
				buyBtn,
				price ~= nil and (s.compute or 0) >= price,
				if price then "Procure · " .. fmt(price) else reason,
				true
			)
		end)
	end

	local emptyLabel = positionText(pageRoot, "Empty", "No procurement packages match your search.", 0, 0, 600, 44, 14, C.muted)
	emptyLabel.TextWrapped = true
	emptyLabel.Visible = false

	local placePager = Shared.pager(pageRoot, function()
		pageIndex = math.max(1, pageIndex - 1)
		relayout("shop")
		Shared.fn.revealPageChange("shop")
	end, function()
		pageIndex += 1
		relayout("shop")
		Shared.fn.revealPageChange("shop")
	end)

	connect(searchInput:GetPropertyChangedSignal("Text"), function()
		local clean = string.lower(searchInput.Text)
		if clean == query then return end
		query = clean
		pageIndex = 1
		relayout("shop")
	end)

	-- =========================================================================
	-- RESPONSIVE LAYOUT
	-- =========================================================================
	layoutPage("shop", function(w)
		Kit.place(searchInput, 0, 137, w, 40)

		local matchedCards = {}
		for _, item in ipairs(offerCards) do
			if query == "" or Fuzzy.score(query, item.searchString) > 0 then
				table.insert(matchedCards, item)
			end
		end

		for _, item in ipairs(offerCards) do
			item.card.Visible = false
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
		local cardHeight = 330

		local perPage = columns * 3
		local totalPages = math.max(1, math.ceil(#matchedCards / perPage))
		pageIndex = math.clamp(pageIndex, 1, totalPages)

		local pageStart = (pageIndex - 1) * perPage + 1
		local pageEnd = math.min(#matchedCards, pageIndex * perPage)
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

			item.title.Size = UDim2.fromOffset(cardWidth - 40, 26)
			item.detail.Size = UDim2.fromOffset(cardWidth - 40, 32)
			Kit.place(item.buyBtn, 20, 274, cardWidth - 40, 40)
		end

		local totalRows = math.ceil(visibleCount / columns)
		local endY = gridStartY + totalRows * (cardHeight + 16)

		if totalPages > 1 then
			placePager(w, endY + 8, pageIndex, totalPages, #matchedCards, "packages")
			return endY + 68
		end

		return endY + 16
	end)
end

return InterfacePageShop
