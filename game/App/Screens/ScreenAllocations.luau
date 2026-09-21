--!strict
-- ScreenAllocations: Daily fleet allocation streak and career milestone achievements
local AppContext = require(script.Parent.Parent.AppContext)

local ScreenAllocations = {}

function ScreenAllocations.build(ctx: AppContext.Context)
	local Elements = ctx.Elements
	local Buttons = ctx.Buttons
	local Feedback = ctx.Feedback
	local C = ctx.C
	local Config = ctx.Config
	local fmt = ctx.fmt

	local root = ctx.screens.rewards

	-- =========================================================================
	-- 1. DAILY STREAK CALENDAR HERO
	-- =========================================================================
	local daily = Elements.interactiveCard(root, "DailyRewardHero", 175, C.card)


	local streakBadge = Elements.badge(daily, "Day 1 Streak", "accent", true)
	Elements.place(streakBadge, 24, 20, 110, 22)

	local dailyTitle = Elements.text(daily, "Title", "Daily Fleet Allocation.", 22, C.textPrimary, true)
	Elements.place(dailyTitle, 24, 48, 550, 30)

	local dailyDetail = Elements.text(daily, "Detail", "", 12, C.textSecondary)
	dailyDetail.TextWrapped = true
	Elements.place(dailyDetail, 24, 80, 550, 24)

	local dailyBtn = Buttons.button(daily, "ClaimDaily", "Collect Reward", function()
		if ctx.state then
			local streak = (ctx.state.daily and ctx.state.daily.streak) or 0
			local rewardVal = 100 + (streak + 1) * 50
			Feedback.confetti(daily, C.accent)
			Feedback.ringPulse(daily, UDim2.fromScale(0.5, 0.5), C.accent)
			Feedback.floatText(daily, "+" .. fmt(rewardVal) .. " Compute", C.compute, UDim2.fromScale(0.5, 0.45))
		end
		ctx.act("daily")
	end, "primary")
	Elements.place(dailyBtn, 24, 114, 180, 42)

	-- =========================================================================
	-- 2. CAREER ACHIEVEMENTS
	-- =========================================================================
	local achievements = {}
	for i, item in ipairs(Config.Achievements) do
		local card = Elements.interactiveCard(root, "Achievement_" .. item.key, 145, C.card)

		local icon = Elements.icon(card, "Icon", item.icon or "rewards", C.accent)
		Elements.place(icon, 20, 20, 22, 22)

		local title = Elements.text(card, "Title", item.name, 16, C.textPrimary, true)
		Elements.place(title, 52, 18, 300, 24)

		local detail = Elements.text(card, "Detail", item.subtitle or "Fleet career milestone", 12, C.textSecondary)
		detail.TextWrapped = true
		Elements.place(detail, 20, 48, 320, 30)

		local claimBtn = Buttons.button(card, "ClaimBtn", "Claim Payout", function()
			Feedback.confetti(card, C.gold)
			Feedback.floatText(card, "Milestone Unlocked!", C.gold, UDim2.fromScale(0.5, 0.45))
			ctx.act("achievement", item.key)
		end, "secondary")
		Elements.place(claimBtn, 20, 92, 140, 38)

		achievements[i] = {
			item = item,
			card = card,
			title = title,
			detail = detail,
			claimBtn = claimBtn,
			glow = nil,
		}
	end

	-- =========================================================================
	-- 3. STATE BINDING
	-- =========================================================================
	local dailyGlow: any = nil

	ctx.bind("rewards", function(s)
		local d = s.daily or {}
		local streak = d.streak or 0
		local reward = 100 + (streak + 1) * 50
		local ready = d.canClaim == true

		local badgeText = streakBadge:FindFirstChild("BadgeText") :: TextLabel?
		if badgeText then
			badgeText.Text = string.format("DAY %d STREAK", streak + 1)
		end
		dailyDetail.Text = if ready
			then string.format("Your regular daily grant is available: +%s Compute. Keep your streak active!", fmt(reward))
			else "Your daily allocation has been claimed for today. Check back tomorrow."

		if ready and not dailyGlow and (ctx.preferences and ctx.preferences.motion ~= false) then
			dailyGlow = Feedback.ambientGlow(daily, { color = C.accent })
		elseif not ready and dailyGlow then
			dailyGlow.stop()
			dailyGlow = nil
		end

		Buttons.enable(
			dailyBtn,
			ready,
			if ready then "Claim · +" .. fmt(reward) .. " C" else "Claimed Today",
			true
		)

		for _, ach in ipairs(achievements) do
			local metricVal = if ach.item.metric == "rate"
				then Config.rate(s)
				else ((s.achievementMetrics and s.achievementMetrics[ach.item.metric]) or 0)
			local done = (s.achievements and s.achievements[ach.item.key]) == true
			local readyToClaim = not done and metricVal >= ach.item.target

			if readyToClaim then
				if not ach.glow and (ctx.preferences and ctx.preferences.motion ~= false) then
					ach.glow = Feedback.ambientGlow(ach.card, { color = Color3.fromRGB(245, 158, 11) })
				end
			else
				if ach.glow then
					ach.glow.stop()
					ach.glow = nil
				end
			end

			Feedback.lock(ach.card, done and not readyToClaim, ach.claimBtn)
			Buttons.enable(
				ach.claimBtn,
				readyToClaim,
				if done then "Completed"
					elseif readyToClaim then "Claim · +" .. fmt(ach.item.reward) .. " C"
					else fmt(math.min(metricVal, ach.item.target)) .. " / " .. fmt(ach.item.target),
				true
			)
		end
	end)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	ctx.layoutScreen("rewards", function(w)
		local isNarrow = w < 640
		local heroH = if isNarrow then 195 else 175
		Elements.place(daily, 0, 0, w, heroH)
		dailyTitle.Size = UDim2.fromOffset(w - 48, 30)
		dailyDetail.Size = UDim2.fromOffset(w - 48, if isNarrow then 40 else 24)

		if isNarrow then
			Elements.place(dailyBtn, 24, 134, w - 48, 44)
		else
			Elements.place(dailyBtn, 24, 114, 200, 42)
		end

		local gridStartY = heroH + 16
		local cols = if w >= 860 then 2 else 1
		local cardW = math.floor((w - (cols - 1) * 16) / cols)
		local cardH = 145

		for idx, ach in ipairs(achievements) do
			local localIdx = idx - 1
			local col = localIdx % cols
			local row = localIdx // cols
			local cx = col * (cardW + 16)
			local cy = gridStartY + row * (cardH + 16)

			Elements.place(ach.card, cx, cy, cardW, cardH)
			ach.title.Size = UDim2.fromOffset(cardW - 80, 24)
			ach.detail.Size = UDim2.fromOffset(cardW - 40, 30)
			Elements.place(ach.claimBtn, 20, 92, math.min(220, cardW - 40), 38)
		end

		local totalRows = math.ceil(#achievements / cols)
		return gridStartY + totalRows * (cardH + 16) + 32
	end)
end

return ScreenAllocations

