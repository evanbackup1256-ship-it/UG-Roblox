local StateService = {}
local function finite(value, fallback, maximum)
	if type(value) ~= "number" or value ~= value or value == math.huge or value < 0 then
		return fallback
	end
	return math.min(value, maximum or 1e18)
end
local function copyMap(source, target, entries, transform)
	for _, entry in ipairs(entries) do
		target[entry.key] = transform(source and source[entry.key], entry)
	end
end
function StateService.new(config, data)
	local source = type(data) == "table" and data or {}
	local state = {
		version = 8,
		compute = finite(source.compute, 50),
		totalEarned = finite(source.totalEarned, 0),
		jobs = 0,
		owned = {},
		research = {},
		modules = {},
		data = finite(source.data, 0),
		xp = finite(source.xp, 0),
		reputation = finite(source.reputation, 0, 1000000),
		energy = finite(source.energy, 100, 10000),
		energyUpdatedAt = finite(source.energyUpdatedAt, os.time(), 1e12),
		operationsCompleted = math.floor(finite(source.operationsCompleted, 0, 1e9)),
		operationsFailed = math.floor(finite(source.operationsFailed, 0, 1e9)),
		operationCombo = math.floor(finite(source.operationCombo, 0, 1000)),
		operationMastery = {},
		criticalSuccesses = math.floor(finite(source.criticalSuccesses, 0, 1e9)),
		flawlessSuccesses = math.floor(finite(source.flawlessSuccesses, 0, 1e9)),
		totalData = finite(source.totalData, 0),
		lastOperationAt = 0,
		claimed = {},
		achievements = {},
		quests = {},
		daily = {
			day = "",
			streak = 0,
			claimed = 0,
			boosts = 0,
			lastClaimAt = 0
		},
		settings = table.clone(config.Settings),
		boostUntil = 0,
		boostReady = 0,
		canSave = true,
		saveStatus = "Saved",
		createdAt = os.time(),
		updatedAt = os.time(),
		codes = {},
		changelogVersion = "",
		tutorialComplete = false,
		tutorialStep = 1,
		prestigeTokens = math.floor(finite(source.prestigeTokens, 0, 1e9)),
		prestigeCount = math.floor(finite(source.prestigeCount, 0, 1e9)),
	}
	copyMap(source.owned, state.owned, config.Tiers, function(value)
		return math.floor(finite(value, 0, 200))
	end)
	copyMap(source.research, state.research, config.Research, function(value, entry)
		return math.floor(finite(value, 0, entry.max))
	end)
	copyMap(source.modules, state.modules, config.Modules, function(value, entry)
		return math.floor(finite(value, 0, entry.max))
	end)
	copyMap(source.operationMastery, state.operationMastery, config.Operations, function(value)
		return math.floor(finite(value, 0, 25))
	end)
	state.energy = math.min(state.energy, config.energyCapacity(state))
	copyMap(source.claimed, state.claimed, config.Contracts, function(value)
		return value == true
	end)
	copyMap(source.achievements, state.achievements, config.Achievements, function(value)
		return value == true
	end)
	copyMap(source.quests, state.quests, config.Contracts, function(value)
		return math.floor(finite(value, 0, 1))
	end)
	if type(source.daily) == "table" then
		state.daily.day = type(source.daily.day) == "string" and string.sub(source.daily.day, 1, 16) or ""
		state.daily.streak = math.floor(finite(source.daily.streak, 0, 3650))
		state.daily.claimed = math.floor(finite(source.daily.claimed, 0, 3650))
		state.daily.boosts = math.floor(finite(source.daily.boosts, 0, 1e6))
		state.daily.lastClaimAt = finite(source.daily.lastClaimAt, 0, 1e12)
	end
	if type(source.settings) == "table" then
		for key, default in pairs(config.Settings) do
			local value = source.settings[key]
			if type(default) == "boolean" and type(value) == "boolean" then
				state.settings[key] = value
			elseif type(default) == "number" and type(value) == "number" and value == value then
				state.settings[key] = math.clamp(value, 0, 1)
			end
		end
	end
	if type(source.codes) == "table" then
		for code, redeemed in pairs(source.codes) do
			if type(code) == "string" and #code <= 32 and redeemed == true then
				state.codes[string.upper(code)] = true
			end
		end
	end
	state.changelogVersion = type(source.changelogVersion) == "string" and string.sub(source.changelogVersion, 1, 32) or ""
	state.tutorialComplete = source.tutorialComplete == true
	state.tutorialStep = math.clamp(math.floor(finite(source.tutorialStep, 1, #config.Tutorial)), 1, #config.Tutorial)
	state.jobs = math.floor(finite(source.jobs, 0, 1e9))
	return state
end
function StateService.touch(state)
	state.updatedAt = os.time()
end
function StateService.public(state, config, now)
	local maximumResearch, allResearch = 0, 999
	for _, item in ipairs(config.Research) do
		local level = state.research[item.key] or 0
		maximumResearch = math.max(maximumResearch, level)
		allResearch = math.min(allResearch, level)
	end
	-- Computed once and threaded through config.rate/synergyBonus below
	-- instead of each recomputing it — this whole function runs on every
	-- server publish (every action and every production tick), so a
	-- three-times-redundant synergy evaluation was a real, recurring cost.
	local synergyStatus = config.synergyStatus(state)
	return {
		version = state.version,
		compute = state.compute,
		totalEarned = state.totalEarned,
		jobs = state.jobs,
		owned = table.clone(state.owned),
		research = table.clone(state.research),
		modules = table.clone(state.modules),
		data = state.data,
		xp = state.xp,
		level = config.level(state),
		reputation = state.reputation,
		energy = state.energy,
		energyCapacity = config.energyCapacity(state),
		operationsCompleted = state.operationsCompleted,
		operationsFailed = state.operationsFailed,
		operationCombo = state.operationCombo,
		operationMastery = table.clone(state.operationMastery),
		criticalSuccesses = state.criticalSuccesses,
		flawlessSuccesses = state.flawlessSuccesses,
		totalData = state.totalData,
		claimed = table.clone(state.claimed),
		achievements = table.clone(state.achievements),
		quests = table.clone(state.quests),
		daily = table.clone(state.daily),
		achievementMetrics = {
			units = config.units(state),
			earned = state.totalEarned,
			research = maximumResearch,
			research_all = allResearch,
			streak = state.daily.streak,
			boosts = state.daily.boosts,
			jobs = state.jobs
		},
		settings = table.clone(state.settings),
		boostUntil = state.boostUntil,
		boostReady = state.boostReady,
		codes = table.clone(state.codes),
		changelogVersion = state.changelogVersion,
		changelog = config.Changelog,
		changelogs = config.Changelogs,
		tutorialComplete = state.tutorialComplete,
		tutorialStep = state.tutorialStep,
		rate = config.rate(state, synergyStatus) * (state.boostUntil > now and 2 or 1),
		units = config.units(state),
		saveStatus = state.saveStatus or "Saved",
		updatedAt = state.updatedAt,
		prestigeTokens = state.prestigeTokens,
		prestigeCount = state.prestigeCount,
		prestigePoints = config.prestigePoints(state),
		prestigeThreshold = config.Prestige.threshold,
		prestigeBonus = config.prestigeBonus(state),
		synergyStatus = synergyStatus,
		synergyBonus = config.synergyBonus(state, synergyStatus),
	}
end
return StateService
