local ActionService = {}
ActionService.__index = ActionService

local function find(entries, key)
	for _, entry in ipairs(entries) do
		if entry.key == key then
			return entry
		end
	end
end

function ActionService.new(config, economy, rewards, shop, validation)
	return setmetatable({
		config = config,
		economy = economy,
		rewards = rewards,
		shop = shop,
		validation = validation,
		random = Random.new(),
	}, ActionService)
end

function ActionService:_operation(state, key)
	local operation = find(self.config.Operations, key)
	if not operation then
		return false, "Unknown dispatch."
	end

	if self.config.level(state) < operation.unlock then
		return false, "This dispatch is not unlocked."
	end

	if state.energy < operation.energy then
		return false, "More energy is required."
	end

	state.energy -= operation.energy
	state.operationsCompleted += 1

	local mastery = math.min(25, (state.operationMastery[key] or 0) + 1)
	state.operationMastery[key] = mastery

	local chance = math.clamp(
		operation.chance + mastery * 0.005 + self.config.moduleEffect(state, "success") + math.min(0.08, state.reputation / 25000),
		0.15,
		0.98
	)

	if self.random:NextNumber() > chance then
		state.operationsFailed += 1
		state.operationCombo = 0
		local fieldData = math.max(1, math.floor(operation.data * 0.35))
		local experience = math.max(1, math.floor(operation.xp * 0.3))
		state.data += fieldData
		state.totalData += fieldData
		state.xp += experience
		return false, string.format("Dispatch failed · +%d field data", fieldData)
	end

	state.operationCombo += 1

	-- Graded outcome tiers, richer than the old binary crit/no-crit split.
	-- "flawless" is the rarer top tier and only reachable once the current
	-- combo streak clears its minCombo requirement, so it rewards sustained
	-- runs rather than being purely a lucky roll right after a failure
	-- reset combo to 0. Falls back to the original critical-only formula
	-- if an operation somehow has no outcomes table (defensive; every
	-- current Config.Operations entry defines one).
	local outcomes = operation.outcomes or {}
	local roll = self.random:NextNumber()

	local tier, multiplier, label = "partial", 1, nil
	if outcomes.flawless
		and (outcomes.flawless.minCombo == nil or state.operationCombo >= outcomes.flawless.minCombo)
		and roll <= (outcomes.flawless.chanceWithin or 0)
	then
		tier, multiplier, label = "flawless", outcomes.flawless.multiplier, outcomes.flawless.label
	elseif outcomes.critical and roll <= (outcomes.critical.chanceWithin or math.min(0.2, 0.035 + mastery * 0.003)) then
		tier, multiplier, label = "critical", outcomes.critical.multiplier, outcomes.critical.label
	end

	local compute = math.floor(self.config.reward(operation, state) * (1 + self.config.moduleEffect(state, "operation")) * multiplier)
	local fieldData = math.floor(operation.data * (1 + self.config.moduleEffect(state, "data")) * multiplier)
	local experience = math.floor(operation.xp * multiplier)
	local reputation = math.max(1, math.floor((4 + operation.unlock * 2) * (1 + self.config.moduleEffect(state, "reputation"))))

	state.compute += compute
	state.totalEarned += compute
	state.data += fieldData
	state.totalData += fieldData
	state.xp += experience
	state.reputation = math.min(1000000, state.reputation + reputation)
	if tier == "critical" then
		state.criticalSuccesses += 1
	elseif tier == "flawless" then
		state.flawlessSuccesses = (state.flawlessSuccesses or 0) + 1
	end

	return true, string.format("%s · +%d compute%s", operation.name, compute, if label then " · " .. label else "")
end

function ActionService:_recharge(state)
	local capacity = self.config.energyCapacity(state)
	if state.energy >= capacity - 1 then
		return false, "Energy reserve is already full."
	end

	local cost = math.floor(120 * self.config.level(state) ^ 1.35)
	if state.compute < cost then
		return false, "More compute needed."
	end

	state.compute -= cost
	state.energy = math.min(capacity, state.energy + math.ceil(capacity * 0.4))
	return true, "Energy reserve recharged."
end

