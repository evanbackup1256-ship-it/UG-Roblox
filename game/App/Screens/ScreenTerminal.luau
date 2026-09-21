--!strict
-- ScreenTerminal: Command terminal for promo codes, broadcasts, and system patch notes
local AppContext = require(script.Parent.Parent.AppContext)

local ScreenTerminal = {}

function ScreenTerminal.build(ctx: AppContext.Context)
	local Elements = ctx.Elements
	local Buttons = ctx.Buttons
	local Inputs = ctx.Inputs
	local Feedback = ctx.Feedback
	local C = ctx.C
	local Config = ctx.Config

	local root = ctx.screens.events

	-- =========================================================================
	-- 1. ACCESS CODE TERMINAL
	-- =========================================================================
	local codeCard = Elements.card(root, "CodeTerminal", 150, C.card)


	local codeBadge = Elements.badge(codeCard, "SECURE BROADCAST LINK", "azure", true)
	Elements.place(codeBadge, 24, 20, 180, 22)

	local codeTitle = Elements.text(codeCard, "Title", "Access Code Decryption", 20, C.textPrimary, true)
	Elements.place(codeTitle, 24, 48, 400, 26)

	local codeSubtitle = Elements.text(
		codeCard,
		"Subtitle",
		"Redeem system broadcast tokens for emergency compute caches and fleet grants.",
		12,
		C.textSecondary
	)
	Elements.place(codeSubtitle, 24, 76, 500, 20)

	local codeInput = Inputs.searchInput(codeCard, "CodeInput", "ENTER ACCESS CODE…", "codes")
	local inputInstance = codeInput.instance:FindFirstChild("TextBox") :: TextBox
	if inputInstance then
		inputInstance.ClearTextOnFocus = false
	end

	local redeemBtn = Buttons.button(codeCard, "RedeemBtn", "Redeem Code", function()
		local text = codeInput.getText()
		local cleanText = string.upper(string.gsub(text, "%s+", ""))
		if cleanText ~= "" then
			Feedback.floatText(codeCard, "Transmitting...", C.accent, UDim2.fromScale(0.5, 0.4))
			ctx.act("code", cleanText)
			codeInput.setText("")
		else
			Feedback.floatText(codeCard, "Enter a valid code", C.danger, UDim2.fromScale(0.5, 0.4))
		end
	end, "primary")

	-- Also allow hitting Enter on the keyboard
	if inputInstance then
		ctx.connect(inputInstance.FocusLost, function(enterPressed)
			if enterPressed then
				local text = codeInput.getText()
				local cleanText = string.upper(string.gsub(text, "%s+", ""))
				if cleanText ~= "" then
					Feedback.floatText(codeCard, "Transmitting...", C.accent, UDim2.fromScale(0.5, 0.4))
					ctx.act("code", cleanText)
					codeInput.setText("")
				end
			end
		end)
	end

	-- =========================================================================
	-- 2. SYSTEM PATCH NOTES / CHANGELOG
	-- =========================================================================
	local activeChangelog = Config.Changelog or (Config.Changelogs and Config.Changelogs[1]) or {
		version = "2.0.0",
		date = "2026-09-20",
		title = "Systems Architecture Overhaul",
		tag = "RELEASE",
		entries = { "Complete ground-up client rebuild", "Physical spring physics kinetics" },
	}

	local logCard = Elements.card(root, "SystemLog", 260, C.card)


	local tagType = if activeChangelog.tag == "RELEASE" then "mint"
		elseif activeChangelog.tag == "MAJOR" then "amber"
		else "azure"

	local logBadge = Elements.badge(logCard, "FIRMWARE v" .. activeChangelog.version .. " · " .. (activeChangelog.tag or "STABLE"), tagType, true)
	Elements.place(logBadge, 24, 20, 220, 22)

	local logTitle = Elements.text(logCard, "Title", activeChangelog.title, 20, C.textPrimary, true)
	Elements.place(logTitle, 24, 48, 480, 26)

	local logDate = Elements.text(logCard, "Date", "Published " .. activeChangelog.date, 11, C.textMuted, true)
	Elements.place(logDate, 24, 76, 300, 18)

	-- Bullet list of entries
	local entryLabels: { TextLabel } = {}
	for i, entryText in ipairs(activeChangelog.entries or {}) do
		local entryRow = Elements.text(
			logCard,
			"Entry_" .. i,
			string.format("›  %s", entryText),
			13,
			C.textSecondary
		)
		entryRow.TextWrapped = true
		entryLabels[i] = entryRow
	end

	-- Acknowledge button
	local ackBtn = Buttons.button(logCard, "AckBtn", "Acknowledge Update", function()
		Feedback.floatText(logCard, "Firmware verified", C.mint, UDim2.fromScale(0.5, 0.4))
		ctx.act("changelog")
	end, "secondary")

	-- =========================================================================
	-- 3. STATE BINDING
	-- =========================================================================
	ctx.bind("events", function(s)
		local unread = s.changelogVersion ~= activeChangelog.version
		Buttons.enable(
			ackBtn,
			unread,
			if unread then "Acknowledge Release" else "Firmware Synchronized",
			true
		)
	end)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	ctx.layoutScreen("events", function(w)
		local y = 20
		local isCompact = w < 600

		-- Place code card
		local codeCardHeight = if isCompact then 180 else 150
		Elements.place(codeCard, 0, y, w, codeCardHeight)

		if isCompact then
			Elements.place(codeBadge, 20, 18, 170, 22)
			Elements.place(codeTitle, 20, 44, w - 40, 24)
			Elements.place(codeSubtitle, 20, 70, w - 40, 20)
			Elements.place(codeInput.instance, 20, 96, w - 40, 36)
			Elements.place(redeemBtn, 20, 136, w - 40, 36)
		else
			Elements.place(codeBadge, 24, 20, 180, 22)
			Elements.place(codeTitle, 24, 48, w - 48, 26)
			Elements.place(codeSubtitle, 24, 76, w - 48, 20)
			local inputWidth = w - 210
			Elements.place(codeInput.instance, 24, 102, inputWidth, 38)
			Elements.place(redeemBtn, w - 170, 102, 146, 38)
		end

		y += codeCardHeight + 16

		-- Place log card
		local entriesTotalHeight = #entryLabels * 24
		local logCardHeight = 110 + entriesTotalHeight + 56
		Elements.place(logCard, 0, y, w, logCardHeight)

		Elements.place(logBadge, 24, 20, 220, 22)
		Elements.place(logTitle, 24, 48, w - 48, 26)
		Elements.place(logDate, 24, 76, 300, 18)

		local entryY = 104
		for _, lbl in ipairs(entryLabels) do
			Elements.place(lbl, 24, entryY, w - 48, 22)
			entryY += 24
		end

		Elements.place(ackBtn, 24, entryY + 10, math.min(220, w - 48), 38)

		y += logCardHeight + 20
		return y
	end)
end

return ScreenTerminal

