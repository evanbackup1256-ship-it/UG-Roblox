--!strict
-- ScreenMarket: Hardware procurement store with 3D staging viewports
local AppContext = require(script.Parent.Parent.AppContext)
local Fuzzy = require(script.Parent.Parent.Parent.Fuzzy)

local ScreenMarket = {}

function ScreenMarket.build(ctx: AppContext.Context)
	local Elements = ctx.Elements
	local Buttons = ctx.Buttons
	local Inputs = ctx.Inputs
	local Feedback = ctx.Feedback
	local C = ctx.C
	local Config = ctx.Config
	local Shop = ctx.Shop
	local fmt = ctx.fmt

	local root = ctx.screens.shop
	local query = ""

	local searchInput = Inputs.input(root, "ShopSearch", "Search hardware packages…", function(q)
		query = q
		ctx.relayout("shop")
	end)

	local offerCards = {}
	for i, offer in ipairs(Config.ShopOffers) do
		local card = Elements.interactiveCard(root, "Offer_" .. offer.key, 310, C.card)

		local stageRoot = Elements.create("Frame", card, {
			Name = "PreviewStage",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 160),
			ClipsDescendants = true,
		})
		if ctx.director then
			ctx.director:Add(stageRoot, i, offer.color, true)
		end


		local discountPct = math.floor((offer.discount or 0.05) * 100)
		local discountBadge = Elements.badge(card, string.format("Save %d%%", discountPct), "compute", true)
		Elements.place(discountBadge, 18, 16, 76, 22)

		local title = Elements.text(card, "Title", offer.name, 17, C.textPrimary, true)
		Elements.place(title, 20, 168, 300, 24)

		local detail = Elements.text(card, "Detail", offer.subtitle or "Pre-assembled server bundle", 12, C.textSecondary)
		detail.TextWrapped = true
		Elements.place(detail, 20, 194, 300, 30)

		local savingsLabel = Elements.text(
			card,
			"Savings",
			string.format("%d units · %d%% bundle savings", offer.quantity, discountPct),
			11,
			C.accent,
			true
		)
		savingsLabel.Font = ctx.Theme.typography.fontMono
		Elements.place(savingsLabel, 20, 226, 280, 20)

		local buyBtn = Buttons.button(card, "BuyPackage", "Procure", function()
			Feedback.confetti(card, offer.color or C.gold)
			Feedback.floatText(card, string.format("+%d UNITS", offer.quantity), offer.color or C.gold, UDim2.fromScale(0.5, 0.45))
			ctx.act("buyPackage", offer.key)
		end, "primary")
		Elements.place(buyBtn, 20, 252, 140, 42)

		offerCards[i] = {
			card = card,
			offer = offer,
			title = title,
			detail = detail,
			savingsLabel = savingsLabel,
			buyBtn = buyBtn,
			searchString = string.lower(offer.name .. " " .. (offer.subtitle or "")),
		}
	end

	local emptyLabel = Elements.text(root, "Empty", "No procurement packages match your search.", 14, C.textMuted)
	emptyLabel.TextWrapped = true
	emptyLabel.Visible = false

	-- =========================================================================
	-- 2. STATE BINDING
	-- =========================================================================
	ctx.bind("shop", function(s)
		for _, item in ipairs(offerCards) do
			local price, reason = Shop.quote(Config, s, item.offer.key)
			local canAfford = price ~= nil and (s.compute or 0) >= price

			Buttons.enable(
				item.buyBtn,
				canAfford,
				if price then "Procure · " .. fmt(price) else reason,
				true
			)
		end
	end)

	-- =========================================================================
	-- 3. RESPONSIVE LAYOUT
	-- =========================================================================
	ctx.layoutScreen("shop", function(w)
		Elements.place(searchInput, 0, 0, w, 38)
		local gridStartY = 48

		local matchedCards = {}
		for _, item in ipairs(offerCards) do
			if query == "" or (Fuzzy.score(query, item.searchString) or 0) > 0 then
				table.insert(matchedCards, item)
			end
		end

		for _, item in ipairs(offerCards) do
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
		local cardH = 304

		for idx, item in ipairs(matchedCards) do
			local localIdx = idx - 1
			local col = localIdx % cols
			local row = localIdx // cols
			local cx = col * (cardW + 16)
			local cy = gridStartY + row * (cardH + 16)

			item.card.Visible = true
			Elements.place(item.card, cx, cy, cardW, cardH)

			item.title.Position = UDim2.fromOffset(20, 168)
			item.title.Size = UDim2.fromOffset(cardW - 40, 22)
			item.detail.Position = UDim2.fromOffset(20, 192)
			item.detail.Size = UDim2.fromOffset(cardW - 40, 28)
			Elements.place(item.savingsLabel, 20, 222, cardW - 40, 20)
			Elements.place(item.buyBtn, 20, 248, math.min(220, cardW - 40), 42)
		end

		local totalRows = math.ceil(#matchedCards / cols)
		return gridStartY + totalRows * (cardH + 16) + 32
	end)
end

return ScreenMarket

