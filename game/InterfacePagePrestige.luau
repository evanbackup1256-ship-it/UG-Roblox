--!strict
local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePagePrestige = {}

function InterfacePagePrestige.build(Shared: InterfaceShared.Shared)
	local Kit = Shared.Kit
	local C = Shared.C
	local positionText = Shared.positionText
	local liven = Shared.liven
	local bind = Shared.bind
	local layoutPage = Shared.layoutPage
	local fmt = Shared.fmt

	local pageRoot = Shared.pages.prestige

	-- =========================================================================
	-- 1. HERO BANNER: QUANTUM FLEET RELAUNCH
	-- =========================================================================
	local hero = Kit.interactiveCard(pageRoot, "RelaunchHero", 260, C.panel)
	Kit.place(Kit.rocketIcon(hero, "RocketIcon", C.energy), 24, 22, 24, 24)

	local heroBadge = Kit.badge(hero, "Fleet Relaunch", "energy", true)
	Kit.place(heroBadge, 58, 22, 110, 20)

	local heroTitle = positionText(hero, "Title", "Bank Prestige Tokens.", 24, 54, 550, 32, 24, C.text, true)

	local heroDetail = positionText(hero, "Detail", "", 24, 92, 600, 70, 13, C.textSub)
	heroDetail.TextWrapped = true

	local heroButton = liven(Kit.button(hero, "PrestigeAction", "Connecting…", function()
		Shared.fn.act("prestige")
	end, "primary"))

	local heroGlow: any = nil
	local isReady = false
	local function syncHeroGlow()
		local wanted = isReady and (Shared.preferences.motion ~= false)
		if wanted and not heroGlow then
			heroGlow = Kit.ambientGlow(hero, { color = C.energy })
		elseif not wanted and heroGlow then
			heroGlow.stop()
			heroGlow = nil
		end
	end
	table.insert(Shared.fn.settingRefresh, syncHeroGlow)

	local lastPrestigeCount: number? = nil

	-- =========================================================================
	-- 2. LIFETIME PRESTIGE METRICS
	-- =========================================================================
	local statDefs = {
		{ label = "Prestige Tokens", key = "prestigeTokens", color = C.energy },
		{ label = "Permanent Multiplier", key = "prestigeBonus", color = C.accent },
		{ label = "Total Relaunches", key = "prestigeCount", color = C.text },
	}

	local stats = {}
	for index, def in ipairs(statDefs) do
		local card = Kit.interactiveCard(pageRoot, "PrestigeStat_" .. index, 110, C.panel)
		local lbl = positionText(card, "Label", def.label, 20, 16, 240, 18, 11, C.textSub, true)

		local val = positionText(card, "Value", "—", 20, 36, 240, 34, 24, def.color, true)
		val.Font = Enum.Font.RobotoMono

		stats[index] = { card = card, label = lbl, value = val, key = def.key }
	end

	-- =========================================================================
	-- 3. STATE BINDING
	-- =========================================================================
	bind("prestige", function(s)
		local pending = s.prestigePoints or 0
		local ready = pending > 0
		isReady = ready
		syncHeroGlow()

		local count = s.prestigeCount or 0
		if lastPrestigeCount ~= nil and count > lastPrestigeCount then
			Kit.bump(heroTitle, 1.08)
			Kit.fanfare(hero, C.energy)
			Kit.floatText(hero, "Fleet Relaunch Initiated", C.energy, Vector2.new(0.5, 0.4))
		end
		lastPrestigeCount = count

		heroDetail.Text = if ready
			then "Initiating a relaunch grants " .. fmt(pending) .. " prestige tokens and resets hardware, research, modules, energy, and balance. Completed milestones, contracts, and reputation are permanently retained."
			else "Generate " .. fmt(s.prestigeThreshold or 0) .. " lifetime compute to unlock fleet relaunch. Lifetime earned: " .. fmt(s.totalEarned or 0) .. " compute."

		Kit.enable(
			heroButton,
			ready,
			if ready then "Initiate Relaunch · +" .. fmt(pending) .. " Tokens" else "Threshold Not Reached",
			true
		)

		for _, stat in ipairs(stats) do
			if stat.key == "prestigeBonus" then
				stat.value.Text = "+" .. math.floor((s.prestigeBonus or 0) * 100) .. "%"
			else
				stat.value.Text = fmt(s[stat.key] or 0)
			end
		end
	end)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	layoutPage("prestige", function(w)
		Kit.place(hero, 0, 137, w, 260)
		heroTitle.Size = UDim2.fromOffset(w - 48, 32)
		heroDetail.Size = UDim2.fromOffset(w - 48, 70)
		Kit.place(heroButton, 24, 186, math.min(320, w - 48), 44)

		local columns = if w >= 740 then 3 elseif w >= 480 then 2 else 1
		local cardWidth = (w - (columns - 1) * 16) / columns
		local statsY = 137 + 260 + 16

		for index, stat in ipairs(stats) do
			local col = (index - 1) % columns
			local row = (index - 1) // columns

			local cardX = col * (cardWidth + 16)
			local cardY = statsY + row * (110 + 16)

			Kit.place(stat.card, cardX, cardY, cardWidth, 110)
			stat.value.Size = UDim2.fromOffset(cardWidth - 40, 34)
		end

		local totalRows = math.ceil(#stats / columns)
		return statsY + totalRows * (110 + 16)
	end)
end

return InterfacePagePrestige
