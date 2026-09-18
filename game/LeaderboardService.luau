local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local LeaderboardService = {}
LeaderboardService.__index = LeaderboardService

local TOP_N = 50
local WRITE_COOLDOWN = 60    -- seconds/player, gates how often a score write is attempted
local REFRESH_INTERVAL = 120 -- seconds, cached top-N re-pull cadence

-- Each category is its own OrderedDataStore (one numeric key per store),
-- so two rankings (lifetime compute vs. relaunch count) live side by side
-- without either interfering with the other's sort order or write cadence.
local CATEGORIES = {
	{ key = "earned", store = "DeckEmpire_Leaderboard_v1", field = "totalEarned", cap = 1e15 },
	{ key = "prestige", store = "DeckEmpire_LeaderboardPrestige_v1", field = "prestigeCount", cap = 1e6 },
}

function LeaderboardService.new(sessions)
	local self = setmetatable({
		sessions = sessions,
		isStudio = RunService:IsStudio(),
		categories = {},
		app = nil,
	}, LeaderboardService)

	-- GetOrderedDataStore itself is documented as an instant local handle,
	-- not a network call, but this constructor runs synchronously at
	-- server startup (ServerController.luau, before anything else — not
	-- even the "service kernel online" print has happened yet), so ANY
	-- unexpected stall or error here would silently block the entire
	-- server from ever finishing load: no player could get a session, no
	-- print would ever appear, and the client would hang forever waiting
	-- on GetState. Wrapped per-category so one bad store can't take out
	-- the whole service, and never allowed to block: real store creation
	-- is deferred to :Start(), off the constructor's critical path.
	for _, definition in ipairs(CATEGORIES) do
		self.categories[definition.key] = {
			definition = definition,
			store = nil,
			cachedTop = {},
			cachedAt = 0,
		}
	end

	return self
end

function LeaderboardService:_ensureStore(category)
	if category.store or category.storeFailed then
		return category.store
	end

	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore(category.definition.store)
	end)

	if ok then
		category.store = store
	else
		category.storeFailed = true
		warn("[Deck/Leaderboard] failed to open store for", category.definition.key, ":", store)
	end

	return category.store
end

function LeaderboardService:Init(app)
	self.app = app
end

function LeaderboardService:Start()
	self.app:Spawn(function()
		while true do
			for key in self.categories do
				self:_refreshTop(key)
			end
			task.wait(REFRESH_INTERVAL)
		end
	end)
end

-- Best-effort, never blocks gameplay: called from the action-success path
-- in ServerController.luau. The service's own per-player throttle (via
-- Framework:Throttle, one token per WRITE_COOLDOWN seconds, shared across
-- all categories for a given player) makes it safe to call this on every
-- successful action rather than hand-picking "milestone" verbs — most
-- calls simply no-op.
function LeaderboardService:Submit(player, state)
	if not self.app:Throttle("leaderboardWrite", player, 1, 1 / WRITE_COOLDOWN) then
		return
	end

	for key, category in self.categories do
		local raw = state[category.definition.field]
		if type(raw) == "number" then
			local score = math.floor(math.min(raw, category.definition.cap))
			task.spawn(function()
				local store = self:_ensureStore(category)
				if not store then
					return
				end
				local ok, err = pcall(function()
					store:SetAsync("user_" .. player.UserId, score)
				end)
				if not ok then
					warn(string.format("[Deck/Leaderboard] write failed (%s):", key), err)
				end
			end)
		end
	end
end

function LeaderboardService:_refreshTop(key)
	local category = self.categories[key]
	if not category then
		return
	end

	local store = self:_ensureStore(category)
	if not store then
		return
	end

	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, TOP_N)
	end)
	if not ok then
		-- Keep serving whatever cachedTop already holds (possibly still
		-- empty on a fresh server, or stale from the last successful
		-- pull) rather than erroring — Studio in particular routinely
		-- fails DataStore calls without API access enabled, and this must
		-- degrade to an empty/stale leaderboard, never a broken one.
		return
	end

	local top = {}
	for rank, entry in ipairs(pages:GetCurrentPage()) do
		top[rank] = {
			userId = tonumber(string.match(entry.key, "%d+")),
			score = entry.value,
			rank = rank,
		}
	end

	category.cachedTop = top
	category.cachedAt = os.time()
end

function LeaderboardService:GetTop(key)
	local category = self.categories[key]
	if not category then
		return {}, 0
	end
	return category.cachedTop, category.cachedAt
end

-- OrderedDataStore has no direct "rank of key" query, so this approximates
-- via cached top-N membership rather than a second expensive query per
-- request — a player outside the top N simply gets no rank back, which the
-- client surfaces as "outside top 50" rather than a fetched number.
function LeaderboardService:GetRank(key, userId)
	local category = self.categories[key]
	if not category then
		return nil
	end
	for _, entry in ipairs(category.cachedTop) do
		if entry.userId == userId then
			return entry.rank
		end
	end
	return nil
end

function LeaderboardService:Categories()
	local keys = {}
	for _, definition in ipairs(CATEGORIES) do
		table.insert(keys, definition.key)
	end
	return keys
end

function LeaderboardService:Stop()
end

function LeaderboardService:Destroy()
	self.app = nil
end

return LeaderboardService