function ActionService:_module(state, key)
	local module = find(self.config.Modules, key)
	if not module then
		return false, "Unknown firmware module."
	end

	if self.config.level(state) < module.unlock then
		return false, "This firmware is not unlocked."
	end

	local level = state.modules[key] or 0
	if level >= module.max then
		return false, "Firmware is fully calibrated."
	end

	local compute, data = self.config.moduleCost(module, level)
	if state.compute < compute or state.data < data then
		return false, "More compute and field data are required."
	end

	state.compute -= compute
	state.data -= data
	state.modules[key] = level + 1
	state.energy = math.min(state.energy, self.config.energyCapacity(state))
	return true, module.name .. " calibrated"
end

function ActionService:_code(state, value)
	if type(value) ~= "string" then
		return false, "Enter a valid code."
	end

	local code = string.upper(string.gsub(value, "%s+", ""))
	if #code < 1 or #code > 32 then
		return false, "Enter a valid code."
	end

	local definition = self.config.Codes[code]
	if not definition then
		return false, "Code not found."
	end
	if state.codes[code] then
		return false, "Code already redeemed."
	end

	state.codes[code] = true
	state.compute += definition.reward
	state.totalEarned += definition.reward
	return true, definition.label .. " · +" .. definition.reward .. " compute"
end

-- `key` is expected to already be TextService-filtered by the caller
-- (ServerController.luau, which has the requesting Player instance
-- FilterStringForBroadcast needs — Execute's signature deliberately stays
-- player-agnostic, matching every other branch here). This function only
-- does length/emptiness validation, not content moderation.
function ActionService:_callsign(state, value)
	if value == nil then
		state.callsign = ""
		return true, "Call sign cleared."
	end

	if type(value) ~= "string" then
		return false, "Enter a valid call sign."
	end

	local trimmed = string.gsub(value, "^%s+", "")
	trimmed = string.gsub(trimmed, "%s+$", "")

	if #trimmed > 20 then
		return false, "Call sign must be 20 characters or fewer."
	end

	state.callsign = trimmed
	return true, if trimmed == "" then "Call sign cleared." else "Call sign updated."
end

function ActionService:_tutorial(state, key)
	if key == "complete" then
		state.tutorialComplete = true
		state.tutorialStep = #self.config.Tutorial
		return true, "Guide complete."
	end

	local step = tonumber(key)
	if not step then
		return false, "Invalid guide step."
	end

	state.tutorialStep = math.clamp(math.floor(step), 1, #self.config.Tutorial)
	return true, "Guide progress saved."
end

function ActionService:Execute(state, kind, key, amount, now)
	if type(kind) ~= "string" or #kind > 32 then
		return false, "Invalid request."
	end

	if key ~= nil and type(key) ~= "string" then
		return false, "Invalid request."
	end

	if kind == "job" then
		return self.economy.runJob(self.config, state, now)
	elseif kind == "buy" then
		return self.economy.buy(self.config, state, key, amount)
	elseif kind == "research" then
		return self.economy.research(self.config, state, key)
	elseif kind == "boost" then
		return self.economy.boost(self.config, state, now)
	elseif kind == "prestige" then
		return self.economy.prestige(self.config, state)
	elseif kind == "recharge" then
		return self:_recharge(state)
	elseif kind == "operation" then
		return self:_operation(state, key)
	elseif kind == "module" then
		return self:_module(state, key)
	elseif kind == "daily" then
		local ok, reward = self.rewards.daily(state)
		if ok then
			state.compute += reward
			state.totalEarned += reward
			return true, "Daily reward claimed · +" .. reward .. " compute"
		end
		return false, reward
	elseif kind == "claim" then
		local contract = find(self.config.Contracts, key)
		if not contract or state.claimed[key] or self.config.metric(state, contract.metric) < contract.target then
			return false, "Contract is not ready."
		end
		local reward = self.config.reward(contract, state)
		state.claimed[key] = true
		state.compute += reward
		state.totalEarned += reward
		return true, "Contract complete · +" .. reward .. " compute"
	elseif kind == "achievement" then
		local ok, reward, name = self.rewards.achievement(self.config, state, key)
		if ok then
			state.compute += reward
			state.totalEarned += reward
			return true, "Achievement unlocked · " .. name
		end
		return false, reward
	elseif kind == "buyPackage" then
		return self.shop.purchase(self.config, state, key)
	elseif kind == "code" then
		return self:_code(state, key)
	elseif kind == "changelog" then
		state.changelogVersion = self.config.Changelog.version
		return true, "Bulletins marked as read."
	elseif kind == "tutorial" then
		return self:_tutorial(state, key)
	elseif kind == "callsign" then
		return self:_callsign(state, key)
	end

	return false, "Unknown request."
end

return ActionService
