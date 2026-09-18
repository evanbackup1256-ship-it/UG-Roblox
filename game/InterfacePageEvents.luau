local MarketplaceService = game:GetService("MarketplaceService")

local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageEvents = {}

function InterfacePageEvents.build(Shared: InterfaceShared.Shared)
	local Kit, C, Config = Shared.Kit, Shared.C, Shared.Config
	local positionText, liven = Shared.positionText, Shared.liven
	local bind, layoutPage, relayout = Shared.bind, Shared.layoutPage, Shared.relayout
	local connect = Shared.connect

	local codes = Kit.card(Shared.pages.events, "Codes", 260)
	Kit.place(Kit.icon(codes, "Icon", "codes", C.accent), 22, 22, 24, 24)

	local codeTitle = positionText(codes, "Title", "Redeem center", 58, 18, 500, 30, 22, C.text, true)
	codeTitle.TextWrapped = true
	codeTitle.TextTruncate = Enum.TextTruncate.None

	local codeDetail = positionText(codes, "Detail", "Codes are validated by the server and can only be claimed once per save.", 22, 60, 600, 38, 13, C.muted)
	codeDetail.TextWrapped = true

	local codeStatus = positionText(codes, "Status", "CHECKING REWARD HISTORY", 22, 102, 600, 22, 10, C.accent, true)

	local codeInput = Kit.input(codes, "CodeInput", "Enter reward code")

	local function submitCode()
		local code = string.sub(codeInput.Text, 1, 32)
		if code ~= "" then
			Shared.fn.act("code", code)
		end
	end

	local redeem = liven(Kit.button(codes, "Redeem", "Redeem code", submitCode, true))

	local sanitizing = false
	connect(codeInput:GetPropertyChangedSignal("Text"), function()
		if sanitizing then
			return
		end

		local clean = string.sub(string.upper((string.gsub(codeInput.Text, "[^%w%-]", ""))), 1, 32)
		if clean == codeInput.Text then
			return
		end

		sanitizing = true
		codeInput.Text = clean
		codeInput.CursorPosition = #clean + 1
		sanitizing = false
	end)

	connect(codeInput.FocusLost, function(enter)
		if enter then
			submitCode()
		end
	end)

	local activeCodes = 0
	for _ in Config.Codes do
		activeCodes += 1
	end

	bind("events", function(s)
		local redeemed = 0
		for _ in s.codes or {} do
			redeemed += 1
		end
		codeStatus.Text = string.format("%d ACTIVE REWARDS  ·  %d REDEEMED", activeCodes, redeemed)
	end)

	local changelogIndex = 1
	local news = Kit.card(Shared.pages.events, "Changelog", 400)

	local newsEyebrow = positionText(news, "Eyebrow", "", 22, 22, 500, 22, 11, C.accent, true)
	local newsTitle = positionText(news, "Title", "", 22, 55, 500, 34, 25, C.text, true)
	newsTitle.TextWrapped = true
	newsTitle.TextTruncate = Enum.TextTruncate.None

	local newsDate = positionText(news, "Date", "", 22, 88, 500, 22, 11, C.muted)

	local notes = {}
	for i = 1, 4 do
		local text = positionText(news, "Entry" .. i, "", 22, 116 + (i - 1) * 44, 600, 36, 13, C.muted)
		text.TextWrapped = true
		text.TextTruncate = Enum.TextTruncate.None
		notes[i] = text
	end

	local changelogPrev = Kit.button(news, "Previous", "Older", function()
		changelogIndex = math.min(#Config.Changelogs, changelogIndex + 1)
		relayout("events")
	end)

	local changelogPage = Kit.text(news, "Page", "", 11, C.muted, true)
	changelogPage.TextXAlignment = Enum.TextXAlignment.Center

	local changelogNext = Kit.button(news, "Next", "Newer", function()
		changelogIndex = math.max(1, changelogIndex - 1)
		relayout("events")
	end)

	local markRead = liven(Kit.button(news, "MarkRead", "Mark latest as read", function()
		Shared.fn.act("changelog")
	end, true))

	local function refreshChangelog()
		local bulletin = Config.Changelogs[changelogIndex]
		if not bulletin then
			return
		end

		newsEyebrow.Text = bulletin.tag .. "  /  VERSION " .. bulletin.version
		newsTitle.Text = bulletin.title
		newsDate.Text = bulletin.date

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
		Kit.enable(markRead, not read, if read then "Latest update read" else "Mark latest as read", true)
	end)

	local support = Kit.card(Shared.pages.events, "Support", 160)
	positionText(support, "Title", "Support the cloud", 22, 20, 600, 30, 20, C.text, true)

	local paid = {}
	for key, id in Config.Gamepasses do
		if id > 0 then
			table.insert(paid, Kit.button(support, key, if key == "Founder" then "Founder pass" else "2× production", function()
				MarketplaceService:PromptGamePassPurchase(Shared.player, id)
			end))
		end
	end

	for key, product in Config.Products do
		if product.id > 0 then
			table.insert(paid, Kit.button(support, key, product.name, function()
				MarketplaceService:PromptProductPurchase(Shared.player, product.id)
			end))
		end
	end

	support.Visible = #paid > 0

	layoutPage("events", function(w)
		local narrow = w < 400
		local stacked = w < 520
		local codeHeight = if narrow then 284 else 260

		Kit.place(codes, 0, 137, w, codeHeight)
		codeTitle.Size = UDim2.fromOffset(w - 80, 32)
		codeTitle.TextSize = if narrow then 19 else 22
		codeDetail.Size = UDim2.fromOffset(w - 44, if narrow then 58 else 38)
		codeStatus.Position = UDim2.fromOffset(22, if narrow then 124 else 102)
		codeStatus.Size = UDim2.fromOffset(w - 44, 22)

		Kit.place(codeInput, 22, if narrow then 158 else 142, if stacked then w - 44 else w - 250, 44)
		Kit.place(
			redeem,
			if stacked then 22 else w - 216,
			if stacked then (if narrow then 212 else 196) else 142,
			if stacked then math.min(210, w - 44) else 194,
			44
		)

		local newsY = 157 + codeHeight
		local newsHeight = if narrow then 432 else 400

		Kit.place(news, 0, newsY, w, newsHeight)
		newsTitle.Size = UDim2.fromOffset(w - 44, if narrow then 54 else 34)
		newsTitle.TextSize = if narrow then 21 else 25
		newsDate.Position = UDim2.fromOffset(22, if narrow then 110 else 88)
		newsDate.Size = UDim2.fromOffset(w - 44, 22)

		for index, text in ipairs(notes) do
			text.Position = UDim2.fromOffset(22, (if narrow then 138 else 116) + (index - 1) * (if narrow then 48 else 44))
			text.Size = UDim2.fromOffset(w - 44, if narrow then 42 else 36)
		end

		refreshChangelog()

		local pagerY = if narrow then 378 else 340
		local side = math.min(100, (w - 66) / 3)
		local pageLabelX = 22 + side + 6
		Kit.place(changelogPrev, 22, pagerY, side, 42)
		Kit.place(changelogPage, pageLabelX, pagerY, math.max(1, w - side - pageLabelX - 6), 42)
		Kit.place(changelogNext, w - side, pagerY, side, 42)
		Kit.place(markRead, 22, if narrow then 328 else 292, math.min(210, w - 44), 38)

		if #paid == 0 then
			return newsY + newsHeight
		end

		local supportY = newsY + newsHeight + 20
		Kit.place(support, 0, supportY, w, 70 + #paid * 52)
		for i, button in ipairs(paid) do
			Kit.place(button, 22, 62 + (i - 1) * 52, w - 44, 44)
		end

		return supportY + 70 + #paid * 52
	end)
end

return InterfacePageEvents
