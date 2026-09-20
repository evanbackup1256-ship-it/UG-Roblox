--!strict
local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageRewards = {}

function InterfacePageRewards.build(Shared: InterfaceShared.Shared)
	local Kit = Shared.Kit
	local C = Shared.C
	local Config = Shared.Config
	local positionText = Shared.positionText
	local liven = Shared.liven
	local bind = Shared.bind
	local layoutPage = Shared.layoutPage
	local fmt = Shared.fmt

	local pageRoot = Shared.pages.rewards

	-- =========================================================================
	-- 1. DAILY ALLOCATION HERO CARD
	-- =========================================================================
	local daily = Kit.interactiveCard(pageRoot, "DailyRewardHero", 175, C.panel)

	local streakBadge = Kit.badge(daily, "Day 1 Streak", "accent", true)
	Kit.place(streakBadge, 24, 20, 110, 20)

	local dailyTitle = positionText(daily, "Title", "Daily Fleet Allocation.", 24, 46, 550, 30, 22, C.text, true)
	local dailyDetail = positionText(daily, "Detail", "", 24, 78, 550, 24, 12, C.textSub)
	dailyDetail.TextWrapped = true

	local dailyButton = liven(Kit.button(daily, "ClaimDaily", "Collect Reward", function()
		if Shared.state then
			local streak = (Shared.state.daily and Shared.state.daily.streak) or 0
			local rewardVal = 100 + (streak + 1) * 50
			Kit.fanfare(daily, C.accent)
			Kit.floatText(daily, "+" .. fmt(rewardVal) .. " Compute", C.compute, Vector2.new(0.5, 0.45))
		end
		Shared.fn.act("daily")
	end, "primary"))

	local dailyGlow: any = nil
	local isUnclaimed = false
	local function syncDailyGlow()
		local wanted = isUnclaimed and (Shared.preferences.motion ~= false)
		if wanted and not dailyGlow then
			dailyGlow = Kit.ambientGlow(daily, { color = C.accent })
		elseif not wanted and dailyGlow then
			dailyGlow.stop()
			dailyGlow = nil
		end
	end
	table.insert(Shared.fn.settingRefresh, syncDailyGlow)

	-- =========================================================================
	-- 2. CAREER ACHIEVEMENTS
	-- =========================================================================
	local achievements = {}
	for i, item in ipairs(Config.Achievements) do
		local card = Kit.interactiveCard(pageRoot, "Achievement_" .. item.key, 150, C.panel)

		Kit.place(Kit.icon(card, "Icon", item.icon or "rewards", C.accent), 20, 20, 22, 22)

		local title = positionText(card, "Title", item.name, 52, 18, 350, 24, 16, C.text, true)
		local detail = positionText(card, "Detail", item.subtitle, 20, 48, 350, 32, 12, C.textSub)
		detail.TextWrapped = true

		local claimBtn = liven(Kit.button(card, "Unlock", "", function()
			Kit.fanfare(card, C.gold)
			Kit.floatText(card, "Achievement Unlocked", C.gold, Vector2.new(0.5, 0.45))
			Shared.fn.act("achievement", item.key)
			Kit.bump(title, 1.05)
		end, "secondary"))

		achievements[i] = {
			card = card,
			item = item,
			title = title,
			detail = detail,
			claimBtn = claimBtn,
		}

		local lastDone: boolean? = nil
		bind("rewards", function(s)
			local metric = if item.metric == "rate"
				then (s.rate or 0)
				else ((s.achievementMetrics and s.achievementMetrics[item.metric]) or 0)
			local done = (s.achievements and s.achievements[item.key]) == true

			if lastDone ~= nil and not lastDone and done then
				Kit.fanfare(card, C.gold)
			end
			lastDone = done

			local readyToClaim = not done and metric >= item.target
			Kit.enable(
				claimBtn,
				readyToClaim,
				if done then "Unlocked"
					elseif readyToClaim then "Claim Reward"
					else fmt(math.min(metric, item.target)) .. " / " .. fmt(item.target),
				true
			)
		end)
	end

	-- =========================================================================
	-- 3. STATE BINDING (DAILY)
	-- =========================================================================
	bind("rewards", function(s)
		local today = os.date("!%Y-%m-%d", os.time())
		local streak = (s.daily and s.daily.streak) or 0
		local claimed = (s.daily and s.daily.day) == today
		isUnclaimed = not claimed
		syncDailyGlow()

		streakBadge.Text.Text = string.format("Day %d Streak", math.max(1, streak))

		dailyDetail.Text = if claimed
			then "Day " .. streak .. " allocation collected. Return tomorrow for the next distribution."
			else "Next allocation drop · " .. fmt(100 + (streak + 1) * 50) .. " compute"

		Kit.enable(
			dailyButton,
			not claimed,
			if claimed then "Claimed Today" else "Collect Daily Allocation",
			true
		)
	end)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	layoutPage("rewards", function(w)
		local narrow = w < 680

		Kit.place(daily, 0, 137, w, if narrow then 185 else 175)
		dailyTitle.Size = UDim2.fromOffset(w - 48, 30)
		dailyDetail.Size = UDim2.fromOffset(w - 48, 24)
		Kit.place(dailyButton, 24, if narrow then 118 else 112, math.min(260, w - 48), 40)

		local gridStartY = 137 + (if narrow then 185 else 175) + 16

		local columns = if w >= 880 then 2 else 1
		local cardWidth = (w - (columns - 1) * 16) / columns
		local cardHeight = 150

		for idx, item in ipairs(achievements) do
			local localIdx = idx - 1
			local col = localIdx % columns
			local row = localIdx // columns

			local cardX = col * (cardWidth + 16)
			local cardY = gridStartY + row * (cardHeight + 16)

			Kit.place(item.card, cardX, cardY, cardWidth, cardHeight)

			item.title.Size = UDim2.fromOffset(cardWidth - 80, 24)
			item.detail.Size = UDim2.fromOffset(cardWidth - 40, 32)
			Kit.place(item.claimBtn, 20, 96, cardWidth - 40, 38)
		end

		local totalRows = math.ceil(#achievements / columns)
		return gridStartY + totalRows * (cardHeight + 16)
	end)
end

return InterfacePageRewards
