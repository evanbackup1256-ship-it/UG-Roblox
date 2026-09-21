--!strict
-- ScreenStandings: Global fleet verified rankings and player standings
local AppContext = require(script.Parent.Parent.AppContext)

local ScreenStandings = {}

function ScreenStandings.build(ctx: AppContext.Context)
	local Elements = ctx.Elements
	local Inputs = ctx.Inputs
	local Feedback = ctx.Feedback
	local C = ctx.C
	local fmt = ctx.fmt

	local root = ctx.screens.leaderboard
	local activeCategory = "earned"

	-- =========================================================================
	-- 1. HERO BANNER
	-- =========================================================================
	local hero = Elements.card(root, "StandingsHero", 96, C.card)

	local heroIcon = Elements.icon(hero, "Icon", "leaderboard", C.accent)
	Elements.place(heroIcon, 22, 22, 22, 22)

	local heroBadge = Elements.badge(hero, "Global Network", "accent", true)
	Elements.place(heroBadge, 54, 16, 110, 22)

	local heroTitle = Elements.text(hero, "Title", "Fleet Standings", 18, C.textPrimary, true)
	Elements.place(heroTitle, 54, 40, 400, 24)

	local heroDetail = Elements.text(
		hero,
		"Detail",
		"Rankings reflect verified progress across all servers and update periodically.",
		12,
		C.textSecondary
	)
	Elements.place(heroDetail, 54, 64, 600, 22)

	local refreshLeaderboard: (() -> ())? = nil

	-- =========================================================================
	-- 2. CATEGORY SWITCHER & ROWS
	-- =========================================================================
	local categorySegment = Inputs.segmented(
		root,
		"CategorySegment",
		{ "Compute Earned", "Fleet Relaunches" },
		1,
		function(idx)
			activeCategory = if idx == 2 then "prestige" else "earned"
			if refreshLeaderboard then
				refreshLeaderboard()
			end
			ctx.relayout("leaderboard")
		end
	)

	local rowsContainer = Elements.card(root, "RowsContainer", 500, C.card)

	local rowItems = {}
	for i = 1, 12 do
		local row = Elements.create("Frame", rowsContainer, {
			Name = "Row_" .. i,
			Size = UDim2.new(1, 0, 0, 40),
			Position = UDim2.new(0, 0, 0, (i - 1) * 40),
			BackgroundColor3 = if i % 2 == 0 then C.card else C.recessed,
			BorderSizePixel = 0,
		})

		if i == 1 then

		end

		local rankCol = if i == 1 then Color3.fromRGB(245, 158, 11)
			elseif i == 2 then Color3.fromRGB(203, 213, 225)
			elseif i == 3 then Color3.fromRGB(205, 127, 50)
			else C.textMuted

		local rankLbl = Elements.text(row, "Rank", string.format("#%02d", i), 12, rankCol, true)
		rankLbl.Font = ctx.Theme.typography.fontMono
		Elements.place(rankLbl, 20, 10, 40, 20)

		local nameLbl = Elements.text(row, "Name", "Searching network…", 13, C.textPrimary, true)
		Elements.place(nameLbl, 70, 10, 300, 20)

		local scoreLbl = Elements.text(row, "Score", "—", 12, C.accent, true)
		scoreLbl.Font = ctx.Theme.typography.fontMono
		scoreLbl.TextXAlignment = Enum.TextXAlignment.Right
		Elements.place(scoreLbl, 400, 10, 180, 20)

		rowItems[i] = { row = row, rank = rankLbl, name = nameLbl, score = scoreLbl }
	end

	local Players = game:GetService("Players")
	local nameCache: { [number]: string } = {}
	local currentTop: { any } = {}

	local function resolveName(userId: number?): string
		if not userId or userId <= 0 then return "Autonomous Node" end
		if ctx.player and userId == ctx.player.UserId then
			return ctx.player.DisplayName .. " (You)"
		end
		if nameCache[userId] then return nameCache[userId] end
		nameCache[userId] = "Operator #" .. userId
		task.spawn(function()
			local ok, name = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if ok and name and name ~= "" then
				nameCache[userId] = name
				for _, row in ipairs(rowItems) do
					if row.userId == userId then
						row.name.Text = name
					end
				end
			end
		end)
		return nameCache[userId]
	end

	local function updateDisplay(top: { any })
		currentTop = top or {}
		for i = 1, #rowItems do
			local item = rowItems[i]
			local entry = currentTop[i]
			if entry then
				item.userId = entry.userId
				item.name.Text = resolveName(entry.userId)
				local suffix = if activeCategory == "prestige" then " Relaunches" else " Compute"
				item.score.Text = fmt(entry.score or 0) .. suffix
			else
				item.userId = nil
				item.name.Text = if i == 1 then "Awaiting verified network telemetry…" else "—"
				item.score.Text = "—"
			end
		end
	end

	refreshLeaderboard = function()
		if not ctx.getLeaderboard then return end
		task.spawn(function()
			local data = ctx.getLeaderboard(activeCategory)
			if data and type(data.top) == "table" then
				updateDisplay(data.top)
			else
				updateDisplay({})
			end
		end)
	end

	-- =========================================================================
	-- 3. STATE BINDING
	-- =========================================================================
	ctx.bind("leaderboard", function(s)
		refreshLeaderboard()
	end)

	-- =========================================================================
	-- 4. RESPONSIVE LAYOUT
	-- =========================================================================
	ctx.layoutScreen("leaderboard", function(w)
		Elements.place(hero, 0, 0, w, 96)
		Elements.place(categorySegment.instance, 0, 108, math.min(w, 320), 38)
		Elements.place(rowsContainer, 0, 158, w, 12 * 40)

		for _, item in ipairs(rowItems) do
			item.score.AnchorPoint = Vector2.new(1, 0)
			item.score.Position = UDim2.new(1, -20, 0, 10)
			item.score.Size = UDim2.fromOffset(140, 20)

			item.name.Position = UDim2.fromOffset(70, 10)
			item.name.Size = UDim2.fromOffset(math.max(80, w - 240), 20)
			item.name.TextTruncate = Enum.TextTruncate.AtEnd
		end

		return 158 + 12 * 40 + 32
	end)
end

return ScreenStandings

