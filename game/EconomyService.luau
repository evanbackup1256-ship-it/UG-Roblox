local EconomyService = {}

local function find(entries, key)
    for _, entry in ipairs(entries) do if entry.key == key then return entry end end
end

function EconomyService.rate(config, state)
    return config.rate(state) * (state.boostUntil > workspace:GetServerTimeNow() and 2 or 1)
end

function EconomyService.runJob(config, state, clock)
	local cooldown = math.max(0.18, 0.7 - (state.research.scheduling or 0) * 0.04 - (state.research.autoscaling or 0) * 0.025)
    if clock - (state.lastJob or -10) < cooldown then return false, "Job is processing." end
	state.lastJob = clock
	state.jobs = (state.jobs or 0) + 1
	local earned = config.job(state)
    state.compute += earned
    state.totalEarned += earned
    return true, "Job complete · +" .. earned .. " compute"
end

function EconomyService.buy(config, state, key, quantity)
    local tier = find(config.Tiers, key)
    if not tier then return false, "Unknown infrastructure." end
    if config.units(state) < tier.unlock then return false, "Grow your fleet to unlock this tier." end
    local amount = (quantity == 5 or quantity == 10) and quantity or 1
    local bought = 0
    for _ = 1, amount do
        local owned = state.owned[tier.key] or 0
        if owned >= 200 then break end
        local cost = config.buyCost(tier, owned, state)
        if state.compute < cost then break end
        state.compute -= cost
        state.owned[tier.key] = owned + 1
        bought += 1
    end
    if bought == 0 then return false, "More compute needed." end
    return true, bought .. " × " .. tier.name .. " deployed"
end

function EconomyService.research(config, state, key)
    local item = find(config.Research, key)
    if not item then return false, "Unknown research." end
    local level = state.research[item.key] or 0
    if level >= item.max then return false, "Research complete." end
    local cost = config.researchCost(item, level, state)
    if state.compute < cost then return false, "More compute needed." end
    state.compute -= cost
    state.research[item.key] = level + 1
    return true, item.name .. " upgraded"
end

function EconomyService.prestige(config, state)
    local gained = config.prestigePoints(state)
    if gained <= 0 then
        return false, "Reach " .. math.floor(config.Prestige.threshold) .. " lifetime compute to relaunch."
    end

    state.prestigeTokens = (state.prestigeTokens or 0) + gained
    state.prestigeCount = (state.prestigeCount or 0) + 1

    state.compute = 50
    state.totalEarned = 0
    state.jobs = 0
    state.owned = {}
    state.research = {}
    state.modules = {}
    state.data = 0
    state.xp = 0
    state.energy = config.energyCapacity(state)
    state.operationsCompleted = 0
    state.operationsFailed = 0
    state.operationCombo = 0
    state.operationMastery = {}
    state.criticalSuccesses = 0
    state.flawlessSuccesses = 0
    state.totalData = 0
    state.boostUntil = 0
    state.boostReady = 0

    return true, "Fleet relaunched · +" .. gained .. " prestige tokens"
end

function EconomyService.boost(config, state, clock)
    if state.boostReady > workspace:GetServerTimeNow() then return false, "Overclock is recharging." end
    if config.units(state) == 0 then return false, "Deploy a server first." end
	state.boostUntil = workspace:GetServerTimeNow() + 30 + (state.research.overclock or 0) * 5 + (state.research.redundancy or 0) * 3
    state.boostReady = state.boostUntil + 180 - (state.research.energy or 0) * 10
    state.daily.boosts += 1
    return true, "Overclock active · double production"
end

return EconomyService
