local InterfaceShared = require(script.Parent.InterfaceShared)

local InterfacePageRewards = {}

function InterfacePageRewards.build(Shared: InterfaceShared.Shared)
	local Kit, C, Config = Shared.Kit, Shared.C, Shared.Config
	local positionText, liven = Shared.positionText, Shared.liven
	local bind, layoutPage = Shared.bind, Shared.layoutPage
	local fmt = Shared.fmt

	local daily = Kit.card(Shared.pages.rewards, "Daily", 180, C.paper)
	local dailyTitle = positionText(daily, "Title", "Your daily drop.", 22, 22, 550, 34, 25, C.ink, true)
	local dailyDetail = positionText(daily, "Detail", "", 22, 64, 550, 26, 14, C.ink)
	dailyDetail.TextWrapped = true

	local dailyButton = liven(Kit.button(daily, "ClaimDaily", "Claim reward", function()
		Shared.fn.act("daily")
	end, "primary"))

	bind("rewards", function(s)
		-- GetServerTimeNow() is seconds since the server booted, not a Unix
		-- timestamp — feeding it to os.date produced a bogus date that
		-- rarely matched the real calendar day RewardService.daily checks
		-- against server-side, so the button's claimed/available state
		-- would disagree with the server until a claim attempt corrected
		-- it. os.time() matches what the server actually compares against.
		local today = os.date("!%Y-%m-%d", os.time())
		local streak = s.daily.streak or 0
		local claimed = s.daily.day == today

		dailyDetail.Text = if claimed
			then "Day " .. streak .. " collected. See you tomorrow."
			else "Next drop · " .. fmt(100 + (streak + 1) * 50) .. " compute"

		Kit.enable(dailyButton, not claimed, if claimed then "Collected today" else "Collect daily reward", true)
	end)

	local achievements = {}
	for i, item in ipairs(Config.Achievements) do
		local card = Kit.card(Shared.pages.rewards, "Achievement_" .. item.key, 154)

		Kit.place(Kit.icon(card, "Icon", item.icon or "rewards", C.accent), 20, 20, 24, 24)

		local title = positionText(card, "Title", item.name, 56, 18, 350, 26, 17, C.text, true)
		local detail = positionText(card, "Detail", item.subtitle, 20, 52, 350, 36, 12, C.muted)
		detail.TextWrapped = true

		local claim = liven(Kit.button(card, "Unlock", "", function()
			Shared.fn.act("achievement", item.key)
			Kit.bump(title, 1.12)
		end))

		achievements[i] = {
			card = card,
			title = title,
			detail = detail,
			claim = claim,
		}

		bind("rewards", function(s)
			local metric = if item.metric == "rate" then s.rate or 0 else s.achievementMetrics[item.metric] or 0
			local done = s.achievements[item.key]

			Kit.enable(
				claim,
				not done and metric >= item.target,
				if done then "Unlocked"
					elseif metric >= item.target then "Collect achievement"
					else fmt(math.min(metric, item.target)) .. " / " .. fmt(item.target),
				true
			)
		end)
	end

	layoutPage("rewards", function(w)
		Kit.place(daily, 0, 137, w, 180)
		dailyTitle.Size = UDim2.fromOffset(w - 44, 34)
		dailyDetail.Size = UDim2.fromOffset(w - 44, 44)
		Kit.place(dailyButton, 22, 112, math.min(280, w - 44), 44)

		local columns = if w >= 730 then 2 else 1
		local cw = (w - (columns - 1) * 16) / columns

		for i, item in ipairs(achievements) do
			Kit.place(
				item.card,
				((i - 1) % columns) * (cw + 16),
				337 + ((i - 1) // columns) * 170,
				cw,
				154
			)
			item.title.Size = UDim2.fromOffset(cw - 76, 26)
			item.detail.Size = UDim2.fromOffset(cw - 40, 36)
			Kit.place(item.claim, 20, 100, cw - 40, 44)
		end

		return 337 + math.ceil(#achievements / columns) * 170
	end)
end

return InterfacePageRewards
