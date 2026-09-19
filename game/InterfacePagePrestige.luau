local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePagePrestige = {}

function InterfacePagePrestige.build(Shared: InterfaceShared.Shared)
	local Kit, C = Shared.Kit, Shared.C
	local positionText, liven = Shared.positionText, Shared.liven
	local bind, layoutPage = Shared.bind, Shared.layoutPage
	local fmt = Shared.fmt

	local hero = Kit.card(Shared.pages.prestige, "RelaunchHero", 280, C.paper)
	Kit.place(Kit.rocketIcon(hero, "Icon", C.ink), 22, 22, 26, 26)
	positionText(hero, "Eyebrow", "FLEET RELAUNCH", 58, 22, 300, 22, 10, C.ink, true).Font = Enum.Font.RobotoMono

	local heroTitle = positionText(hero, "Title", "Bank prestige tokens.", 22, 58, 550, 34, 25, C.ink, true)
	local heroDetail = positionText(hero, "Detail", "", 22, 100, 600, 76, 13, C.ink)
	heroDetail.TextWrapped = true

	local heroButton = liven(Kit.button(hero, "Prestige", "", function()
		Shared.fn.act("prestige")
	end, "primary"))

	local lastPrestigeCount = nil
	bind("prestige", function(s)
		local pending = s.prestigePoints or 0
		local ready = pending > 0

		-- Bump only once the server confirms a relaunch actually happened
		-- (prestigeCount went up), not the instant the button is clicked —
		-- act() silently drops the request while another one is already in
		-- flight, so celebrating at click time could pop this for a click
		-- that did nothing.
		local count = s.prestigeCount or 0
		if lastPrestigeCount ~= nil and count > lastPrestigeCount then
			Kit.bump(heroTitle, 1.12)
		end
		lastPrestigeCount = count

		heroDetail.Text = if ready
			then "Resetting now grants " .. fmt(pending) .. " tokens and returns hardware, research, firmware, energy, and balance to their starting values. Achievements, contracts, and reputation are kept."
			else "Reach " .. fmt(s.prestigeThreshold or 0) .. " lifetime compute to unlock a relaunch. Earned so far: " .. fmt(s.totalEarned or 0) .. "."

		Kit.enable(
			heroButton,
			ready,
			if ready then "Relaunch fleet · +" .. fmt(pending) .. " tokens" else "Not ready",
			true
		)
	end)

	local stats = {}
	for index, definition in ipairs({
		{ "PRESTIGE TOKENS", "prestigeTokens" },
		{ "PRODUCTION BONUS", "prestigeBonus" },
		{ "RELAUNCHES", "prestigeCount" },
		}) do
		local card = Kit.card(Shared.pages.prestige, "PrestigeStat" .. index, 116)
		local label = positionText(card, "Label", definition[1], 20, 14, 220, 20, 10, C.muted, true)

		local value = positionText(card, "Value", "—", 20, 39, 220, 36, 27, C.accent, true)
		value.Font = Enum.Font.RobotoMono

		stats[index] = { card = card, label = label, value = value, key = definition[2] }
	end

	bind("prestige", function(s)
		for _, stat in ipairs(stats) do
			if stat.key == "prestigeBonus" then
				stat.value.Text = "+" .. math.floor((s.prestigeBonus or 0) * 100) .. "%"
			else
				stat.value.Text = fmt(s[stat.key] or 0)
			end
		end
	end)

	layoutPage("prestige", function(w)
		Kit.place(hero, 0, 137, w, 280)
		heroTitle.Size = UDim2.fromOffset(w - 44, 34)
		heroDetail.Size = UDim2.fromOffset(w - 44, 76)
		Kit.place(heroButton, 22, 192, math.min(320, w - 44), 48)

		local columns = if w >= 700 then 3 elseif w >= 460 then 2 else 1
		local cw = (w - (columns - 1) * 16) / columns
		local statsY = 137 + 280 + 16

		for index, stat in ipairs(stats) do
			Kit.place(
				stat.card,
				((index - 1) % columns) * (cw + 16),
				statsY + ((index - 1) // columns) * 132,
				cw,
				116
			)
			stat.label.Size = UDim2.fromOffset(cw - 40, 20)
			stat.value.Size = UDim2.fromOffset(cw - 40, 36)
		end

		return statsY + math.ceil(#stats / columns) * 132
	end)
end

return InterfacePagePrestige
