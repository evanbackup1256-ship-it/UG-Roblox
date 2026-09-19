local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageResearch = {}

function InterfacePageResearch.build(Shared: InterfaceShared.Shared)
	local Kit, C, Config = Shared.Kit, Shared.C, Shared.Config
	local positionText, liven, bump = Shared.positionText, Shared.liven, Shared.bump
	local bind, layoutPage, relayout = Shared.bind, Shared.layoutPage, Shared.relayout
	local fmt = Shared.fmt

	local researchPage = 1

	-- Synergy bonuses: a live (not one-time-claimed) status derived from
	-- currently owned tiers/research/modules, shown here rather than as a
	-- 12th nav tab since it's a derived-stat panel tied to the same
	-- "systems that passively change your multipliers" framing as the rest
	-- of this page, not a standalone feature surface.
	--
	-- Row N's content occupies rowY(N)..rowY(N)+33 where rowY(N) =
	-- 84 + (N-1)*40 (icon shell top at rowY, description bottom at
	-- rowY+17+16 = rowY+33) — this height must track that geometry exactly
	-- or the card clips its own last row and the page content below it
	-- starts overlapping the card instead of sitting below it.
	local function synergyCardHeight()
		return 84 + (#Config.Synergies - 1) * 40 + 33 + 20
	end
	local synergyCard = Kit.card(Shared.pages.research, "Synergies", synergyCardHeight())
	positionText(synergyCard, "Eyebrow", "SYNERGY BONUSES", 22, 18, 300, 20, 10, C.muted, true).Font = Enum.Font.RobotoMono

	local synergyTotal = positionText(synergyCard, "Total", "", 22, 40, 400, 30, 20, C.accent, true)
	synergyTotal.Font = Enum.Font.RobotoMono
	local bumpSynergyTotal = bump(synergyTotal)

	local synergyRows = {}
	for index, synergy in ipairs(Config.Synergies) do
		local rowY = 84 + (index - 1) * 40

		local iconShell = Kit.create("Frame", synergyCard, {
			Name = "IconShell_" .. synergy.key,
			Position = UDim2.fromOffset(22, rowY),
			Size = UDim2.fromOffset(32, 32),
			BackgroundColor3 = C.raised,
			BorderSizePixel = 0,
		})
		Kit.corner(iconShell, 12)
		local icon = Kit.icon(iconShell, "Icon", synergy.icon or "research", C.muted)
		Kit.place(icon, 4, 4, 24, 24)

		local name = positionText(synergyCard, "Name_" .. synergy.key, synergy.name, 66, rowY - 1, 260, 18, 13, C.text, true)
		local description = positionText(synergyCard, "Description_" .. synergy.key, synergy.description, 66, rowY + 17, 700, 16, 11, C.muted)
		description.TextWrapped = true
		description.TextTruncate = Enum.TextTruncate.AtEnd

		synergyRows[index] = {
			synergy = synergy,
			iconShell = iconShell,
			icon = icon,
			name = name,
			description = description,
			active = false,
			bumpName = bump(name),
		}
	end

	bind("research", function(s)
		local status = s.synergyStatus or {}
		local bonus = s.synergyBonus or 0
		local newText = "+" .. math.floor(bonus * 100) .. "% production active"

		if newText ~= synergyTotal.Text then
			synergyTotal.Text = newText
			bumpSynergyTotal()
		end

		for _, row in ipairs(synergyRows) do
			local active = status[row.synergy.key] == true

			if active ~= row.active then
				row.active = active

				-- Newly activated: pop/glow the icon shell and bump the name,
				-- the same "you just crossed a threshold" language contract
				-- progress bars use via Kit.progressFull. Deactivating (e.g.
				-- selling off the last qualifying tier) just settles back
				-- with no celebration.
				Kit.animate(row.iconShell, { BackgroundColor3 = if active then C.accent2 else C.raised }, if active then 0.16 else 0.2, if active then Enum.EasingStyle.Back else Enum.EasingStyle.Quad)
				Kit.tintIcon(row.icon, if active then C.ink else C.muted)
				row.name.TextColor3 = if active then C.accent else C.text

				if active then
					row.bumpName()
				end
			end
		end
	end)

	local researchCards = {}
	for index, item in ipairs(Config.Research) do
		local card = Kit.card(Shared.pages.research, "Research_" .. item.key, 214)

		Kit.place(Kit.icon(card, "Icon", item.icon or "research", C.accent), 20, 20, 24, 24)

		local title = positionText(card, "Title", item.name, 56, 18, 360, 28, 17, C.text, true)
		title.TextWrapped = true
		title.TextTruncate = Enum.TextTruncate.None

		local detail = positionText(card, "Detail", item.subtitle, 20, 56, 400, 48, 13, C.muted)
		detail.TextWrapped = true
		detail.TextTruncate = Enum.TextTruncate.None

		local level = positionText(card, "Level", "", 20, 110, 300, 22, 11, C.accent, true)
		local progress, fill = Kit.progress(card, "Progress")

		local buy = liven(Kit.button(card, "Research", "", function()
			Shared.fn.act("research", item.key)
		end, "primary"))

		researchCards[index] = {
			card = card,
			title = title,
			detail = detail,
			progress = progress,
			buy = buy,
			level = level,
		}

		local shownFraction = -1
		local bumpLevel = bump(level)

		bind("research", function(s)
			local n = s.research[item.key] or 0
			local price = Config.researchCost(item, n, s)
			local fraction = n / item.max

			level.Text = string.format("LEVEL %d / %d", n, item.max)

			if fraction ~= shownFraction then
				local first = shownFraction == -1
				shownFraction = fraction
				Kit.animate(fill, { Size = UDim2.fromScale(fraction, 1) }, 0.3)
				if not first then
					bumpLevel()
				end
			end

			Kit.enable(
				buy,
				n < item.max and (s.compute or 0) >= price,
				if n >= item.max then "Fully researched" else "Upgrade · " .. fmt(price),
				true
			)
		end)
	end

	local placeResearchPager = Shared.pager(Shared.pages.research, function()
		researchPage = math.max(1, researchPage - 1)
		relayout("research")
		Shared.fn.revealPageChange("research")
	end, function()
		researchPage += 1
		relayout("research")
		Shared.fn.revealPageChange("research")
	end)

	layoutPage("research", function(w)
		local synergyHeight = synergyCardHeight()
		Kit.place(synergyCard, 0, 137, w, synergyHeight)
		local synergyTextWidth = math.max(1, w - 88)
		synergyTotal.Size = UDim2.fromOffset(math.max(1, w - 44), 30)
		for _, row in ipairs(synergyRows) do
			row.name.Size = UDim2.fromOffset(math.min(260, synergyTextWidth), 18)
			row.description.Size = UDim2.fromOffset(synergyTextWidth, 16)
		end

		local cardsY = 137 + synergyHeight + 16

		local columns = if w >= 750 then 2 else 1
		local cw = (w - (columns - 1) * 16) / columns
		local small = cw < 350
		local height = if small then 250 else 214
		local pageSize = columns * 3
		local totalPages = math.max(1, math.ceil(#researchCards / pageSize))

		researchPage = math.clamp(researchPage, 1, totalPages)
		local first = (researchPage - 1) * pageSize + 1
		local last = math.min(#researchCards, first + pageSize - 1)

		for index, item in ipairs(researchCards) do
			item.card.Visible = index >= first and index <= last
		end

		local shown = 0
		for index = first, last do
			local item = researchCards[index]

			Kit.place(
				item.card,
				(shown % columns) * (cw + 16),
				cardsY + (shown // columns) * (height + 16),
				cw,
				height
			)

			item.title.Size = UDim2.fromOffset(cw - 76, if small then 56 else 28)
			item.title.TextSize = if small then 15 else 17
			item.detail.Position = UDim2.fromOffset(20, if small then 86 else 56)
			item.detail.Size = UDim2.fromOffset(cw - 40, 48)
			item.level.Position = UDim2.fromOffset(20, if small then 146 else 110)

			Kit.place(item.progress, 20, height - 74, cw - 40, 4)
			Kit.place(item.buy, 20, height - 56, cw - 40, 44)

			shown += 1
		end

		local footerY = cardsY + 12 + math.ceil(shown / columns) * (height + 16)
		placeResearchPager(w, footerY, researchPage, totalPages, #researchCards, "PROGRAMS")

		return footerY + 54
	end)
end

return InterfacePageResearch
