--!strict
local InterfaceShared = require(script.Parent.InterfaceShared)
local Fuzzy = require(script.Parent.Fuzzy)

local InterfacePageResearch = {}

function InterfacePageResearch.build(Shared: InterfaceShared.Shared)
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
	local preferences = Shared.preferences
	local Tokens = Shared.Tokens

	local pageRoot = Shared.pages.research
	local pageIndex = 1
	local query = ""

	-- =========================================================================
	-- 1. TOP SEARCH TOOLBAR
	-- =========================================================================
	local searchInput = Kit.input(pageRoot, "ResearchSearch", "Search technological upgrades…")

	-- =========================================================================
	-- 2. SYNERGY MATRIX HUD CARD
	-- =========================================================================
	local function calculateSynergyHeight()
		return 84 + (#Config.Synergies - 1) * 42 + 36
	end

	local synergyCard = Kit.card(pageRoot, "SynergyMatrix", calculateSynergyHeight(), C.panel)

	local eyebrow = positionText(synergyCard, "Eyebrow", "Synergy Network", 22, 16, 260, 20, 11, C.textSub, true)

	local synergyBadge = Kit.badge(synergyCard, "Active", "accent", true)
	Kit.place(synergyBadge, 220, 16, 70, 20)

	local synergyTotal = positionText(synergyCard, "Total", "+0% production active", 22, 38, 450, 30, 20, C.accent, true)
	synergyTotal.Font = Enum.Font.RobotoMono
	local bumpSynergy = bump(synergyTotal)

	local synergyRows = {}
	for index, syn in ipairs(Config.Synergies) do
		local rowY = 82 + (index - 1) * 42

		local iconShell = Kit.create("Frame", synergyCard, {
			Name = "Shell_" .. syn.key,
			Position = UDim2.fromOffset(22, rowY),
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = C.raised,
			BorderSizePixel = 0,
		})
		Kit.corner(iconShell, Kit.radius.control)

		local icon = Kit.icon(iconShell, "Icon", syn.icon or "research", C.muted)
		Kit.place(icon, 4, 4, 20, 20)

		local name = positionText(synergyCard, "Name_" .. syn.key, syn.name, 60, rowY - 1, 280, 18, 12, C.text, true)
		local desc = positionText(synergyCard, "Desc_" .. syn.key, syn.description, 60, rowY + 16, 700, 16, 11, C.muted)
		desc.TextWrapped = true
		desc.TextTruncate = Enum.TextTruncate.AtEnd

		synergyRows[index] = {
			synergy = syn,
			iconShell = iconShell,
			icon = icon,
			name = name,
			desc = desc,
			active = false,
			bumpName = bump(name),
		}
	end

	-- =========================================================================
	-- 3. RESEARCH UPGRADE CARDS
	-- =========================================================================
	local researchCards = {}
	for index, item in ipairs(Config.Research) do
		local card = Kit.interactiveCard(pageRoot, "Research_" .. item.key, 215, C.panel)

		Kit.place(Kit.icon(card, "Icon", item.icon or "research", C.accent), 20, 20, 22, 22)

		local title = positionText(card, "Title", item.name, 52, 18, 360, 26, 16, C.text, true)
		title.TextWrapped = true

		local detail = positionText(card, "Detail", item.subtitle, 20, 52, 400, 44, 12, C.textSub)
		detail.TextWrapped = true

		local levelLabel = positionText(card, "Level", "Tier 0 / 5", 20, 104, 300, 20, 11, C.accent, true)
		levelLabel.Font = Enum.Font.RobotoMono

		local progressBar = Kit.progressBar(card, "ProgressBar", 6, C.accent)

		local researchBtn = liven(Kit.button(card, "Research", "Connecting…", function()
			Kit.floatText(card, "+1 " .. item.name, C.accent, Vector2.new(0.5, 0.45))
			Shared.fn.act("research", item.key)
		end, "primary"))

		researchCards[index] = {
			card = card,
			item = item,
			title = title,
			detail = detail,
			levelLabel = levelLabel,
			progressBar = progressBar,
			researchBtn = researchBtn,
			searchString = string.lower(item.name .. " " .. (item.subtitle or "")),
		}
	end

	local emptyLabel = positionText(pageRoot, "Empty", "No technological research matches your search.", 0, 0, 600, 44, 14, C.muted)
	emptyLabel.TextWrapped = true
	emptyLabel.Visible = false

	local placePager = Shared.pager(pageRoot, function()
		pageIndex = math.max(1, pageIndex - 1)
		relayout("research")
		Shared.fn.revealPageChange("research")
	end, function()
		pageIndex += 1
		relayout("research")
		Shared.fn.revealPageChange("research")
	end)

	connect(searchInput:GetPropertyChangedSignal("Text"), function()
		local clean = string.lower(searchInput.Text)
		if clean == query then return end
		query = clean
		pageIndex = 1
		relayout("research")
	end)

	-- =========================================================================
	-- 4. STATE BINDING
	-- =========================================================================
	bind("research", function(s)
		-- 1. Sync Synergies
		local status = s.synergyStatus or {}
		local bonus = s.synergyBonus or 0
		local bonusText = "+" .. math.floor(bonus * 100) .. "% production active"

		if bonusText ~= synergyTotal.Text then
			synergyTotal.Text = bonusText
			bumpSynergy()
		end

		for _, row in ipairs(synergyRows) do
			local isActive = status[row.synergy.key] == true
			if isActive ~= row.active then
				row.active = isActive
				Kit.animate(
					row.iconShell,
					{ BackgroundColor3 = if isActive then C.accent2 else C.raised },
					0.18,
					Enum.EasingStyle.Quad
				)
				Kit.tintIcon(row.icon, if isActive then C.ink else C.muted)
				row.name.TextColor3 = if isActive then C.accent else C.text

				if isActive then
					row.bumpName()
					if preferences.particles ~= false then
						Kit.confetti(row.iconShell, C.accent2)
					end
				end
			end
		end

		-- 2. Sync Research Upgrades
		local researchLevels = s.research or {}
		local compute = s.compute or 0

		for _, rc in ipairs(researchCards) do
			local curLevel = researchLevels[rc.item.key] or 0
			local cost = Config.researchCost(rc.item, curLevel, s)
			local isMax = curLevel >= rc.item.max
			local progressRatio = math.clamp(curLevel / rc.item.max, 0, 1)

			rc.levelLabel.Text = string.format("Tier %d / %d", curLevel, rc.item.max)
			rc.progressBar:SetProgress(progressRatio, true)

			Kit.enable(
				rc.researchBtn,
				not isMax and compute >= cost,
				if isMax then "Researched" else "Upgrade · " .. fmt(cost),
				true
			)
		end

		relayout("research")
	end)

	-- =========================================================================
	-- 5. RESPONSIVE LAYOUT
	-- =========================================================================
	layoutPage("research", function(w)
		local narrow = w < 680

		Kit.place(searchInput, 0, 137, w, 40)

		local synHeight = calculateSynergyHeight()
		Kit.place(synergyCard, 0, 189, w, synHeight)

		local matchedCards = {}
		for _, rc in ipairs(researchCards) do
			if query == "" or Fuzzy.score(query, rc.searchString) > 0 then
				table.insert(matchedCards, rc)
			end
		end

		for _, rc in ipairs(researchCards) do
			rc.card.Visible = false
		end

		local gridStartY = 189 + synHeight + 16

		if #matchedCards == 0 then
			emptyLabel.Visible = true
			Kit.place(emptyLabel, 0, gridStartY + 40, w, 44)
			return gridStartY + 120
		else
			emptyLabel.Visible = false
		end

		local columns = if w >= 900 then 2 else 1
		local cardWidth = (w - (columns - 1) * 16) / columns
		local cardHeight = 215

		local perPage = columns * 6
		local totalPages = math.max(1, math.ceil(#matchedCards / perPage))
		pageIndex = math.clamp(pageIndex, 1, totalPages)

		local pageStart = (pageIndex - 1) * perPage + 1
		local pageEnd = math.min(#matchedCards, pageIndex * perPage)
		local visibleCount = pageEnd - pageStart + 1

		for idx = pageStart, pageEnd do
			local rc = matchedCards[idx]
			local localIdx = idx - pageStart
			local col = localIdx % columns
			local row = localIdx // columns

			local cardX = col * (cardWidth + 16)
			local cardY = gridStartY + row * (cardHeight + 16)

			rc.card.Visible = true
			Kit.place(rc.card, cardX, cardY, cardWidth, cardHeight)

			rc.title.Size = UDim2.fromOffset(cardWidth - 80, 26)
			rc.detail.Size = UDim2.fromOffset(cardWidth - 40, 44)
			Kit.place(rc.progressBar.instance, 20, 134, cardWidth - 40, 6)
			Kit.place(rc.researchBtn, 20, 156, cardWidth - 40, 40)
		end

		local totalRows = math.ceil(visibleCount / columns)
		local endY = gridStartY + totalRows * (cardHeight + 16)

		if totalPages > 1 then
			placePager(w, endY + 8, pageIndex, totalPages, #matchedCards, "upgrades")
			return endY + 68
		end

		return endY + 16
	end)
end

return InterfacePageResearch
