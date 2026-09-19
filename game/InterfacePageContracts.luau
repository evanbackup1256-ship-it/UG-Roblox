local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageContracts = {}

function InterfacePageContracts.build(Shared: InterfaceShared.Shared)
	local Kit, C, Config = Shared.Kit, Shared.C, Shared.Config
	local positionText, liven = Shared.positionText, Shared.liven
	local bind, layoutPage = Shared.bind, Shared.layoutPage
	local fmt = Shared.fmt

	local contractCards = {}
	for i, contract in ipairs(Config.Contracts) do
		local card = Kit.card(Shared.pages.contracts, "Contract_" .. contract.key, 120)

		positionText(card, "Number", string.format("%02d", i), 20, 20, 35, 30, 20, C.accent, true)

		local title = positionText(card, "Title", contract.name, 68, 18, 440, 28, 17, C.text, true)
		title.TextWrapped = true
		title.TextTruncate = Enum.TextTruncate.None

		local detail = positionText(card, "Detail", contract.subtitle, 68, 51, 440, 32, 12, C.muted)
		detail.TextWrapped = true

		local progress, fill = Kit.progress(card, "Progress")
		Kit.progressShimmer(fill)

		local claim = liven(Kit.button(card, "Claim", "", function()
			Shared.fn.act("claim", contract.key)
		end, "primary"))

		contractCards[i] = {
			card = card,
			title = title,
			detail = detail,
			progress = progress,
			claim = claim,
		}

		local shownFraction = -1
		local ready = false
		local hydratedOnce = false
		local restColor = card.BackgroundColor3

		bind("contracts", function(s)
			local n = Config.metric(s, contract.metric)
			local complete = s.claimed[contract.key]
			local fraction = math.clamp(n / contract.target, 0, 1)

			if fraction ~= shownFraction then
				shownFraction = fraction
				Kit.animate(fill, { Size = UDim2.fromScale(fraction, 1) }, 0.3)
			end

			if fraction >= 1 and not ready and not complete and Shared.preferences.motion and hydratedOnce then
				card.BackgroundColor3 = C.accent
				Kit.animate(card, { BackgroundColor3 = restColor }, 0.5, Enum.EasingStyle.Quad)
				Kit.progressFull(progress)
			end
			ready = fraction >= 1
			hydratedOnce = true

			Kit.enable(
				claim,
				not complete and fraction >= 1,
				if complete then "Completed"
					elseif fraction >= 1 then "Claim " .. fmt(Config.reward(contract, s))
					else fmt(math.min(n, contract.target)) .. " / " .. fmt(contract.target),
				true
			)
		end)
	end

	layoutPage("contracts", function(w)
		local narrow = w < 620
		local height = if narrow then 204 else 120

		for i, item in ipairs(contractCards) do
			Kit.place(item.card, 0, 137 + (i - 1) * (height + 12), w, height)

			item.title.Size = UDim2.fromOffset(w - (if narrow then 88 else 288), if narrow then 48 else 28)
			item.title.TextSize = if narrow then 15 else 17
			item.detail.Position = UDim2.fromOffset(if narrow then 20 else 68, if narrow then 70 else 51)
			item.detail.Size = UDim2.fromOffset(w - (if narrow then 40 else 288), if narrow then 40 else 32)

			Kit.place(item.progress, if narrow then 20 else 68, if narrow then 126 else 98, w - (if narrow then 40 else 88), 4)
			Kit.place(item.claim, if narrow then 20 else w - 194, if narrow then 144 else 26, if narrow then w - 40 else 174, 42)
		end

		return 137 + #contractCards * (height + 12)
	end)
end

return InterfacePageContracts
