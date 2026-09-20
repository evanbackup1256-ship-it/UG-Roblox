--!strict
local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageContracts = {}

function InterfacePageContracts.build(Shared: InterfaceShared.Shared)
	local Kit = Shared.Kit
	local C = Shared.C
	local Config = Shared.Config
	local positionText = Shared.positionText
	local liven = Shared.liven
	local bind = Shared.bind
	local layoutPage = Shared.layoutPage
	local fmt = Shared.fmt
	local preferences = Shared.preferences

	local pageRoot = Shared.pages.contracts

	local contractCards = {}
	for i, contract in ipairs(Config.Contracts) do
		local card = Kit.interactiveCard(pageRoot, "Contract_" .. contract.key, 120, C.panel)

		local orderBadge = Kit.badge(card, string.format("Order %02d", i), "raised", true)
		Kit.place(orderBadge, 20, 18, 70, 20)

		local status = Kit.statusDot(card, C.muted, "Pending", 6)
		Kit.place(status, 98, 25, 6, 6)

		local title = positionText(card, "Title", contract.name, 116, 14, 440, 26, 16, C.text, true)
		title.TextWrapped = true

		local detail = positionText(card, "Detail", contract.subtitle, 20, 46, 440, 30, 12, C.textSub)
		detail.TextWrapped = true

		local progressBar = Kit.progressBar(card, "Progress", 6, C.accent)

		local claimBtn = liven(Kit.button(card, "Claim", "Connecting…", function()
			if Shared.state then
				local reward = Config.reward(contract, Shared.state)
				Kit.fanfare(card, C.compute)
				Kit.floatText(card, "+" .. fmt(reward) .. " Compute", C.compute, Vector2.new(0.5, 0.45))
			end
			Shared.fn.act("claim", contract.key)
		end, "primary"))

		contractCards[i] = {
			card = card,
			title = title,
			detail = detail,
			progressBar = progressBar,
			status = status,
			claimBtn = claimBtn,
		}

		local shownFraction = -1
		local ready = false
		local hydratedOnce = false
		local restColor = card.BackgroundColor3

		bind("contracts", function(s)
			local metricVal = Config.metric(s, contract.metric)
			local complete = (s.claimed and s.claimed[contract.key]) == true
			local fraction = math.clamp(metricVal / contract.target, 0, 1)

			if fraction ~= shownFraction then
				shownFraction = fraction
				progressBar:SetProgress(fraction, true)
			end

			status.Dot.BackgroundColor3 = if complete then C.compute elseif fraction >= 1 then C.energy else C.muted

			if fraction >= 1 and not ready and not complete and (preferences.motion ~= false) and hydratedOnce then
				card.BackgroundColor3 = C.accent
				Kit.animate(card, { BackgroundColor3 = restColor }, 0.4, Enum.EasingStyle.Quad)
				Kit.progressFull(progressBar.instance)
			end
			ready = fraction >= 1
			hydratedOnce = true

			Kit.enable(
				claimBtn,
				not complete and fraction >= 1,
				if complete then "Completed"
					elseif fraction >= 1 then "Claim · " .. fmt(Config.reward(contract, s))
					else fmt(math.min(metricVal, contract.target)) .. " / " .. fmt(contract.target),
				true
			)
		end)
	end

	-- =========================================================================
	-- RESPONSIVE LAYOUT
	-- =========================================================================
	layoutPage("contracts", function(w)
		local narrow = w < 640
		local height = if narrow then 190 else 120

		for i, item in ipairs(contractCards) do
			Kit.place(item.card, 0, 137 + (i - 1) * (height + 12), w, height)

			item.title.Size = UDim2.fromOffset(w - (if narrow then 88 else 288), if narrow then 44 else 26)
			item.title.TextSize = if narrow then 15 else 16
			item.detail.Position = UDim2.fromOffset(20, if narrow then 68 else 48)
			item.detail.Size = UDim2.fromOffset(w - (if narrow then 40 else 240), if narrow then 38 else 30)

			Kit.place(item.progressBar.instance, 20, if narrow then 120 else 94, w - (if narrow then 40 else 240), 6)
			Kit.place(item.claimBtn, if narrow then 20 else w - 200, if narrow then 138 else 26, if narrow then w - 40 else 180, 40)
		end

		return 137 + #contractCards * (height + 12)
	end)
end

return InterfacePageContracts
