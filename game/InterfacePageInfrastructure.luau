local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageInfrastructure = {}

function InterfacePageInfrastructure.build(Shared: InterfaceShared.Shared)
	local Kit, C, Config = Shared.Kit, Shared.C, Shared.Config
	local positionText, liven = Shared.positionText, Shared.liven
	local bind, layoutPage, relayout = Shared.bind, Shared.layoutPage, Shared.relayout
	local own, connect = Shared.own, Shared.connect
	local fmt = Shared.fmt

	-- Page-local UI/filter state. query/filter/infrastructurePage are read
	-- nowhere outside this module. quantity also drives this module's own
	-- button text, but act()'s "buy" branch (in the orchestrator, defined
	-- before this page builds) needs the current selection at click time,
	-- so it's mirrored onto Shared.quantity everywhere it changes below.
	local quantity = 1
	local query = ""
	local filter = "all"
	local infrastructurePage = 1

	local search = Kit.input(Shared.pages.infrastructure, "Search", "Search infrastructure…")

	local filterButton = Kit.button(Shared.pages.infrastructure, "Filter", "All hardware", function()
		filter = if filter == "all" then "unlocked" elseif filter == "unlocked" then "owned" else "all"
		infrastructurePage = 1
		Kit.sound("slider")
		if Shared.state then
			Shared.fn.apply(Shared.state)
		end
	end)

	local placeInfrastructurePager = Shared.pager(Shared.pages.infrastructure, function()
		infrastructurePage = math.max(1, infrastructurePage - 1)
		relayout("infrastructure")
		Shared.fn.revealPageChange("infrastructure")
	end, function()
		infrastructurePage += 1
		relayout("infrastructure")
		Shared.fn.revealPageChange("infrastructure")
	end)

	local quantityButton = Kit.button(Shared.pages.infrastructure, "Quantity", "Buy ×1", function()
		quantity = if quantity == 1 then 5 elseif quantity == 5 then 10 else 1
		Shared.quantity = quantity
		Kit.sound("slider")
		if Shared.state then
			Shared.fn.apply(Shared.state)
		end
	end)

	local tierCards = {}
	for index, tier in ipairs(Config.Tiers) do
		local card = Kit.card(Shared.pages.infrastructure, "Tier_" .. tier.key, 272)

		Kit.place(Kit.icon(card, "Icon", tier.icon or "infrastructure", tier.color), 20, 20, 24, 24)

		local name = positionText(card, "Title", tier.name, 56, 18, 230, 27, 17, C.text, true)
		local ownedLabel = positionText(card, "Owned", "0 owned", 20, 51, 150, 22, 12, C.muted)

		local stageRoot = Kit.create("Frame", card, {
			Name = "Preview",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 72),
			Size = UDim2.new(1, 0, 0, 110),
		})
		Shared.director:Add(stageRoot, index, tier.color)

		local output = positionText(card, "Output", "+" .. fmt(tier.rate) .. " /s each", 20, 184, 230, 22, 13, tier.color, true)

		local buy = liven(Kit.button(card, "Deploy", "Connecting…", function()
			Shared.fn.act("buy", tier.key)
		end, "primary"))

		tierCards[index] = {
			card = card,
			tier = tier,
			search = string.lower(tier.name),
			name = name,
			buy = buy,
			owned = ownedLabel,
			output = output,
		}
	end

	local empty = positionText(Shared.pages.infrastructure, "Empty", "No hardware matches your search.", 0, 0, 600, 44, 16, C.muted)
	empty.TextWrapped = true
	empty.Visible = false
	local emptyShown = false

	local tierMatches = {}

	layoutPage("infrastructure", function(w)
		local columns = math.clamp((w + 16) // 300, 1, 3)
		local cw = (w - (columns - 1) * 16) / columns
		local narrow = w < 550
		local toolbarHeight = if narrow then 104 else 52

		Kit.place(search, 0, 135, if narrow then w else w - 284, 44)
		Kit.place(filterButton, if narrow then 0 else w - 272, if narrow then 187 else 135, math.min(150, w - 122), 44)
		Kit.place(quantityButton, w - 110, if narrow then 187 else 135, 110, 44)

		table.clear(tierMatches)
		for _, item in ipairs(tierCards) do
			item.card.Visible = false

			if string.find(item.search, query, 1, true) then
				local unlocked = not Shared.state or (Shared.state.units or 0) >= item.tier.unlock
				local count = if Shared.state then Shared.state.owned[item.tier.key] or 0 else 0

				if filter == "all"
					or (filter == "owned" and count > 0)
					or (filter == "unlocked" and unlocked)
				then
					table.insert(tierMatches, item)
				end
			end
		end

		local pageSize = columns * 3
		local totalPages = math.max(1, math.ceil(#tierMatches / pageSize))
		infrastructurePage = math.clamp(infrastructurePage, 1, totalPages)

		local first = (infrastructurePage - 1) * pageSize + 1
		local shown = 0

		for index = first, math.min(#tierMatches, first + pageSize - 1) do
			local item = tierMatches[index]
			item.card.Visible = true
			Kit.place(
				item.card,
				(shown % columns) * (cw + 16),
				147 + toolbarHeight + (shown // columns) * 288,
				cw,
				272
			)
			item.name.Size = UDim2.fromOffset(cw - 76, 27)
			item.output.Size = UDim2.fromOffset(cw - 40, 22)
			Kit.place(item.buy, 20, 218, cw - 40, 44)
			shown += 1
		end

		-- Sits at the same top edge card content would start at, so it never
		-- drifts independently of the toolbar height (narrow layouts stack
		-- the search/filter/quantity controls onto 2 rows, which pushes
		-- this down along with everything else) or overlaps whatever comes
		-- after it — previously this had a hardcoded Y that only matched
		-- toolbarHeight by coincidence at one specific window width.
		local emptyY = 147 + toolbarHeight
		Kit.place(empty, 0, emptyY, w, 44)

		local shouldShowEmpty = #tierMatches == 0
		if shouldShowEmpty ~= emptyShown then
			emptyShown = shouldShowEmpty
			if shouldShowEmpty then
				empty.Visible = true
				empty.TextTransparency = 1
				Kit.animate(empty, { TextTransparency = 0 }, 0.2)
			else
				Kit.animate(empty, { TextTransparency = 1 }, 0.2)
				Kit.Scheduler.after(empty, "hide", 0.2, function()
					if not emptyShown then
						empty.Visible = false
					end
				end)
			end
		end

		-- When there are zero results, leave room below the empty-state
		-- message instead of collapsing straight back to the toolbar's
		-- bottom edge (that's what put the pager right on top of the
		-- "No hardware matches" text at 0 results).
		local contentBottom = if shouldShowEmpty
			then emptyY + 60
			else 147 + toolbarHeight + math.ceil(shown / columns) * 288

		local footerY = contentBottom + 16
		placeInfrastructurePager(w, footerY, infrastructurePage, totalPages, #tierMatches, "RESULTS")

		return footerY + 54
	end)

	own(function()
		table.clear(tierMatches)
	end)

	connect(search:GetPropertyChangedSignal("Text"), function()
		local nextQuery = string.lower(search.Text)
		if nextQuery == query then
			return
		end
		query = nextQuery
		infrastructurePage = 1
		relayout("infrastructure")
	end)

	bind("infrastructure", function(s)
		filterButton.Text = if filter == "all" then "All hardware" elseif filter == "owned" then "Owned" else "Unlocked"
		quantityButton.Text = "Buy ×" .. quantity

		local units = s.units or 0
		local compute = s.compute or 0

		for _, item in ipairs(tierCards) do
			local n = s.owned[item.tier.key] or 0
			local cost = Config.buyCost(item.tier, n, s)
			local unlocked = units >= item.tier.unlock

			item.owned.Text = n .. " owned"

			Kit.lock(item.card, not unlocked, item.buy)

			Kit.enable(
				item.buy,
				unlocked and n < 200 and compute >= cost,
				if n >= 200 then "At capacity"
					elseif not unlocked then item.tier.unlock .. " units to unlock"
					elseif quantity > 1 then "Up to ×" .. quantity .. " · " .. fmt(cost) .. "/ea"
					else "Deploy · " .. fmt(cost),
				true
			)
		end

		relayout("infrastructure")
	end)
end

return InterfacePageInfrastructure
