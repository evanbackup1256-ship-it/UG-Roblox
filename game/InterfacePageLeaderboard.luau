local TweenService = game:GetService("TweenService")

local InterfaceShared = require(script.Parent.InterfaceShared)

local ROW_HEIGHT = 40
local VISIBLE_ROWS = 12

-- Reused across every reveal instead of built fresh per row/per fetch —
-- TweenInfo is a plain value type, but there's no reason to allocate 12 of
-- them every time the list populates when a 12-entry lookup table covers
-- every possible stagger step once.
local ROW_FADE, ROW_POP = {}, {}
for step = 0, VISIBLE_ROWS - 1 do
	ROW_FADE[step] = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, step * 0.025)
	ROW_POP[step] = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, step * 0.025)
end

local InterfacePageLeaderboard = {}

function InterfacePageLeaderboard.build(Shared: InterfaceShared.Shared)
	local Kit, C = Shared.Kit, Shared.C
	local positionText, liven, bump = Shared.positionText, Shared.liven, Shared.bump
	local bind, layoutPage = Shared.bind, Shared.layoutPage
	local run, fmt = Shared.run, Shared.fmt

	local requestRefresh

	-- Two independently-ranked categories (see LeaderboardService.luau),
	-- each with its own OrderedDataStore so switching between them never
	-- needs a second scoring scheme crammed into one store.
	local CATEGORIES = {
		{ key = "earned", label = "Compute", unit = "COMPUTE" },
		{ key = "prestige", label = "Relaunches", unit = "RELAUNCHES" },
	}
	local activeCategory = CATEGORIES[1]
	-- true once real data has ever populated the list for the CURRENT
	-- category — reset on category switch so switching tabs gets its own
	-- entrance stagger, same as the very first load does.
	local staggered = false
	-- Assigned further down, once `rows` exists — forward-declared here so
	-- the category buttons (built before `rows`) can already close over it.
	local setActiveCategory

	local hero = Kit.card(Shared.pages.leaderboard, "StandingsHero", 96, C.paper)
	Kit.place(Kit.icon(hero, "Icon", "leaderboard", C.ink), 22, 22, 26, 26)
	local heroTitle = positionText(hero, "Title", "Fleet standings", 58, 18, 500, 28, 20, C.ink, true)
	local heroDetail = positionText(
		hero,
		"Detail",
		"Rankings refresh periodically and may not reflect your most recent progress.",
		58, 52, 700, 30, 12, C.ink
	)
	heroDetail.TextWrapped = true

	local refreshButton = liven(Kit.button(hero, "Refresh", "Refresh", function()
		requestRefresh()
	end))

	-- A small tab switcher, not Kit.enable's disabled-state styling (that
	-- primitive means "can't be clicked right now," the wrong semantics for
	-- "this is the currently selected tab" — both tabs stay clickable here,
	-- only their tint communicates which is active).
	local categoryButtons = {}

	for _, category in ipairs(CATEGORIES) do
		local button = liven(Kit.button(hero, "Category_" .. category.key, category.label, function()
			if activeCategory.key ~= category.key then
				setActiveCategory(category)
				requestRefresh()
			end
		end))
		table.insert(categoryButtons, { button = button, category = category })
	end
	-- Give the default tab its accent tint immediately (Kit.button's
	-- default coloring is identical for every tab until this runs).
	categoryButtons[1].button.BackgroundColor3 = C.accent
	categoryButtons[1].button.TextColor3 = C.ink

	local rankCard = Kit.card(Shared.pages.leaderboard, "YourRank", 72)
	positionText(rankCard, "Label", "YOUR RANK", 20, 14, 220, 18, 10, C.muted, true)
	local rankValue = positionText(rankCard, "Value", "—", 20, 34, 300, 28, 18, C.accent, true)
	rankValue.Font = Enum.Font.RobotoMono
	local bumpRank = bump(rankValue)

	local updatedLabel = positionText(rankCard, "Updated", "", 0, 14, 260, 18, 10, C.muted, true)
	updatedLabel.TextXAlignment = Enum.TextXAlignment.Right

	local listCard = Kit.card(Shared.pages.leaderboard, "StandingsList", VISIBLE_ROWS * ROW_HEIGHT + 32)

	local empty = positionText(listCard, "Empty", "No rankings available yet.", 20, 20, 600, 30, 14, C.muted)
	empty.Visible = false
	local emptyShown = false

	local rows = {}
	for i = 1, VISIBLE_ROWS do
		local row = Kit.create("Frame", listCard, {
			Name = "Row_" .. i,
			BackgroundTransparency = 1,
			Visible = false,
		})
		Kit.corner(row, 6)
		local scale = Kit.create("UIScale", row, { Name = "RevealScale", Scale = 1 })

		local rank = positionText(row, "Rank", "", 20, 0, 60, ROW_HEIGHT, 13, C.muted, true)
		rank.Font = Enum.Font.RobotoMono
		rank.TextTransparency = 0

		local name = positionText(row, "Name", "", 90, 0, 400, ROW_HEIGHT, 14, C.text, true)
		local score = positionText(row, "Score", "", 0, 0, 220, ROW_HEIGHT, 13, C.accent, true)
		score.Font = Enum.Font.RobotoMono
		score.TextXAlignment = Enum.TextXAlignment.Right

		rows[i] = { row = row, scale = scale, rank = rank, name = name, score = score, shown = false }
	end

	setActiveCategory = function(category)
		activeCategory = category
		staggered = false
		for _, row in ipairs(rows) do
			row.shown = false
		end
		for _, entry in ipairs(categoryButtons) do
			local active = entry.category.key == category.key
			Kit.animate(entry.button, {
				BackgroundColor3 = if active then C.accent else C.raised,
				TextColor3 = if active then C.ink else C.text,
			}, 0.16)
		end
	end

	local fetched = false
	local fetching = false
	local cachedAtSeconds = nil

	local function updatedText()
		if not cachedAtSeconds or cachedAtSeconds <= 0 then
			return ""
		end
		local age = math.max(0, os.time() - cachedAtSeconds)
		if age < 60 then
			return string.format("UPDATED %ds AGO", age)
		end
		return string.format("UPDATED %dm AGO", math.floor(age / 60))
	end

	-- Same show/hide-after-fade pattern the hardware-search empty state
	-- uses: fade the label in/out instead of an instant .Visible flip, and
	-- only actually hide once the fade-out finishes.
	local function setEmpty(shouldShow, message)
		if message then
			empty.Text = message
		end
		if shouldShow == emptyShown then
			return
		end
		emptyShown = shouldShow

		if shouldShow then
			empty.Visible = true
			empty.TextTransparency = 1
			Kit.animate(empty, { TextTransparency = 0 }, 0.2)
		else
			Kit.animate(empty, { TextTransparency = 1 }, 0.2)
			Kit.Scheduler.after(empty, "hide", 0.2, function()
				if not emptyShown then
					empty.Visible = false
				end
			end)
		end
	end

	local function setRankValue(text)
		if rankValue.Text ~= text then
			rankValue.Text = text
			bumpRank()
		end
	end

	local function render(result)
		local top = (result and result.top) or {}
		cachedAtSeconds = result and result.cachedAt or nil

		if #top == 0 then
			setEmpty(true, "No rankings available yet.")
			for _, row in ipairs(rows) do
				row.row.Visible = false
				row.shown = false
			end
			setRankValue("—")
			updatedLabel.Text = updatedText()
			return
		end

		setEmpty(false)
		-- Stagger the fade+pop in only the first time real data ever
		-- populates this list (same restraint switchPage's own card
		-- stagger uses: an entrance flourish, not something that replays
		-- every time the player clicks Refresh).
		local stagger = not staggered
		staggered = true

		for i, row in ipairs(rows) do
			local entry = top[i]
			row.row.Visible = entry ~= nil
			if entry then
				local isSelf = entry.userId == Shared.player.UserId
				row.rank.Text = "#" .. tostring(entry.rank)
				row.name.Text = if isSelf then "You" else ("Operator " .. tostring(entry.userId))
				row.score.Text = fmt(entry.score) .. " " .. activeCategory.unit
				row.row.BackgroundColor3 = C.accent

				local targetTransparency = if isSelf then 0.85 else 1
				if not row.shown then
					if stagger and Kit.motion then
						local step = math.min(i - 1, VISIBLE_ROWS - 1)
						row.row.BackgroundTransparency = 1
						row.scale.Scale = 0.985

						local fadeTween = TweenService:Create(row.row, ROW_FADE[step], { BackgroundTransparency = targetTransparency })
						Kit.Scheduler.track(row.row, "reveal", fadeTween)
						fadeTween:Play()

						local popTween = TweenService:Create(row.scale, ROW_POP[step], { Scale = 1 })
						Kit.Scheduler.track(row.scale, "reveal", popTween)
						popTween:Play()
					else
						-- First time this row is populated but not
						-- staggering (reduced motion, or a later page of
						-- rows beyond what shipped on the first fetch):
						-- settle straight to target rather than animating
						-- from whatever transparency a previous fetch's
						-- different entry left behind.
						row.row.BackgroundTransparency = targetTransparency
						row.scale.Scale = 1
					end
				else
					Kit.animate(row.row, { BackgroundTransparency = targetTransparency }, 0.2)
				end
				row.shown = true
			else
				row.shown = false
			end
		end

		setRankValue(if result and result.rank then "#" .. tostring(result.rank) else "Outside top 50")
		updatedLabel.Text = updatedText()
	end

	requestRefresh = function()
		if fetching then
			return
		end
		fetching = true
		local requestedCategory = activeCategory.key
		Kit.enable(refreshButton, false, "Refreshing…", false)

		run(function()
			local ok, result = pcall(Shared.Leaderboard.InvokeServer, Shared.Leaderboard, requestedCategory)
			fetching = false
			Kit.enable(refreshButton, true, "Refresh", false)

			-- The player may have switched tabs again while this request
			-- was in flight — a stale response for a category that's no
			-- longer selected must not overwrite what's currently shown.
			if requestedCategory ~= activeCategory.key then
				return
			end

			if ok and type(result) == "table" then
				render(result)
			elseif not fetched then
				-- First load failed (e.g. Studio without DataStore API
				-- access, or a fresh server with no writes yet): show the
				-- empty state rather than leaving the page blank.
				render(nil)
			end
			fetched = true
		end)
	end

	bind("leaderboard", function()
		if not fetched then
			requestRefresh()
		end
	end)

	layoutPage("leaderboard", function(w)
		local narrow = w < 480
		local heroHeight = if narrow then 194 else 96

		Kit.place(hero, 0, 137, w, heroHeight)
		heroTitle.Size = UDim2.fromOffset(w - 80, 28)
		heroDetail.Size = UDim2.fromOffset(w - 80, if narrow then 46 else 30)
		heroDetail.TextWrapped = true

		local controlsY = if narrow then 100 else 26
		local tabWidth = 120
		for i, entry in ipairs(categoryButtons) do
			Kit.place(entry.button, 58 + (i - 1) * (tabWidth + 8), controlsY, tabWidth, 44)
		end
		Kit.place(refreshButton, if narrow then 58 else w - 150, if narrow then 148 else 26, 130, 44)

		local rankY = 137 + heroHeight + 16
		Kit.place(rankCard, 0, rankY, w, 72)
		rankValue.Size = UDim2.fromOffset(if narrow then w - 160 else 300, 28)
		Kit.place(updatedLabel, math.max(20, w - 260), 14, math.min(240, w - 40), 18)

		local listY = rankY + 72 + 16
		local listHeight = VISIBLE_ROWS * ROW_HEIGHT + 32
		Kit.place(listCard, 0, listY, w, listHeight)
		empty.Size = UDim2.fromOffset(w - 40, 30)

		local scoreWidth = if w < 380 then math.max(90, w - 240) else 220
		local nameWidth = math.max(60, w - 44 - 90 - scoreWidth - 20)
		for i, row in ipairs(rows) do
			Kit.place(row.row, 0, 16 + (i - 1) * ROW_HEIGHT, w, ROW_HEIGHT)
			row.name.Size = UDim2.fromOffset(nameWidth, ROW_HEIGHT)
			Kit.place(row.score, w - 20 - scoreWidth, 0, scoreWidth, ROW_HEIGHT)
		end

		return listY + listHeight
	end)
end

return InterfacePageLeaderboard
