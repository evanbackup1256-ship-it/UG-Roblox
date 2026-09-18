local ServerScriptService = game:GetService("ServerScriptService")

local Trove = require(ServerScriptService.DeckPackages.Trove)

local Framework = {}
Framework.__index = Framework

local function safeCall(service, method, ...)
	local callback = service[method]
	if type(callback) ~= "function" then
		return true
	end

	local arguments = table.pack(...)
	return xpcall(function()
		callback(service, table.unpack(arguments, 1, arguments.n))
	end, debug.traceback)
end

function Framework.new(name)
	assert(type(name) == "string" and #name > 0, "Framework requires a name")

	return setmetatable({
		name = name,
		state = "created",
		services = {},
		definitions = {},
		order = {},
		initialized = {},
		started = {},
		trove = Trove.new(),
	}, Framework)
end

function Framework:Register(name, service, dependencies)
	assert(self.state == "created", "Services must be registered before startup")
	assert(type(name) == "string" and #name > 0, "Service name is required")
	assert(type(service) == "table", "Service must be a table")
	assert(self.definitions[name] == nil, "Duplicate service: " .. name)

	self.definitions[name] = {
		service = service,
		dependencies = dependencies or {},
	}

	return service
end

function Framework:Get(name)
	local service = self.services[name]
	assert(service ~= nil, "Unknown service: " .. name)
	return service
end

function Framework:TryGet(name)
	return self.services[name]
end

function Framework:Track(item, cleanupMethod)
	return self.trove:Add(item, cleanupMethod)
end

function Framework:Connect(signal, callback)
	return self.trove:Connect(signal, callback)
end

function Framework:Spawn(callback, ...)
	local thread = task.spawn(callback, ...)
	self.trove:Add(thread)
	return thread
end

function Framework:_resolve(name, visiting)
	if self.initialized[name] then
		return
	end

	local definition = self.definitions[name]
	assert(definition ~= nil, "Unknown dependency: " .. name)
	assert(not visiting[name], "Circular service dependency: " .. name)

	visiting[name] = true
	for _, dependency in ipairs(definition.dependencies) do
		self:_resolve(dependency, visiting)
	end
	visiting[name] = nil

	self.services[name] = definition.service
	local ok, err = safeCall(definition.service, "Init", self)
	if not ok then
		self.services[name] = nil
		error(string.format("%s failed to initialize: %s", name, err), 0)
	end

	self.initialized[name] = true
	table.insert(self.order, name)
end

function Framework:Start()
	assert(self.state == "created", "Framework can only start once")
	self.state = "starting"

	local ok, err = xpcall(function()
		for name in self.definitions do
			self:_resolve(name, {})
		end

		for _, name in ipairs(self.order) do
			local service = self.services[name]
			local started, startError = safeCall(service, "Start")
			if not started then
				error(string.format("%s failed to start: %s", name, startError), 0)
			end
			self.started[name] = true
		end
	end, debug.traceback)

	if not ok then
		self:Destroy()
		error(err, 0)
	end

	self.state = "running"
	return self
end

function Framework:Destroy()
	if self.state == "destroyed" or self.state == "stopping" then
		return
	end

	self.state = "stopping"

	for index = #self.order, 1, -1 do
		local name = self.order[index]
		local service = self.services[name]
		if service then
			if self.started[name] then
				safeCall(service, "Stop")
			end
			safeCall(service, "Destroy")
		end
	end

	self.trove:Destroy()
	table.clear(self.services)
	table.clear(self.definitions)
	table.clear(self.order)
	table.clear(self.initialized)
	table.clear(self.started)
	self.state = "destroyed"
end


local Players = game:GetService("Players")

local SessionService = {}
SessionService.__index = SessionService

function SessionService.new(persistence, stateService, config, throttle)
	return setmetatable({
		persistence = persistence,
		stateService = stateService,
		config = config,
		throttle = throttle,
		sessions = {},
		loading = {},
		publisher = nil,
		app = nil,
	}, SessionService)
end

function SessionService:Init(app)
	self.app = app
end

function SessionService:Start()
	self.app:Connect(Players.PlayerAdded, function(player)
		task.spawn(function()
			self:Load(player)
		end)
	end)

	self.app:Connect(Players.PlayerRemoving, function(player)
		self:Release(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:Load(player)
		end)
	end
end

function SessionService:SetPublisher(callback)
	self.publisher = callback
end

function SessionService:Load(player)
	local current = self.sessions[player]
	if current then
		return current
	end

	if self.loading[player] then
		local deadline = os.clock() + 20
		while self.loading[player] and player.Parent == Players and os.clock() < deadline do
			task.wait(0.05)
		end
		return self.sessions[player]
	end

	self.loading[player] = true
	local ok, state, message = pcall(self.persistence.Load, self.persistence, player)
	self.loading[player] = nil

	if not ok then
		warn("Deck session load failed:", state)
		message = "Your save is unavailable. Please rejoin."
		state = nil
	end

	if state and player.Parent == Players then
		self.sessions[player] = state
		return state
	end

	if player.Parent == Players and message then
		task.defer(function()
			if player.Parent == Players then
				player:Kick(message)
			end
		end)
	end

	return nil
end

function SessionService:Get(player)
	return self.sessions[player] or self:Load(player)
end

function SessionService:Snapshot(state, now)
	return self.stateService.public(state, self.config, now or workspace:GetServerTimeNow())
end

function SessionService:Publish(player, state, now)
	if self.publisher and self.sessions[player] == state then
		self.publisher(player, self:Snapshot(state, now))
	end
end

function SessionService:Touch(player, state, now)
	self.stateService.touch(state)
	self:Publish(player, state, now)
end

function SessionService:Each(callback)
	for player, state in self.sessions do
		if player.Parent == Players then
			callback(player, state)
		else
			self:Release(player)
		end
	end
end

function SessionService:Drop(player)
	self.sessions[player] = nil
	self.loading[player] = nil
	if self.throttle then
		self.throttle:Forget(player)
	end
end

function SessionService:Release(player)
	self:Drop(player)
	self.persistence:Release(player)
end

function SessionService:Stop()
	local players = {}
	for player in self.sessions do
		table.insert(players, player)
	end

	for _, player in ipairs(players) do
		self:Release(player)
	end
end

function SessionService:Destroy()
	self.persistence:Close()
	table.clear(self.sessions)
	table.clear(self.loading)
	self.publisher = nil
	self.app = nil
end


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
	end

	return false, "Unknown request."
end


local RunService = game:GetService("RunService")

local ProductionService = {}
ProductionService.__index = ProductionService

function ProductionService.new(config, stateService, sessions)
	return setmetatable({
		config = config,
		stateService = stateService,
		sessions = sessions,
		app = nil,
		accumulator = 0,
		interval = 0.5,
	}, ProductionService)
end

function ProductionService:Init(app)
	self.app = app
end

function ProductionService:Start()
	self.app:Connect(RunService.Heartbeat, function(delta)
		self.accumulator += delta
		if self.accumulator < self.interval then
			return
		end

		local elapsed = math.min(self.accumulator, 5)
		self.accumulator = 0
		self:Step(elapsed)
	end)
end

function ProductionService:Step(elapsed)
	local now = workspace:GetServerTimeNow()

	self.sessions:Each(function(player, state)
		local boosted = math.clamp(state.boostUntil - (now - elapsed), 0, elapsed)
		local earned = self.config.rate(state) * (elapsed + boosted)
		local capacity = self.config.energyCapacity(state)
		local recovery = 0.75 * (1 + self.config.moduleEffect(state, "recovery"))

		state.compute = math.min(1e18, state.compute + earned)
		state.totalEarned = math.min(1e18, state.totalEarned + earned)
		state.energy = math.min(capacity, state.energy + recovery * elapsed)
		self.stateService.touch(state)
		self.sessions:Publish(player, state, now)
	end)
end

function ProductionService:Stop()
	self.accumulator = 0
end

function ProductionService:Destroy()
	self.app = nil
end


Framework.SessionService = SessionService
Framework.ActionService = ActionService
Framework.ProductionService = ProductionService

return Framework
