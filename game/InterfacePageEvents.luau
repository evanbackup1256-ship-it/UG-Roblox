--!strict
local MarketplaceService = game:GetService("MarketplaceService")

local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageEvents = {}

function InterfacePageEvents.build(Shared: InterfaceShared.Shared)
	local Kit = Shared.Kit
	local C = Shared.C
	local Config = Shared.Config
	local positionText = Shared.positionText
	local liven = Shared.liven
	local bind = Shared.bind
	local layoutPage = Shared.layoutPage
	local relayout = Shared.relayout
	local connect = Shared.connect

	local pageRoot = Shared.pages.events

	-- =========================================================================
	-- 1. PROMO CODE TERMINAL
	-- =========================================================================
	local codes = Kit.interactiveCard(pageRoot, "CodesVault", 240, C.panel)
	Kit.place(Kit.icon(codes, "Icon", "codes", C.accent), 22, 22, 22, 22)

	local codeBadge = Kit.badge(codes, "Promo Codes", "accent", true)
	Kit.place(codeBadge, 54, 16, 96, 20)

	local codeTitle = positionText(codes, "Title", "Code Redemption", 54, 38, 500, 26, 18, C.text, true)
	local codeDetail = positionText(
		codes,
		"Detail",
		"Promo codes are verified by the server and may be redeemed once per account.",
		22,
		68,
		600,
		30,
		12,
		C.textSub
	)
	codeDetail.TextWrapped = true

	local codeStatus = positionText(codes, "Status", "Checking code status…", 22, 102, 600, 20, 11, C.accent, true)
	codeStatus.Font = Enum.Font.RobotoMono

	local codeInput = Kit.input(codes, "CodeInput", "Enter redemption code…")

	local function submitCode()
		local code = string.sub(codeInput.Text, 1, 32)
		if code ~= "" then
			Kit.fanfare(codes, C.accent)
			Kit.floatText(codes, "Redeeming…", C.accent, Vector2.new(0.5, 0.45))
			Shared.fn.act("code", code)
		end
	end

	local redeemBtn = liven(Kit.button(codes, "Redeem", "Redeem Code", submitCode, "primary"))

	local sanitizing = false
	connect(codeInput:GetPropertyChangedSignal("Text"), function()
		if sanitizing then return end
		local clean = string.sub(string.upper(string.gsub(codeInput.Text, "[^%w%-]", "")), 1, 32)
		if clean == codeInput.Text then return end
		sanitizing = true
		codeInput.Text = clean
		codeInput.CursorPosition = #clean + 1
		sanitizing = false
	end)

	connect(codeInput.FocusLost, function(enter)
		if enter then submitCode() end
	end)

	local totalCodesCount = 0
	for _ in Config.Codes do
		totalCodesCount += 1
	end

	bind("events", function(s)
		local redeemedCount = 0
		for _ in s.codes or {} do
			redeemedCount += 1
		end
		codeStatus.Text = string.format("%d active codes available  ·  %d redeemed", totalCodesCount, redeemedCount)
	end)

	-- =========================================================================
	-- 2. FLEET BULLETINS & CHANGELOG
	-- =========================================================================
	local changelogIndex = 1
	local news = Kit.interactiveCard(pageRoot, "ChangelogHero", 370, C.panel)

	local newsEyebrow = positionText(news, "Eyebrow", "", 22, 18, 500, 20, 11, C.accent, true)
	newsEyebrow.Font = Enum.Font.RobotoMono

	local newsTitle = positionText(news, "Title", "", 22, 42, 500, 28, 20, C.text, true)
	local newsDate = positionText(news, "Date", "", 22, 72, 500, 20, 11, C.muted)
	newsDate.Font = Enum.Font.RobotoMono

	local notes = {}
	for i = 1, 4 do
		local text = positionText(news, "Entry" .. i, "", 22, 98 + (i - 1) * 40, 600, 32, 13, C.textSub)
		text.TextWrapped = true
		notes[i] = text
	end

	local changelogPrev = Kit.button(news, "Previous", "Older", function()
		changelogIndex = math.min(#Config.Changelogs, changelogIndex + 1)
		relayout("events")
	end, "secondary")

	local changelogPage = Kit.text(news, "Page", "", 11, C.muted, true)
	changelogPage.Font = Enum.Font.RobotoMono
	changelogPage.TextXAlignment = Enum.TextXAlignment.Center

	local changelogNext = Kit.button(news, "Next", "Newer", function()
		changelogIndex = math.max(1, changelogIndex - 1)
		relayout("events")
	end, "secondary")

	local markReadBtn = liven(Kit.button(news, "MarkRead", "Acknowledge", function()
		Shared.fn.act("changelog")
	end, "primary"))

	local function refreshChangelog()
		local bulletin = Config.Changelogs[changelogIndex]
		if not bulletin then return end

		newsEyebrow.Text = bulletin.tag .. " · Version " .. bulletin.version
		newsTitle.Text = bulletin.title
		newsDate.Text = "Released: " .. bulletin.date

		for index, label in ipairs(notes) do
			local copy = bulletin.entries[index]
			label.Visible = copy ~= nil
			label.Text = if copy then string.format("%02d   %s", index, copy) else ""
		end

		changelogPage.Text = string.format("%d / %d", changelogIndex, #Config.Changelogs)
		Kit.enable(changelogPrev, changelogIndex < #Config.Changelogs, "Older", false)
		Kit.enable(changelogNext, changelogIndex > 1, "Newer", false)
	end

	bind("events", function(s)
		local read = s.changelogVersion == Config.Changelog.version
		Kit.enable(markReadBtn, not read, if read then "Acknowledged" else "Acknowledge Update", true)
	end)

	-- =========================================================================
	-- 3. FLEET SUBSCRIPTION & CLOUD SUPPORT
	-- =========================================================================
	local support = Kit.interactiveCard(pageRoot, "SupportVault", 160, C.panel)
	positionText(support, "Title", "Fleet Network Passes", 22, 18, 600, 26, 18, C.text, true)
	local supportSub = positionText(support, "Detail", "Permanent game passes and server infrastructure upgrades.", 22, 44, 600, 22, 12, C.textSub)

	local paidButtons = {}
	for key, id in Config.Gamepasses do
		if id > 0 then
			table.insert(paidButtons, Kit.button(support, key, if key == "Founder" then "Founder Pass" else "2× Fleet Output", function()
				MarketplaceService:PromptGamePassPurchase(Shared.player, id)
			end, "secondary"))
		end
	end

	for key, product in Config.Products do
		if product.id > 0 then
			table.insert(paidButtons, Kit.button(support, key, product.name, function()
				MarketplaceService:PromptProductPurchase(Shared.player, product.id)
			end, "primary"))
		end
	end

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	layoutPage("events", function(w)
		local narrow = w < 640

		-- 1. Codes Vault
		Kit.place(codes, 0, 137, w, if narrow then 250 else 210)
		codeTitle.Size = UDim2.fromOffset(w - 44, 26)
		codeDetail.Size = UDim2.fromOffset(w - 44, 30)
		if narrow then
			Kit.place(codeInput, 22, 132, w - 44, 40)
			Kit.place(redeemBtn, 22, 182, w - 44, 40)
		else
			Kit.place(codeInput, 22, 134, math.max(120, w - 210), 40)
			Kit.place(redeemBtn, w - 176, 134, 154, 40)
		end

		local newsY = 137 + (if narrow then 250 else 210) + 16

		-- 2. Changelog
		Kit.place(news, 0, newsY, w, 370)
		newsTitle.Size = UDim2.fromOffset(w - 44, 28)
		for _, label in ipairs(notes) do
			label.Size = UDim2.fromOffset(w - 44, 32)
		end

		local controlsY = 312
		if narrow then
			Kit.place(changelogPrev, 22, controlsY, 70, 36)
			Kit.place(changelogPage, 98, controlsY, 60, 36)
			Kit.place(changelogNext, 164, controlsY, 70, 36)
			Kit.place(markReadBtn, 240, controlsY, w - 262, 36)
		else
			Kit.place(changelogPrev, 22, controlsY, 86, 38)
			Kit.place(changelogPage, 114, controlsY, 70, 38)
			Kit.place(changelogNext, 190, controlsY, 86, 38)
			Kit.place(markReadBtn, w - 210, controlsY, 188, 38)
		end
		refreshChangelog()

		local supportY = newsY + 370 + 16

		-- 3. Support
		Kit.place(support, 0, supportY, w, 160)
		local btnW = math.clamp((w - 44 - (#paidButtons - 1) * 12) / math.max(1, #paidButtons), 120, 240)
		for i, btn in ipairs(paidButtons) do
			Kit.place(btn, 22 + (i - 1) * (btnW + 12), 88, btnW, 40)
		end

		return supportY + 160 + 16
	end)
end

return InterfacePageEvents
