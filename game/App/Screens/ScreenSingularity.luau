--!strict
-- ScreenSingularity: Quantum fleet relaunch and permanent prestige multipliers
local AppContext = require(script.Parent.Parent.AppContext)

local ScreenSingularity = {}

function ScreenSingularity.build(ctx: AppContext.Context)
	local Elements = ctx.Elements
	local Buttons = ctx.Buttons
	local Feedback = ctx.Feedback
	local C = ctx.C
	local Config = ctx.Config
	local fmt = ctx.fmt

	local root = ctx.screens.prestige

	-- =========================================================================
	-- 1. PRESTIGE HERO
	-- =========================================================================
	local hero = Elements.interactiveCard(root, "RelaunchHero", 260, C.card)

	Elements.place(Elements.rocketIcon(hero, "RocketIcon", C.energy), 24, 22, 24, 24)

	local heroBadge = Elements.badge(hero, "Prestige", "energy", true)
	Elements.place(heroBadge, 58, 22, 110, 22)

	local heroTitle = Elements.text(hero, "Title", "Bank Prestige Tokens.", 26, C.textPrimary, true)
	heroTitle.Font = ctx.Theme.typography.fontDisplay
	Elements.place(heroTitle, 24, 56, 550, 32)

	local heroDetail = Elements.text(hero, "Detail", "", 14, C.textSecondary)
	heroDetail.TextWrapped = true
	Elements.place(heroDetail, 24, 94, 550, 70)

	local relaunchBtn = Buttons.button(hero, "RelaunchAction", "Prestige Account", function()
		ctx.act("prestige")
	end, "primary")
	Elements.place(relaunchBtn, 24, 180, 200, 44)

	local heroGlow: any = nil
	local isReady = false

	local function syncHeroGlow()
		local wanted = isReady and (ctx.preferences and ctx.preferences.motion ~= false)
		if wanted and not heroGlow then
			heroGlow = Feedback.ambientGlow(hero, { color = C.energy })
		elseif not wanted and heroGlow then
			heroGlow.stop()
			heroGlow = nil
		end
	end
	table.insert(ctx.settingRefresh, syncHeroGlow)

	-- =========================================================================
	-- 2. LIFETIME STAT TILES
	-- =========================================================================
	local statDefs = {
		{ label = "Prestige Tokens", key = "prestigeTokens", color = C.energy },
		{ label = "Global Multiplier", key = "multiplier", color = C.accent },
		{ label = "Total Prestiges", key = "prestigeCount", color = C.reputation },
	}

	local statTiles = {}
	for i, def in ipairs(statDefs) do
		local tile = Elements.card(root, "StatTile_" .. def.key, 100, C.card)

		local lbl = Elements.text(tile, "Label", def.label, 13, C.textSecondary, true)
		Elements.place(lbl, 20, 18, 200, 20)

		local val = Elements.text(tile, "Val", "0", 24, def.color, true)
		val.Font = ctx.Theme.typography.fontDisplay
		Elements.place(val, 20, 48, 200, 32)

		statTiles[i] = { card = tile, val = val, def = def, bump = Feedback.bump(val) }
	end

	-- =========================================================================
	-- 3. STATE BINDING
	-- =========================================================================
	ctx.bind("prestige", function(s)
		local pending = Config.prestigePoints(s)
		local ready = pending >= 1

		isReady = ready
		syncHeroGlow()

		heroDetail.Text = if ready
			then string.format(
				"Prestige to earn +%s prestige tokens and reset hardware, research, modules, energy, and balance. Completed milestones, contracts, and reputation are permanently retained.",
				fmt(pending)
			)
			else string.format(
				"Prestige becomes available after earning sufficient lifetime compute. Threshold requires at least 1 prestige token (current pending: %s).",
				fmt(pending)
			)

		Buttons.enable(
			relaunchBtn,
			ready,
			if ready then "Prestige Account · +" .. fmt(pending) .. " Tokens" else "Threshold Not Reached",
			true
		)

		for _, tile in ipairs(statTiles) do
			local k = tile.def.key
			local formatted = "0"
			if k == "prestigeTokens" then
				formatted = fmt(s.prestigeTokens or 0)
			elseif k == "multiplier" then
				local bonus = Config.prestigeBonus(s)
				formatted = string.format("×%.2f", 1 + bonus)
			elseif k == "prestigeCount" then
				formatted = fmt(s.prestigeCount or 0)
			end

			if formatted ~= tile.val.Text then
				tile.val.Text = formatted
				tile.bump()
			end
		end
	end)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	ctx.layoutScreen("prestige", function(w)
		local narrow = w < 680

		Elements.place(hero, 0, 0, w, if narrow then 270 else 244)
		heroTitle.Size = UDim2.fromOffset(w - 48, 32)
		heroDetail.Size = UDim2.fromOffset(w - 48, if narrow then 80 else 64)

		if narrow then
			relaunchBtn.Position = UDim2.fromOffset(24, 190)
			relaunchBtn.Size = UDim2.fromOffset(w - 48, 44)
		else
			relaunchBtn.Position = UDim2.fromOffset(24, 180)
			relaunchBtn.Size = UDim2.fromOffset(300, 44)
		end

		local tileStartY = (if narrow then 270 else 244) + 16
		local cols = if w >= 760 then 3 else 1
		local tileW = math.floor((w - (cols - 1) * 14) / cols)
		local tileH = 100

		for idx, item in ipairs(statTiles) do
			local localIdx = idx - 1
			local col = localIdx % cols
			local row = localIdx // cols
			local tx = col * (tileW + 14)
			local ty = tileStartY + row * (tileH + 14)
			Elements.place(item.card, tx, ty, tileW, tileH)
			item.val.Size = UDim2.fromOffset(tileW - 40, 32)
			local lbl = item.card:FindFirstChild("Label") :: TextLabel?
			if lbl then
				lbl.Size = UDim2.fromOffset(tileW - 40, 20)
			end
		end

		local totalRows = math.ceil(#statTiles / cols)
		return tileStartY + totalRows * (tileH + 14) + 32
	end)
end

return ScreenSingularity

