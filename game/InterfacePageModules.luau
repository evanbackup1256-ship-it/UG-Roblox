local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageModules = {}

function InterfacePageModules.build(Shared: InterfaceShared.Shared)
	local Kit, C, Config = Shared.Kit, Shared.C, Shared.Config
	local positionText, liven, bump = Shared.positionText, Shared.liven, Shared.bump
	local bind, layoutPage, relayout = Shared.bind, Shared.layoutPage, Shared.relayout
	local fmt = Shared.fmt

	local modulePage = 1

	local effectNames = {
		production = "AUTOMATED OUTPUT",
		job = "ACTIVE JOB PAYOUT",
		energy = "ENERGY CAPACITY",
		success = "OPERATION RELIABILITY",
		operation = "OPERATION PAYOUT",
		reputation = "REPUTATION GAIN",
		recovery = "ENERGY RECOVERY",
		data = "DATA EXTRACTION",
		hardware = "HARDWARE DISCOUNT",
	}

	local GENERATION_NAMES = { "CORE", "ARRAY", "NEXUS" }

	local moduleCards = {}
	for index, module in ipairs(Config.Modules) do
		local card = Kit.card(Shared.pages.modules, "Module_" .. module.key, 236)

		local generation = math.min(3, (index - 1) // 12 + 1)
		local color = if generation == 1 then C.accent elseif generation == 2 then C.accent2 else C.warning

		positionText(card, "Generation", GENERATION_NAMES[generation], 20, 17, 90, 20, 9, color, true)

		local level = positionText(card, "Level", "LEVEL 0 / 5", 116, 17, 180, 20, 9, C.muted, true)
		level.TextXAlignment = Enum.TextXAlignment.Right

		local title = positionText(card, "Title", module.name, 20, 45, 330, 30, 17, C.text, true)
		title.TextWrapped = true

		local detail = positionText(card, "Detail", module.subtitle, 20, 79, 330, 38, 12, C.muted)
		detail.TextWrapped = true

		local effect = positionText(card, "Effect", effectNames[module.effect] or string.upper(module.effect), 20, 122, 330, 20, 10, color, true)

		local progress, fill = Kit.progress(card, "Calibration")

		local calibrate = liven(Kit.button(card, "Calibrate", "Connecting…", function()
			Shared.fn.act("module", module.key)
		end, true))

		moduleCards[index] = {
			card = card,
			module = module,
			title = title,
			detail = detail,
			level = level,
			effect = effect,
			progress = progress,
			fill = fill,
			fraction = -1,
			bumpLevel = bump(level),
			calibrate = calibrate,
		}
	end

	local placeModulePager = Shared.pager(Shared.pages.modules, function()
		modulePage = math.max(1, modulePage - 1)
		relayout("modules")
		Shared.fn.revealPageChange("modules")
	end, function()
		modulePage += 1
		relayout("modules")
		Shared.fn.revealPageChange("modules")
	end)

	bind("modules", function(s)
		local playerLevel = s.level or 1
		local compute = s.compute or 0
		local data = s.data or 0

		for _, item in ipairs(moduleCards) do
			local module = item.module
			local level = s.modules[module.key] or 0
			local computeCost, dataCost = Config.moduleCost(module, level)
			local unlocked = playerLevel >= module.unlock
			local fraction = level / module.max

			item.level.Text = string.format("LEVEL %d / %d", level, module.max)

			if fraction ~= item.fraction then
				local first = item.fraction == -1
				item.fraction = fraction
				Kit.animate(item.fill, { Size = UDim2.fromScale(fraction, 1) }, 0.24)
				if not first then
					item.bumpLevel()
				end
			end

			Kit.lock(item.card, not unlocked, item.calibrate)

			Kit.enable(
				item.calibrate,
				unlocked and level < module.max and compute >= computeCost and data >= dataCost,
				if level >= module.max then "Fully calibrated"
					elseif not unlocked then "Unlocks at level " .. module.unlock
					else string.format("Calibrate · %s C · %s D", fmt(computeCost), fmt(dataCost)),
				true
			)
		end

		relayout("modules")
	end)

	layoutPage("modules", function(w)
		local columns = if w >= 980 then 3 elseif w >= 650 then 2 else 1
		local cw = (w - (columns - 1) * 16) / columns
		local pageSize = columns * 3
		local totalPages = math.max(1, math.ceil(#moduleCards / pageSize))

		modulePage = math.clamp(modulePage, 1, totalPages)
		local first = (modulePage - 1) * pageSize + 1
		local last = math.min(#moduleCards, first + pageSize - 1)

		for index, item in ipairs(moduleCards) do
			item.card.Visible = index >= first and index <= last
		end

		local shown = 0
		for index = first, last do
			local item = moduleCards[index]

			Kit.place(
				item.card,
				(shown % columns) * (cw + 16),
				137 + (shown // columns) * 252,
				cw,
				236
			)

			item.level.Position = UDim2.fromOffset(math.max(112, cw - 188), 17)
			item.level.Size = UDim2.fromOffset(math.min(168, cw - 112), 20)
			item.title.Size = UDim2.fromOffset(cw - 40, 30)
			item.detail.Size = UDim2.fromOffset(cw - 40, 38)
			item.effect.Size = UDim2.fromOffset(cw - 40, 20)
			item.effect.TextSize = if cw < 280 then 9 else 10

			Kit.place(item.progress, 20, 154, cw - 40, 4)
			Kit.place(item.calibrate, 20, 176, cw - 40, 44)

			shown += 1
		end

		local footerY = 149 + math.ceil(shown / columns) * 252
		placeModulePager(w, footerY, modulePage, totalPages, #moduleCards, "MODULES")

		return footerY + 54
	end)
end

return InterfacePageModules
