--!strict
-- ScreenResearch: Technological upgrades tree and synergy network matrix
local AppContext = require(script.Parent.Parent.AppContext)
local Fuzzy = require(script.Parent.Parent.Parent.Fuzzy)

local ScreenResearch = {}

function ScreenResearch.build(ctx: AppContext.Context)
	local Elements = ctx.Elements
	local Buttons = ctx.Buttons
	local Inputs = ctx.Inputs
	local Feedback = ctx.Feedback
	local Springs = ctx.Springs
	local C = ctx.C
	local Config = ctx.Config
	local fmt = ctx.fmt

	local root = ctx.screens.research
	local query = ""

	local searchInput = Inputs.input(root, "ResearchSearch", "Search technological upgrades…", function(q)
		query = q
		ctx.relayout("research")
	end)

	-- =========================================================================
	-- 1. SYNERGY MATRIX HUD
	-- =========================================================================
	local function getSynergyHeight()
		return 84 + (#Config.Synergies - 1) * 42 + 36
	end

	local synergyCard = Elements.card(root, "SynergyMatrix", getSynergyHeight(), C.card)


	local eyebrow = Elements.text(synergyCard, "Eyebrow", "SYNERGY NETWORK", 11, C.textSecondary, true)
	eyebrow.Font = ctx.Theme.typography.fontMono
	Elements.place(eyebrow, 22, 16, 150, 20)

	local synergyBadge = Elements.badge(synergyCard, "Active", "accent", true)
	synergyBadge.AnchorPoint = Vector2.new(1, 0)
	synergyBadge.Position = UDim2.new(1, -22, 0, 16)

	local synergyTotal = Elements.text(synergyCard, "Total", "+0% production active", 20, C.accent, true)
	synergyTotal.Font = ctx.Theme.typography.fontMono
	Elements.place(synergyTotal, 22, 38, 300, 30)
	local bumpSynergy = Feedback.bump(synergyTotal)

	local synergyRows = {}
	for index, syn in ipairs(Config.Synergies) do
		local rowY = 82 + (index - 1) * 42

		local iconShell = Elements.create("Frame", synergyCard, {
			Name = "Shell_" .. syn.key,
			Position = UDim2.fromOffset(22, rowY),
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = C.recessed,
			BorderSizePixel = 0,
		})
		Elements.corner(iconShell, ctx.Theme.radii.control)

		local icon = Elements.icon(iconShell, "Icon", syn.icon or "research", C.textMuted)
		Elements.place(icon, 4, 4, 20, 20)

		local name = Elements.text(synergyCard, "Name_" .. syn.key, syn.name, 13, C.textPrimary, true)
		Elements.place(name, 60, rowY, 260, 18)

		local desc = Elements.text(synergyCard, "Desc_" .. syn.key, syn.description, 11, C.textMuted)
		desc.TextTruncate = Enum.TextTruncate.AtEnd
		Elements.place(desc, 60, rowY + 18, 500, 16)

		synergyRows[index] = {
			synergy = syn,
			iconShell = iconShell,
			icon = icon,
			name = name,
			desc = desc,
			active = false,
			bumpName = Feedback.bump(name),
		}
	end

	-- =========================================================================
	-- 2. RESEARCH CARDS
	-- =========================================================================
	local researchCards = {}
	for index, item in ipairs(Config.Research) do
		local card = Elements.interactiveCard(root, "Research_" .. item.key, 190, C.card)

		local icon = Elements.icon(card, "Icon", item.icon or "research", C.accent)
		Elements.place(icon, 20, 18, 22, 22)

		if index >= #Config.Research - 1 then

		end

		local title = Elements.text(card, "Title", item.name, 15, C.textPrimary, true)
		Elements.place(title, 50, 18, 240, 22)

		local levelLabel = Elements.text(card, "Level", "Tier 0 / 5", 11, C.accent, true)
		levelLabel.Font = ctx.Theme.typography.fontMono
		levelLabel.AnchorPoint = Vector2.new(1, 0)
		levelLabel.TextXAlignment = Enum.TextXAlignment.Right
		levelLabel.Position = UDim2.new(1, -20, 0, 18)
		levelLabel.Size = UDim2.fromOffset(90, 20)

		local detail = Elements.text(card, "Detail", item.subtitle or "System firmware optimization", 12, C.textSecondary)
		detail.TextWrapped = true
		Elements.place(detail, 20, 48, 340, 36)

		local progressBar = Inputs.progressBar(card, "Progress", 6, C.accent)
		Elements.place(progressBar.instance, 20, 94, 300, 6)

		local upgradeBtn = Buttons.button(card, "Upgrade", "Upgrade", function()
			if ctx.state then
				Feedback.floatText(card, "+1 " .. item.name, C.accent, UDim2.fromScale(0.85, 0.45))
			end
			ctx.act("research", item.key)
		end, "primary")
		Elements.place(upgradeBtn, 20, 114, 120, 38)

		researchCards[index] = {
			item = item,
			card = card,
			title = title,
			detail = detail,
			levelLabel = levelLabel,
			progressBar = progressBar,
			upgradeBtn = upgradeBtn,
			searchString = string.lower(item.name .. " " .. (item.subtitle or "")),
		}
	end

	local emptyLabel = Elements.text(root, "Empty", "No technological research matches your search.", 14, C.textMuted)
	emptyLabel.TextWrapped = true
	emptyLabel.Visible = false

	-- =========================================================================
	-- 3. STATE BINDING
	-- =========================================================================
	ctx.bind("research", function(s)
		local status = s.synergyStatus or {}
		local bonus = s.synergyBonus or 0
		local bonusStr = string.format("+%d%% production active", math.floor(bonus * 100))

		if bonusStr ~= synergyTotal.Text then
			synergyTotal.Text = bonusStr
			bumpSynergy()
		end

		for _, row in ipairs(synergyRows) do
			local isActive = status[row.synergy.key] == true
			if isActive ~= row.active then
				row.active = isActive
				Springs.target(row.iconShell, { BackgroundColor3 = if isActive then C.accent2 else C.recessed }, "smooth")
				row.name.TextColor3 = if isActive then C.accent else C.textPrimary
				if isActive then
					row.bumpName()
					if ctx.preferences and ctx.preferences.particles ~= false then
						Feedback.confetti(row.iconShell, C.accent2)
					end
				end
			end
		end

		local researchLevels = s.research or {}
		local compute = s.compute or 0

		for _, rc in ipairs(researchCards) do
			local curLevel = researchLevels[rc.item.key] or 0
			local cost = Config.researchCost(rc.item, curLevel, s)
			local isMax = curLevel >= rc.item.max
			local progressRatio = math.clamp(curLevel / rc.item.max, 0, 1)

			rc.levelLabel.Text = string.format("Tier %d / %d", curLevel, rc.item.max)
			rc.progressBar:setProgress(progressRatio, true)

			Buttons.enable(
				rc.upgradeBtn,
				not isMax and compute >= cost,
				if isMax then "Researched" else "Upgrade · " .. fmt(cost),
				true
			)
		end
	end)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	ctx.layoutScreen("research", function(w)
		Elements.place(searchInput, 0, 0, w, 38)

		local synH = getSynergyHeight()
		Elements.place(synergyCard, 0, 48, w, synH)
		synergyTotal.Size = UDim2.fromOffset(w - 44, 30)
		for _, row in ipairs(synergyRows) do
			row.name.Size = UDim2.fromOffset(math.max(100, w - 90), 18)
			row.desc.Size = UDim2.fromOffset(math.max(100, w - 90), 16)
		end

		local gridStartY = 48 + synH + 16

		local matchedCards = {}
		for _, rc in ipairs(researchCards) do
			if query == "" or (Fuzzy.score(query, rc.searchString) or 0) > 0 then
				table.insert(matchedCards, rc)
			end
		end

		for _, rc in ipairs(researchCards) do
			rc.card.Visible = false
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
		local cardH = 170

		for idx, rc in ipairs(matchedCards) do
			local localIdx = idx - 1
			local col = localIdx % cols
			local row = localIdx // cols
			local cx = col * (cardW + 16)
			local cy = gridStartY + row * (cardH + 16)

			rc.card.Visible = true
			Elements.place(rc.card, cx, cy, cardW, cardH)

			rc.title.Position = UDim2.fromOffset(50, 18)
			rc.title.Size = UDim2.fromOffset(math.max(80, cardW - 160), 22)
			rc.title.TextTruncate = Enum.TextTruncate.AtEnd

			rc.levelLabel.AnchorPoint = Vector2.new(1, 0)
			rc.levelLabel.Position = UDim2.new(1, -20, 0, 18)
			rc.levelLabel.Size = UDim2.fromOffset(90, 20)

			rc.detail.Position = UDim2.fromOffset(20, 48)
			rc.detail.Size = UDim2.fromOffset(cardW - 40, 36)
			Elements.place(rc.progressBar.instance, 20, 94, cardW - 40, 6)
			Elements.place(rc.upgradeBtn, 20, 114, cardW - 40, 38)
		end

		local totalRows = math.ceil(#matchedCards / cols)
		return gridStartY + totalRows * (cardH + 16) + 32
	end)
end

return ScreenResearch

