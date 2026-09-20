--!strict
local TweenService = game:GetService("TweenService")

local InterfaceShared = require(script.Parent.InterfaceShared)

local ROW_HEIGHT = 44
local VISIBLE_ROWS = 12

local ROW_FADE, ROW_POP = {}, {}
for step = 0, VISIBLE_ROWS - 1 do
	ROW_FADE[step] = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, step * 0.02)
	ROW_POP[step] = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, step * 0.02)
end

local InterfacePageLeaderboard = {}

function InterfacePageLeaderboard.build(Shared: InterfaceShared.Shared)
	local Kit = Shared.Kit
	local C = Shared.C
	local positionText = Shared.positionText
	local liven = Shared.liven
	local bump = Shared.bump
	local bind = Shared.bind
	local layoutPage = Shared.layoutPage
	local run = Shared.run
	local fmt = Shared.fmt
	local preferences = Shared.preferences

	local pageRoot = Shared.pages.leaderboard
	local requestRefresh

	local CATEGORIES = {
		{ key = "earned", label = "Compute Earned", unit = "COMPUTE" },
		{ key = "prestige", label = "Fleet Relaunches", unit = "RELAUNCHES" },
	}
	local activeCategory = CATEGORIES[1]
	local staggered = false
	local setActiveCategory

	-- =========================================================================
	-- 1. HERO BANNER: STANDINGS & CATEGORY CONTROLS
	-- =========================================================================
	local hero = Kit.card(pageRoot, "StandingsHero", 96, C.panel)
	Kit.place(Kit.icon(hero, "Icon", "leaderboard", C.accent), 22, 22, 22, 22)

	local heroBadge = Kit.badge(hero, "Global Network", "accent", true)
	Kit.place(heroBadge, 54, 16, 110, 20)

	local heroTitle = positionText(hero, "Title", "Fleet Standings", 54, 38, 500, 26, 18, C.text, true)
	local heroDetail = positionText(
		hero,
		"Detail",
		"Rankings reflect verified progress across all servers and update periodically.",
		54,
		64,
		700,
		24,
		12,
		C.textSub
	)
	heroDetail.TextWrapped = true

	local refreshButton = liven(Kit.button(hero, "Refresh", "Refresh", function()
		if requestRefresh then
			requestRefresh()
		end
	end, "secondary"))

	local categorySegment = Kit.segmented(
		hero,
		"Categories",
		{ "Compute", "Relaunches" },
		1,
		function(idx)
			local cat = CATEGORIES[idx]
			if activeCategory.key ~= cat.key and setActiveCategory then
				setActiveCategory(cat)
				if requestRefresh then
					requestRefresh()
				end
			end
		end
	)

	-- =========================================================================
	-- 2. OPERATOR'S PERSONAL RANK CARD
	-- =========================================================================
	local rankCard = Kit.interactiveCard(pageRoot, "YourRank", 72, C.panel)
	local rankLabel = positionText(rankCard, "Label", "Your Global Standing", 20, 14, 220, 18, 11, C.textSub, true)

	local rankValue = positionText(rankCard, "Value", "—", 20, 34, 300, 26, 18, C.accent, true)
	rankValue.Font = Enum.Font.RobotoMono
	local bumpRank = bump(rankValue)

	local updatedLabel = positionText(rankCard, "Updated", "", 0, 14, 260, 18, 11, C.muted, true)
	updatedLabel.Font = Enum.Font.RobotoMono
	updatedLabel.TextXAlignment = Enum.TextXAlignment.Right

	-- =========================================================================
	-- 3. GLOBAL RANKINGS LIST CARD
	-- =========================================================================
	local listCard = Kit.card(pageRoot, "StandingsList", VISIBLE_ROWS * ROW_HEIGHT + 36, C.panel)

	local emptyLabel = positionText(listCard, "Empty", "Connecting to fleet registry…", 20, 24, 600, 30, 14, C.muted)
	emptyLabel.Visible = false

	local skeletons = {}
	for step = 1, VISIBLE_ROWS do
		local bar = Kit.skeleton(listCard, "Skeleton_" .. step, ROW_HEIGHT - 8)
		Kit.place(bar, 16, 16 + (step - 1) * ROW_HEIGHT, 100, ROW_HEIGHT - 8)
		table.insert(skeletons, bar)
	end

	local rows = {}
	for step = 1, VISIBLE_ROWS do
		local row = Kit.create("Frame", listCard, {
			Name = "Row_" .. step,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
		})
		local rowScale = Kit.create("UIScale", row, { Scale = 1 })

		local rank = positionText(row, "Rank", "#—", 16, 0, 44, ROW_HEIGHT, 12, C.muted, true)
		rank.Font = Enum.Font.RobotoMono

		local name = positionText(row, "Name", "", 66, 0, 320, ROW_HEIGHT, 13, C.text, true)
		local score = positionText(row, "Score", "", 0, 0, 220, ROW_HEIGHT, 12, C.accent, true)
		score.Font = Enum.Font.RobotoMono
		score.TextXAlignment = Enum.TextXAlignment.Right

		local divider = Kit.create("Frame", row, {
			Name = "Divider",
			Position = UDim2.new(0, 16, 1, -1),
			Size = UDim2.new(1, -32, 0, 1),
			BackgroundColor3 = C.line,
			BackgroundTransparency = 0.65,
			BorderSizePixel = 0,
		})

		rows[step] = {
			row = row,
			scale = rowScale,
			rank = rank,
			name = name,
			score = score,
			divider = divider,
		}
	end

	setActiveCategory = function(category)
		activeCategory = category
		staggered = false
	end

	local function populateList(entries, yourRank, lastUpdated)
		for _, sk in ipairs(skeletons) do
			sk.Visible = false
		end

		if not entries or #entries == 0 then
			emptyLabel.Visible = true
			emptyLabel.Text = "No rankings recorded for this category yet."
			for _, r in ipairs(rows) do
				r.row.Visible = false
			end
			return
		end

		emptyLabel.Visible = false

		if yourRank then
			rankValue.Text = "#" .. yourRank
			bumpRank()
		else
			rankValue.Text = "Unranked"
		end

		if lastUpdated then
			updatedLabel.Text = "Updated " .. string.upper(lastUpdated)
		end

		local shouldAnimate = not staggered and (preferences.motion ~= false)
		staggered = true

		for step = 1, VISIBLE_ROWS do
			local data = entries[step]
			local r = rows[step]

			if data then
				r.row.Visible = true
				r.rank.Text = string.format("#%02d", step)
				r.name.Text = data.name or ("Operator " .. (data.key or step))
				r.score.Text = fmt(data.score or 0) .. " " .. activeCategory.unit

				-- Podium Highlighting
				if step == 1 then
					r.rank.TextColor3 = C.gold
					r.name.TextColor3 = C.gold
				elseif step == 2 then
					r.rank.TextColor3 = Color3.fromRGB(203, 213, 225)
					r.name.TextColor3 = Color3.fromRGB(241, 245, 249)
				elseif step == 3 then
					r.rank.TextColor3 = Color3.fromRGB(217, 119, 6)
					r.name.TextColor3 = C.text
				else
					r.rank.TextColor3 = C.muted
					r.name.TextColor3 = C.text
				end

				if shouldAnimate then
					local stepIdx = step - 1
					r.row.BackgroundTransparency = 0.5
					r.scale.Scale = 0.98

					local fadeTween = TweenService:Create(r.row, ROW_FADE[stepIdx], { BackgroundTransparency = 1 })
					Kit.Scheduler.track(r.row, "reveal", fadeTween)
					fadeTween:Play()

					local popTween = TweenService:Create(r.scale, ROW_POP[stepIdx], { Scale = 1 })
					Kit.Scheduler.track(r.scale, "reveal", popTween)
					popTween:Play()
				end
			else
				r.row.Visible = false
			end
		end
	end

	requestRefresh = function()
		run(function()
			local ok, res = pcall(Shared.Leaderboard.InvokeServer, Shared.Leaderboard, activeCategory.key)
			if ok and type(res) == "table" then
				populateList(res.entries, res.yourRank, res.updated)
			end
		end)
	end

	bind("leaderboard", function(s)
		requestRefresh()
	end)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	layoutPage("leaderboard", function(w)
		local narrow = w < 680

		Kit.place(hero, 0, 137, w, if narrow then 176 else 96)
		heroTitle.Size = UDim2.fromOffset(w - (if narrow then 44 else 340), 26)
		heroDetail.Size = UDim2.fromOffset(w - (if narrow then 44 else 340), 24)

		if narrow then
			Kit.place(categorySegment.instance, 22, 94, w - 44, 36)
			Kit.place(refreshButton, 22, 134, w - 44, 34)
		else
			Kit.place(categorySegment.instance, w - 310, 18, 190, 36)
			Kit.place(refreshButton, w - 110, 18, 90, 36)
		end

		local rankY = 137 + (if narrow then 176 else 96) + 16
		Kit.place(rankCard, 0, rankY, w, 72)
		rankValue.Size = UDim2.fromOffset(w - 240, 26)
		updatedLabel.Position = UDim2.fromOffset(w - 240, 14)

		local listY = rankY + 72 + 16
		local listHeight = VISIBLE_ROWS * ROW_HEIGHT + 36
		Kit.place(listCard, 0, listY, w, listHeight)

		for step = 1, VISIBLE_ROWS do
			local r = rows[step]
			Kit.place(r.row, 0, 18 + (step - 1) * ROW_HEIGHT, w, ROW_HEIGHT)
			r.name.Size = UDim2.fromOffset(math.max(120, w - 340), ROW_HEIGHT)
			r.score.Position = UDim2.fromOffset(w - 240, 0)
			r.score.Size = UDim2.fromOffset(220, ROW_HEIGHT)
		end

		for step = 1, VISIBLE_ROWS do
			local sk = skeletons[step]
			Kit.place(sk, 16, 18 + (step - 1) * ROW_HEIGHT, w - 32, ROW_HEIGHT - 8)
		end

		return listY + listHeight + 16
	end)
end

return InterfacePageLeaderboard
