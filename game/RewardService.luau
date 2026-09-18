local RewardService = {}

local function find(entries, key)
    for _, entry in ipairs(entries) do if entry.key == key then return entry end end
end

function RewardService.daily(state)
    local today = os.date("!%Y-%m-%d")
    if state.daily.day == today then return false, "Daily reward already claimed." end
    state.daily.day = today
    state.daily.streak += 1
    state.daily.claimed += 1
    local reward = 100 + state.daily.streak * 50
    state.daily.lastClaimAt = os.time()
    return true, reward
end

function RewardService.achievement(config, state, key)
    local achievement = find(config.Achievements, key)
    if not achievement or state.achievements[key] then return false, "Achievement is not ready." end
    local researchMax, researchAll = 0, 999
    for _, item in ipairs(config.Research) do
        local level = state.research[item.key] or 0
        researchMax = math.max(researchMax, level)
        researchAll = math.min(researchAll, level)
    end
    local metrics = {units = config.units(state), earned = state.totalEarned, jobs = state.jobs or 0, research = researchMax, research_all = researchAll, streak = state.daily.streak, boosts = state.daily.boosts}
    if (metrics[achievement.metric] or 0) < achievement.target then return false, "Achievement is not ready." end
    state.achievements[key] = true
    return true, achievement.reward, achievement.name
end

return RewardService
