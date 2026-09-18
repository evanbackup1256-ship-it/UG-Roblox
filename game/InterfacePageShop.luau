local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageShop = {}

function InterfacePageShop.build(Shared: InterfaceShared.Shared)
	local Kit, C, Config, Shop = Shared.Kit, Shared.C, Shared.Config, Shared.Shop
	local positionText, liven = Shared.positionText, Shared.liven
	local bind, layoutPage, relayout = Shared.bind, Shared.layoutPage, Shared.relayout
	local fmt = Shared.fmt

	local shopPage = 1

	local offers = {}
	for i, offer in ipairs(Config.ShopOffers) do
		local card = Kit.card(Shared.pages.shop, "Offer_" .. offer.key, 348)

		local stageRoot = Kit.create("Frame", card, {
			Name = "Preview",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 185),
		})
		Shared.director:Add(stageRoot, i, offer.color, true)

		local title = positionText(card, "Title", offer.name, 20, 185, 350, 30, 20, C.text, true)
		local detail = positionText(card, "Detail", offer.subtitle, 20, 222, 350, 34, 13, C.muted)
		detail.TextWrapped = true

		local saving = positionText(
			card,
			"Saving",
			string.format("%d SERVERS  /  %d%% SAVING", offer.quantity, math.floor((offer.discount or 0.05) * 100)),
			20, 262, 300, 20, 10, C.accent, true
		)

		local buy = liven(Kit.button(card, "BuyPackage", "", function()
			Shared.fn.act("buyPackage", offer.key)
		end, true))

		offers[i] = {
			card = card,
			title = title,
			detail = detail,
			saving = saving,
			buy = buy,
		}

		bind("shop", function(s)
			local price, reason = Shop.quote(Config, s, offer.key)
			Kit.enable(
				buy,
				price ~= nil and (s.compute or 0) >= price,
				if price then "Deploy · " .. fmt(price) else reason,
				true
			)
		end)
	end

	local placeShopPager = Shared.pager(Shared.pages.shop, function()
		shopPage = math.max(1, shopPage - 1)
		relayout("shop")
		Shared.fn.revealPageChange("shop")
	end, function()
		shopPage += 1
		relayout("shop")
		Shared.fn.revealPageChange("shop")
	end)

	layoutPage("shop", function(w)
		local columns = if w >= 950 then 3 elseif w >= 640 then 2 else 1
		local cw = (w - (columns - 1) * 16) / columns
		local pageSize = columns * 2
		local totalPages = math.max(1, math.ceil(#offers / pageSize))

		shopPage = math.clamp(shopPage, 1, totalPages)
		local first = (shopPage - 1) * pageSize + 1
		local last = math.min(#offers, first + pageSize - 1)

		for index, item in ipairs(offers) do
			item.card.Visible = index >= first and index <= last
		end

		local shown = 0
		for index = first, last do
			local item = offers[index]

			Kit.place(
				item.card,
				(shown % columns) * (cw + 16),
				137 + (shown // columns) * 364,
				cw,
				348
			)

			item.title.Size = UDim2.fromOffset(cw - 40, 30)
			item.detail.Size = UDim2.fromOffset(cw - 40, 34)
			item.saving.Size = UDim2.fromOffset(cw - 40, 20)
			Kit.place(item.buy, 20, 290, cw - 40, 44)

			shown += 1
		end

		local footerY = 149 + math.ceil(shown / columns) * 364
		placeShopPager(w, footerY, shopPage, totalPages, #offers, "BUNDLES")

		return footerY + 54
	end)
end

return InterfacePageShop
