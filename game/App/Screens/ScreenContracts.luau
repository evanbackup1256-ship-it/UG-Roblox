--!strict
-- ScreenContracts: Enterprise fleet contracts, work orders, and service level agreements
local AppContext = require(script.Parent.Parent.AppContext)

local ScreenContracts = {}

function ScreenContracts.build(ctx: AppContext.Context)
	local Elements = ctx.Elements
	local Buttons = ctx.Buttons
	local Inputs = ctx.Inputs
	local Feedback = ctx.Feedback
	local C = ctx.C
	local Config = ctx.Config
	local fmt = ctx.fmt

	local root = ctx.screens.contracts

	-- =========================================================================
	-- 1. CONTRACTS HEADER SUMMARY
	-- =========================================================================
	local summary = Elements.card(root, "ContractsSummary", 110, C.card)

	
	local badge = Elements.badge(summary, "FLEET SLA DIRECTIVE", "azure", true)
	Elements.place(badge, 24, 18, 160, 22)

	local title = Elements.text(summary, "Title", "Enterprise Service Contracts", 20, C.textPrimary, true)
	Elements.place(title, 24, 46, 380, 26)

	local subtitle = Elements.text(
		summary,
		"Subtitle",
		"Fulfill operational thresholds to execute fleet covenants and claim compute allocations.",
		12,
		C.textSecondary
	)
	Elements.place(subtitle, 24, 74, 520, 20)

	-- Overview stats on the right side of the summary
	local statsPill = Elements.recessedWell(summary, "StatsPill", 80)
	local statsCompleted = Elements.text(statsPill, "CompletedVal", "0 / 0", 18, C.accent, true)
	statsCompleted.TextXAlignment = Enum.TextXAlignment.Center
	Elements.place(statsCompleted, 0, 16, 160, 24)

	local statsLabel = Elements.text(statsPill, "CompletedLbl", "CONTRACTS SIGNED", 10, C.textMuted, true)
	statsLabel.TextXAlignment = Enum.TextXAlignment.Center
	Elements.place(statsLabel, 0, 44, 160, 18)

	-- =========================================================================
	-- 2. CONTRACT CARDS
	-- =========================================================================
	local CARD_HEIGHT = 175

	type ContractEntry = {
		contract: any,
		card: Frame,
		statusBadge: Frame,
		statusText: TextLabel,
		title: TextLabel,
		detail: TextLabel,
		progressBar: any,
		meterLabel: TextLabel,
		claimBtn: TextButton,
		glow: any,
	}

	local cards: { ContractEntry } = {}

	for index, contract in ipairs(Config.Contracts) do
		local card = Elements.interactiveCard(root, "Contract_" .. contract.key, CARD_HEIGHT, C.card)

		-- Status badge
		local statusBadge = Elements.badge(card, "IN PROGRESS", "muted", false)
		local statusText = statusBadge:FindFirstChild("BadgeText") :: TextLabel
		Elements.place(statusBadge, 20, 18, 96, 20)

		-- Title
		local contractTitle = Elements.text(card, "Title", contract.name, 16, C.textPrimary, true)
		Elements.place(contractTitle, 20, 44, 400, 24)

		-- Subtitle
		local contractDetail = Elements.text(card, "Detail", contract.subtitle, 12, C.textSecondary)
		contractDetail.TextWrapped = true
		Elements.place(contractDetail, 20, 70, 420, 32)

		-- Progress Bar
		local progressBar = Inputs.progressBar(card, "Progress", 0)
		Elements.place(progressBar.instance, 20, 108, 300, 6)

		-- Meter text
		local meterLabel = Elements.text(card, "MeterLabel", "0 / 0", 11, C.textMuted, true)
		Elements.place(meterLabel, 20, 120, 260, 18)

		-- Tactile Claim Button
		local claimBtn = Buttons.button(card, "ClaimBtn", "Claim", function()
			Feedback.confetti(card, C.mint)
			Feedback.floatText(card, "+" .. fmt(contract.reward) .. " Compute", C.mint, UDim2.fromScale(0.5, 0.4))
			ctx.act("claim", contract.key)
		end, "primary")
		Elements.place(claimBtn, 20, 124, 150, 38)

		cards[index] = {
			contract = contract,
			card = card,
			statusBadge = statusBadge,
			statusText = statusText,
			title = contractTitle,
			detail = contractDetail,
			progressBar = progressBar,
			meterLabel = meterLabel,
			claimBtn = claimBtn,
			glow = nil,
		}
	end

	-- =========================================================================
	-- 3. STATE BINDING
	-- =========================================================================
	ctx.bind("contracts", function(s)
		local claimedCount = 0
		local totalCount = #cards

		for _, item in ipairs(cards) do
			local contract = item.contract
			local current = Config.metric(s, contract.metric)
			local claimed = s.claimed and (s.claimed[contract.key] == true)
			local target = contract.target or 1
			local ratio = math.clamp(current / target, 0, 1)

			item.progressBar.setProgress(ratio)

			if claimed then
				claimedCount += 1
				if item.glow then
					item.glow.stop()
					item.glow = nil
				end
				item.statusBadge.BackgroundColor3 = C.badgeMintBg or Color3.fromRGB(16, 32, 24)
				item.statusText.TextColor3 = C.mint or C.compute
				item.statusText.Text = "EXECUTED"
				item.meterLabel.Text = "Fulfilled  ·  Reward Claimed"
				item.meterLabel.TextColor3 = C.mint or C.compute

				Buttons.enable(item.claimBtn, false, "Fulfilled", true)
			elseif current >= target then
				if not item.glow and (ctx.preferences and ctx.preferences.motion ~= false) then
					item.glow = Feedback.ambientGlow(item.card, { color = C.energy })
				end
				item.statusBadge.BackgroundColor3 = C.badgeAmberBg or Color3.fromRGB(36, 28, 12)
				item.statusText.TextColor3 = C.amber or C.energy
				item.statusText.Text = "READY TO SIGN"
				item.meterLabel.Text = string.format("%s / %s (100%%)", fmt(current), fmt(target))
				item.meterLabel.TextColor3 = C.textPrimary

				Buttons.enable(item.claimBtn, true, "Sign · +" .. fmt(contract.reward), true)
			else
				if item.glow then
					item.glow.stop()
					item.glow = nil
				end
				item.statusBadge.BackgroundColor3 = C.recessed
				item.statusText.TextColor3 = C.textMuted
				item.statusText.Text = "ACTIVE ORDER"
				item.meterLabel.Text = string.format("%s / %s (%d%%)", fmt(current), fmt(target), math.floor(ratio * 100))
				item.meterLabel.TextColor3 = C.textMuted

				Buttons.enable(item.claimBtn, false, "In Progress", true)
			end
		end

		statsCompleted.Text = string.format("%d / %d", claimedCount, totalCount)
	end)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	ctx.layoutScreen("contracts", function(w)
		local y = 20

		-- Place summary
		local isCompact = w < 640
		local summaryHeight = if isCompact then 145 else 110
		Elements.place(summary, 0, y, w, summaryHeight)

		if isCompact then
			Elements.place(badge, 20, 16, 150, 20)
			Elements.place(title, 20, 42, w - 40, 26)
			Elements.place(subtitle, 20, 70, w - 40, 32)
			statsPill.Visible = false
		else
			statsPill.Visible = true
			Elements.place(badge, 24, 18, 160, 22)
			Elements.place(title, 24, 46, w - 210, 26)
			Elements.place(subtitle, 24, 74, w - 210, 20)
			Elements.place(statsPill, w - 180, 15, 160, 80)
		end

		y += summaryHeight + 16

		-- Place grid of contracts
		local columns = if w >= 820 then 2 else 1
		local spacing = 14
		local cw = math.floor((w - (columns - 1) * spacing) / columns)
		local cardH = if cw < 450 then 184 else 170

		for index, item in ipairs(cards) do
			local col = (index - 1) % columns
			local row = (index - 1) // columns
			local cardX = col * (cw + spacing)
			local cardY = y + row * (cardH + spacing)

			Elements.place(item.card, cardX, cardY, cw, cardH)
			item.title.Size = UDim2.fromOffset(cw - 40, 24)
			item.detail.Size = UDim2.fromOffset(cw - 40, 32)

			local barWidth = cw - 40
			Elements.place(item.progressBar.instance, 20, 102, barWidth, 6)

			if cw < 450 then
				item.meterLabel.Position = UDim2.fromOffset(20, 114)
				item.meterLabel.Size = UDim2.fromOffset(cw - 40, 18)
				Elements.place(item.claimBtn, 20, 136, cw - 40, 38)
			else
				local btnWidth = math.min(180, math.floor(cw * 0.40))
				item.meterLabel.Position = UDim2.fromOffset(20, 120)
				item.meterLabel.Size = UDim2.fromOffset(cw - btnWidth - 30, 24)
				Elements.place(item.claimBtn, cw - btnWidth - 20, 116, btnWidth, 38)
			end
		end

		local rows = math.ceil(#cards / columns)
		return y + rows * (cardH + spacing) + 30
	end)
end

return ScreenContracts

